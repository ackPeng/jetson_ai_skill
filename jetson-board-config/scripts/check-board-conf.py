#!/usr/bin/env python3
import argparse
import json
import os
import re
import subprocess
import sys
from pathlib import Path


BCT_VARS = {
    "PINMUX_CONFIG",
    "PMC_CONFIG",
    "PMIC_CONFIG",
    "DEVICE_CONFIG",
    "DEVICEPROD_CONFIG",
    "PROD_CONFIG",
    "MB2_BCT",
    "UPHY_CONFIG",
    "EMC_BCT",
    "WB0SDRAM_BCT",
    "BPMP_MEM_CONFIG",
    "SCR_CONFIG",
    "MINRATCHET_CONFIG",
    "GPIOINT_CONFIG",
    "MISC_CONFIG",
}

DTB_VARS = {
    "DTB_FILE",
    "TBCDTB_FILE",
    "RECDTB_FILE",
}

OVERLAY_VARS = {
    "OVERLAY_DTB_FILE",
    "DCE_OVERLAY_DTB_FILE",
}

PATH_VARS = {
    "BPFFILE",
}

REQUIRED_IDENTITY = ["BOARDID", "BOARDSKU", "FAB", "BOARDREV", "CHIP_SKU"]
DYNAMIC_REQUIRED_IDENTITY = ["BOARDID", "BOARDSKU", "FAB", "CHIP_SKU"]
CHECK_KEYS = sorted(BCT_VARS | DTB_VARS | OVERLAY_VARS | PATH_VARS | {"BPFDTB_FILE", "EMMC_CFG", "EXTERNAL_PT_LAYOUT"})


def strip_comment(line):
    out = []
    quote = None
    escape = False
    for ch in line:
        if escape:
            out.append(ch)
            escape = False
            continue
        if ch == "\\":
            out.append(ch)
            escape = True
            continue
        if quote:
            out.append(ch)
            if ch == quote:
                quote = None
            continue
        if ch in ("'", '"'):
            quote = ch
            out.append(ch)
            continue
        if ch == "#":
            break
        out.append(ch)
    return "".join(out).strip()


def unquote(value):
    value = value.strip().rstrip(";").strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in ("'", '"'):
        return value[1:-1]
    return value


def expand_vars(value, variables, sdk):
    value = value.replace("${LDK_DIR}", str(sdk))
    value = value.replace("$LDK_DIR", str(sdk))

    def repl(match):
        name = match.group(1) or match.group(2)
        return variables.get(name, os.environ.get(name, ""))

    return re.sub(r"\$\{([A-Za-z_][A-Za-z0-9_]*)\}|\$([A-Za-z_][A-Za-z0-9_]*)", repl, value)


def source_path(raw, variables, sdk, current):
    raw = unquote(raw)
    raw = expand_vars(raw, variables, sdk)
    path = Path(raw)
    if not path.is_absolute():
        path = current.parent / path
    return path


def parse_conf(path, sdk, variables=None, seen=None):
    variables = variables or {}
    seen = seen or set()
    path = path.resolve()
    if path in seen:
        return variables
    seen.add(path)
    if not path.is_file():
        variables.setdefault("_missing_sources", []).append(str(path))
        return variables

    skip_depth = 0
    function_depth = 0
    for raw_line in path.read_text(errors="replace").splitlines():
        line = strip_comment(raw_line)
        if not line:
            continue

        if re.match(r"^(function\s+)?[A-Za-z_][A-Za-z0-9_]*\s*\(\)\s*\{", line):
            function_depth += 1
            continue
        if function_depth:
            if line == "}" or line.endswith("}"):
                function_depth = max(0, function_depth - 1)
            continue

        if re.match(r"^(if|elif|else)\b", line):
            skip_depth += 1 if line.startswith("if") else 0
            continue
        if line == "fi" or line.startswith("fi;"):
            skip_depth = max(0, skip_depth - 1)
            continue
        if skip_depth:
            continue

        m_source = re.match(r"^source\s+(.+)$", line)
        if m_source:
            src = source_path(m_source.group(1), variables, sdk, path)
            parse_conf(src, sdk, variables, seen)
            continue

        m_assign = re.match(r"^([A-Za-z_][A-Za-z0-9_]*)\s*(\+?=)\s*(.*)$", line)
        if not m_assign:
            continue
        key, op, raw_value = m_assign.groups()
        value = expand_vars(unquote(raw_value), variables, sdk)
        if op == "+=":
            variables[key] = variables.get(key, "") + value
        else:
            variables[key] = value
    return variables


def split_csv(value):
    return [item.strip() for item in value.split(",") if item.strip()]


def candidates_for(sdk, key, value):
    if not value:
        return []
    path = Path(value)
    if path.is_absolute() or "/" in value:
        return [sdk / value if not path.is_absolute() else path]
    if key in BCT_VARS:
        return [sdk / "bootloader" / "generic" / "BCT" / value, sdk / "bootloader" / value]
    if key in DTB_VARS or key in OVERLAY_VARS:
        return [sdk / "kernel" / "dtb" / value, sdk / "bootloader" / value]
    if key == "BPFDTB_FILE":
        return [
            sdk / "bootloader" / value,
            sdk / "bootloader" / "generic" / value,
            sdk / "kernel" / "dtb" / value,
        ]
    if key == "EMMC_CFG":
        return [sdk / "bootloader" / "generic" / "cfg" / value]
    if key == "EXTERNAL_PT_LAYOUT":
        return [sdk / value]
    if key in PATH_VARS:
        return [sdk / value]
    return [sdk / value]


