#!/usr/bin/env python3
import argparse
import json
import os
from pathlib import Path


def exists(path):
    return path.exists()


def default_sdks():
    candidates = []
    env_path = os.environ.get("L4T_DIR")
    if env_path:
        candidates.append(Path(env_path))

    cwd = Path.cwd()
    candidates.append(cwd)
    for base in [cwd, *list(cwd.parents)[:3]]:
        candidates.append(base / "Linux_for_Tegra")
        candidates.append(base / "linux_for_tegra")
    for child in cwd.iterdir() if cwd.is_dir() else []:
        if child.is_dir():
            candidates.append(child / "Linux_for_Tegra")
            candidates.append(child / "linux_for_tegra")

    roots = []
    seen = set()
    for path in candidates:
        try:
            root = path.resolve()
        except OSError:
            continue
        if root in seen:
            continue
        seen.add(root)
        if (root / "tools" / "kernel_flash" / "l4t_initrd_flash.sh").is_file():
            roots.append(root)
    return roots


def list_names(path, pattern):
    if not path.is_dir():
        return []
    return sorted(p.name for p in path.glob(pattern))


def inspect_sdk(path):
    root = path.resolve()
    source = root / "source" / "hardware" / "nvidia"
    socs = []
    if (source / "t23x" / "nv-public").is_dir():
        socs.append("t234")
    if (source / "t264" / "nv-public").is_dir():
        socs.append("t264")
    if not socs:
        probe_names = []
        for probe_dir, pattern in [
            (root / "kernel" / "dtb", "tegra*.dtb"),
            (root / "kernel" / "dtb", "tegra*.dtbo"),
            (root / "bootloader" / "generic" / "BCT", "tegra*.dts"),
            (root, "*.conf"),
        ]:
            probe_names.extend(list_names(probe_dir, pattern)[:200])
        if any("tegra234" in name or "t234" in name for name in probe_names):
            socs.append("t234")
        if any("tegra264" in name or "t264" in name or "p3834" in name for name in probe_names):
            socs.append("t264")

    release_file = root / "rootfs" / "etc" / "nv_tegra_release"
    release = ""
    if release_file.is_file():
        try:
            release = release_file.read_text(errors="replace").splitlines()[0]
        except OSError:
            release = ""

    board_configs = [
        name
        for name in list_names(root, "*.conf")
        if not name.endswith(".conf.common")
    ]

    data = {
        "sdk": str(root),
        "exists": root.is_dir(),
        "valid_shape": all(
            exists(p)
            for p in [
                root / "apply_binaries.sh",
                root / "flash.sh",
                root / "tools" / "kernel_flash" / "l4t_initrd_flash.sh",
                root / "bootloader" / "generic" / "BCT",
                root / "kernel" / "dtb",
            ]
        ),
        "socs": socs,
        "release": release,
        "board_config_count": len(board_configs),
        "board_configs_sample": board_configs[:20],
        "top_level_common_configs": list_names(root, "*.conf.common"),
        "internal_flash_xml": list_names(root / "bootloader" / "generic" / "cfg", "flash_*.xml")
        + list_names(root / "bootloader", "flash_*.xml"),
        "external_flash_xml": list_names(root / "tools" / "kernel_flash", "flash_*.xml"),
        "has_source_nvbuild": (root / "source" / "nvbuild.sh").is_file(),
        "rootfs_populated": any((root / "rootfs").iterdir()) if (root / "rootfs").is_dir() else False,
    }
    return data


def print_text(reports):
    for report in reports:
        print(f"SDK: {report['sdk']}")
        print(f"  exists: {report['exists']}")
        print(f"  valid_shape: {report['valid_shape']}")
        print(f"  socs: {', '.join(report['socs']) or 'none'}")
        print(f"  release: {report['release'] or 'unknown'}")
        print(f"  board configs: {report['board_config_count']}")
        if report["board_configs_sample"]:
            print("  board config sample:")
            for name in report["board_configs_sample"]:
                print(f"    - {name}")
        print(f"  internal flash xml: {', '.join(report['internal_flash_xml']) or 'none'}")
        print(f"  external flash xml: {', '.join(report['external_flash_xml']) or 'none'}")
        print(f"  source/nvbuild.sh: {report['has_source_nvbuild']}")
        print(f"  rootfs populated: {report['rootfs_populated']}")


def main():
    parser = argparse.ArgumentParser(description="Probe Jetson Linux_for_Tegra SDK roots.")
    parser.add_argument("--sdk", action="append", type=Path, help="Linux_for_Tegra SDK root. May be repeated.")
    parser.add_argument("--json", action="store_true", help="Print JSON instead of text.")
    args = parser.parse_args()

    paths = args.sdk or default_sdks()
    if not paths:
        parser.error("pass --sdk or set L4T_DIR to a Linux_for_Tegra SDK root")

    reports = [inspect_sdk(path) for path in paths]
    if args.json:
        print(json.dumps(reports, indent=2, sort_keys=True))
    else:
        print_text(reports)


if __name__ == "__main__":
    main()
