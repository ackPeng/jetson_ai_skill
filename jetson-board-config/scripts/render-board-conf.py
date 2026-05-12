#!/usr/bin/env python3
import argparse
from pathlib import Path


def quote(value):
    return '"' + value.replace('"', '\\"') + '"'


def add(lines, key, value):
    if value:
        lines.append(f"{key}={quote(value)};")


def main():
    parser = argparse.ArgumentParser(description="Render a draft Jetson board .conf file.")
    parser.add_argument("--base", required=True, help="Base config name, with or without .conf.")
    parser.add_argument("--output", type=Path, help="Write to this file instead of stdout.")
    parser.add_argument("--dtb")
    parser.add_argument("--tbcdtb")
    parser.add_argument("--bpfdtb")
    parser.add_argument("--bpffile")
    parser.add_argument("--pinmux")
    parser.add_argument("--pmc")
    parser.add_argument("--pmic")
    parser.add_argument("--device")
    parser.add_argument("--deviceprod")
    parser.add_argument("--prod")
    parser.add_argument("--mb2-bct")
    parser.add_argument("--uphy")
    parser.add_argument("--emc-bct")
    parser.add_argument("--wb0sdram-bct")
    parser.add_argument("--bpmp-mem-config")
    parser.add_argument("--scr")
    parser.add_argument("--minratchet")
    parser.add_argument("--gpioint")
    parser.add_argument("--emmc-cfg")
    parser.add_argument("--external-layout")
    parser.add_argument("--external-device")
    parser.add_argument("--overlay", action="append", default=[])
    parser.add_argument("--odmdata")
    parser.add_argument("--set", action="append", default=[], metavar="KEY=VALUE", help="Append an arbitrary assignment.")
    args = parser.parse_args()

    base = args.base if args.base.endswith(".conf") else f"{args.base}.conf"
    lines = [
        "# Draft Jetson board config. Review before flashing.",
        "# Sourced by flash.sh and l4t_initrd_flash.sh.",
        f"source \"${{LDK_DIR}}/{base}\"",
        "",
    ]

    add(lines, "DTB_FILE", args.dtb)
    add(lines, "TBCDTB_FILE", args.tbcdtb or args.dtb)
    add(lines, "BPFDTB_FILE", args.bpfdtb)
    add(lines, "BPFFILE", args.bpffile)
    add(lines, "PINMUX_CONFIG", args.pinmux)
    add(lines, "PMC_CONFIG", args.pmc)
    add(lines, "PMIC_CONFIG", args.pmic)
    add(lines, "DEVICE_CONFIG", args.device)
    add(lines, "DEVICEPROD_CONFIG", args.deviceprod)
    add(lines, "PROD_CONFIG", args.prod)
    add(lines, "MB2_BCT", args.mb2_bct)
    add(lines, "UPHY_CONFIG", args.uphy)
    add(lines, "EMC_BCT", args.emc_bct)
    add(lines, "WB0SDRAM_BCT", args.wb0sdram_bct)
    add(lines, "BPMP_MEM_CONFIG", args.bpmp_mem_config)
    add(lines, "SCR_CONFIG", args.scr)
    add(lines, "MINRATCHET_CONFIG", args.minratchet)
    add(lines, "GPIOINT_CONFIG", args.gpioint)
    add(lines, "EMMC_CFG", args.emmc_cfg)
    add(lines, "EXTERNAL_PT_LAYOUT", args.external_layout)
    add(lines, "EXTERNAL_DEVICE", args.external_device)
    if args.overlay:
        add(lines, "OVERLAY_DTB_FILE", ",".join(args.overlay))
    add(lines, "ODMDATA", args.odmdata)

    for item in args.set:
        if "=" not in item:
            raise SystemExit(f"--set must be KEY=VALUE: {item}")
        key, value = item.split("=", 1)
        add(lines, key.strip(), value.strip())

    text = "\n".join(lines) + "\n"
    if args.output:
        args.output.write_text(text)
    else:
        print(text, end="")


if __name__ == "__main__":
    main()