def check_value(sdk, key, value):
    missing = []
    found = []
    if not value:
        return found, missing
    values = split_csv(value) if key in OVERLAY_VARS else [value]
    for item in values:
        cands = candidates_for(sdk, key, item)
        existing = [str(p) for p in cands if p.exists()]
        if existing:
            found.append({"key": key, "value": item, "path": existing[0]})
        else:
            missing.append({"key": key, "value": item, "candidates": [str(p) for p in cands]})
    return found, missing


def resolve_config(sdk, config):
    path = Path(config)
    if path.is_file():
        return path
    name = config if config.endswith(".conf") else f"{config}.conf"
    return sdk / name


def evaluate_dynamic_conf(sdk, conf, identity):
    if any(not identity[key] for key in DYNAMIC_REQUIRED_IDENTITY) or not conf.is_file():
        return {}, None

    script = r'''
set -e
export LDK_DIR="$PWD"
export board_id="$BOARDID_VALUE"
export board_sku="$BOARDSKU_VALUE"
export board_FAB="$FAB_VALUE"
export board_revision="$BOARDREV_VALUE"
export CHIP_SKU="$CHIP_SKU_VALUE"
source "$CONF_PATH"
if declare -F update_flash_args >/dev/null 2>&1; then
  update_flash_args >/dev/null
fi
for key in $CHECK_KEYS; do
  printf '%s\0%s\0' "$key" "${!key-}"
done
'''
    env = os.environ.copy()
    env.update(
        {
            "BOARDID_VALUE": identity["BOARDID"],
            "BOARDSKU_VALUE": identity["BOARDSKU"],
            "FAB_VALUE": identity["FAB"],
            "BOARDREV_VALUE": identity["BOARDREV"],
            "CHIP_SKU_VALUE": identity["CHIP_SKU"],
            "CONF_PATH": str(conf),
            "CHECK_KEYS": " ".join(CHECK_KEYS),
        }
    )
    result = subprocess.run(
        ["bash", "-lc", script],
        cwd=sdk,
        env=env,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    if result.returncode != 0:
        error = result.stderr.decode(errors="replace").strip() or result.stdout.decode(errors="replace").strip()
        return {}, error

    parts = result.stdout.decode(errors="replace").split("\0")
    dynamic = {}
    for index in range(0, len(parts) - 1, 2):
        key = parts[index]
        value = parts[index + 1]
        if key and value:
            dynamic[key] = value
    return dynamic, None


def main():
    parser = argparse.ArgumentParser(description="Validate Jetson board config references.")
    parser.add_argument("--sdk", required=True, type=Path, help="Linux_for_Tegra SDK root.")
    parser.add_argument("--config", required=True, help="Board config name or path.")
    parser.add_argument("--boardid")
    parser.add_argument("--boardsku")
    parser.add_argument("--fab")
    parser.add_argument("--boardrev")
    parser.add_argument("--chip-sku")
    parser.add_argument(
        "--allow-empty-boardrev",
        action="store_true",
        help="Allow BOARDREV to be empty. Jetson Thor board specs often leave boardrev blank.",
    )
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    sdk = args.sdk.resolve()
    conf = resolve_config(sdk, args.config)
    variables = parse_conf(conf, sdk)

    identity = {
        "BOARDID": args.boardid or os.environ.get("BOARDID", ""),
        "BOARDSKU": args.boardsku or os.environ.get("BOARDSKU", ""),
        "FAB": args.fab or os.environ.get("FAB", ""),
        "BOARDREV": args.boardrev or os.environ.get("BOARDREV", ""),
        "CHIP_SKU": args.chip_sku or os.environ.get("CHIP_SKU", ""),
    }

    dynamic_variables, dynamic_error = evaluate_dynamic_conf(sdk, conf, identity)
    variables.update(dynamic_variables)

    keys_to_check = sorted(set(CHECK_KEYS) & set(variables))
    found = []
    missing = []
    for key in keys_to_check:
        ok, bad = check_value(sdk, key, variables.get(key, ""))
        found.extend(ok)
        missing.extend(bad)

    required_identity = [key for key in REQUIRED_IDENTITY if not (args.allow_empty_boardrev and key == "BOARDREV")]
    missing_identity = [key for key in required_identity if not identity[key]]
    missing_sources = variables.get("_missing_sources", [])
    report = {
        "sdk": str(sdk),
        "config": str(conf),
        "config_exists": conf.is_file(),
        "identity": identity,
        "missing_identity": missing_identity,
        "checked_keys": keys_to_check,
        "found": found,
        "missing": missing,
        "missing_sources": missing_sources,
        "dynamic_evaluated": bool(dynamic_variables),
        "dynamic_error": dynamic_error,
        "dynamic_variables": dynamic_variables,
    }

    if args.json:
        print(json.dumps(report, indent=2, sort_keys=True))
    else:
        print(f"SDK: {sdk}")
        print(f"Config: {conf}")
        print(f"Config exists: {conf.is_file()}")
        if missing_sources:
            print("Missing sourced files:")
            for item in missing_sources:
                print(f"  - {item}")
        if missing_identity:
            print("Missing board identity values:")
            for item in missing_identity:
                print(f"  - {item}")
        if dynamic_error:
            print("Dynamic config evaluation failed:")
            print(f"  - {dynamic_error}")
        print("Checked variables:")
        for key in keys_to_check:
            print(f"  - {key}={variables.get(key, '')}")
        if missing:
            print("Missing referenced files:")
            for item in missing:
                print(f"  - {item['key']}={item['value']}")
                for cand in item["candidates"]:
                    print(f"      {cand}")
        else:
            print("All checked references exist.")

    if not conf.is_file() or missing or missing_sources or missing_identity:
        sys.exit(1)


if __name__ == "__main__":
    main()
