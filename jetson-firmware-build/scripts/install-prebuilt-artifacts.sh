#!/usr/bin/env bash
set -euo pipefail

SDK=""
DTB_DIR=""
BCT_DIR=""
COPY_ROOTFS_BOOT=0
DRY_RUN=0

usage() {
  cat <<'EOF'
Usage: install-prebuilt-artifacts.sh --sdk SDK [--dtb-dir DIR] [--bct-dir DIR] [options]

Options:
  --copy-to-rootfs-boot     Also copy DTB and DTBO files into rootfs/boot
  --dry-run                 Print actions without copying
  -h, --help                Show help
EOF
}

run() {
  printf '+'
  printf ' %q' "$@"
  printf '\n'
  if [ "$DRY_RUN" -eq 0 ]; then
    "$@"
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --sdk) SDK="$2"; shift 2 ;;
    --dtb-dir) DTB_DIR="$2"; shift 2 ;;
    --bct-dir) BCT_DIR="$2"; shift 2 ;;
    --copy-to-rootfs-boot) COPY_ROOTFS_BOOT=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

[ -n "$SDK" ] || { echo "Missing --sdk" >&2; exit 2; }
[ -d "$SDK" ] || { echo "SDK does not exist: $SDK" >&2; exit 1; }

if [ -n "$BCT_DIR" ]; then
  [ -d "$BCT_DIR" ] || { echo "BCT dir does not exist: $BCT_DIR" >&2; exit 1; }
  [ -d "$SDK/bootloader/generic/BCT" ] || { echo "Missing SDK BCT dir" >&2; exit 1; }
  while IFS= read -r file; do
    run sudo install -m 0644 "$file" "$SDK/bootloader/generic/BCT/"
  done < <(find "$BCT_DIR" -maxdepth 1 -type f \( -name '*.dts' -o -name '*.dtsi' -o -name '*.dtb' -o -name '*.cfg' -o -name '*.bin' \) | sort)
fi

if [ -n "$DTB_DIR" ]; then
  [ -d "$DTB_DIR" ] || { echo "DTB dir does not exist: $DTB_DIR" >&2; exit 1; }
  [ -d "$SDK/kernel/dtb" ] || { echo "Missing SDK kernel/dtb dir" >&2; exit 1; }
  while IFS= read -r file; do
    run sudo install -m 0644 "$file" "$SDK/kernel/dtb/"
    if [ "$COPY_ROOTFS_BOOT" -eq 1 ] && [ -d "$SDK/rootfs/boot" ]; then
      run sudo install -m 0644 "$file" "$SDK/rootfs/boot/"
    fi
  done < <(find "$DTB_DIR" -maxdepth 1 -type f \( -name '*.dtb' -o -name '*.dtbo' \) | sort)
fi
