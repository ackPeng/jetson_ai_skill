#!/usr/bin/env bash
set -euo pipefail

SDK=""
CONFIG=""
BOARDID=""
BOARDSKU=""
FAB=""
BOARDREV=""
CHIP_SKU=""
MODE="nvme"
EXTERNAL_DEVICE="nvme0n1p1"
EXTERNAL_LAYOUT=""
QSPI_LAYOUT=""
ROOTDEV=""
ROOTFS_SIZE="80GiB"
MASSFLASH="5"
NETWORK="usb0"
ADDITIONAL_DTB_OVERLAY=""
EXECUTE=0

require_sudo() {
  if [ "$(id -u)" -eq 0 ]; then
    return 0
  fi
  if sudo -n true 2>/dev/null; then
    return 0
  fi
  echo "Passwordless sudo is required to execute l4t_initrd_flash.sh from this script." >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: make-massflash.sh --sdk SDK --config CONFIG --boardid ID --boardsku SKU --fab FAB --boardrev REV --chip-sku SKU [options]

Options:
  --mode nvme|qspi|internal Package type. Default: nvme
  --external-device DEV     External device. Default: nvme0n1p1
  --external-layout XML     External layout path. Defaults from mode and detected SoC
  --qspi-layout XML         QSPI layout path. Defaults from detected SoC
  --rootdev ROOTDEV         Root device argument. Defaults: internal for t264, external for t234
  --rootfs-size SIZE        Rootfs size for external package. Default: 80GiB
  --massflash N             Massflash count. Default: 5
  --network IFACE           Network interface. Default: usb0
  --additional-dtb-overlay OPT
                           Sets ADDITIONAL_DTB_OVERLAY_OPT for BootOrder*.dtbo cases
  --execute                 Actually run the command. Default only prints it.
  -h, --help                Show help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --sdk) SDK="$2"; shift 2 ;;
    --config) CONFIG="$2"; shift 2 ;;
    --boardid) BOARDID="$2"; shift 2 ;;
    --boardsku) BOARDSKU="$2"; shift 2 ;;
    --fab) FAB="$2"; shift 2 ;;
    --boardrev) BOARDREV="$2"; shift 2 ;;
    --chip-sku) CHIP_SKU="$2"; shift 2 ;;
    --mode) MODE="$2"; shift 2 ;;
    --external-device) EXTERNAL_DEVICE="$2"; shift 2 ;;
    --external-layout) EXTERNAL_LAYOUT="$2"; shift 2 ;;
    --qspi-layout) QSPI_LAYOUT="$2"; shift 2 ;;
    --rootdev) ROOTDEV="$2"; shift 2 ;;
    --rootfs-size) ROOTFS_SIZE="$2"; shift 2 ;;
    --massflash) MASSFLASH="$2"; shift 2 ;;
    --network) NETWORK="$2"; shift 2 ;;
    --additional-dtb-overlay) ADDITIONAL_DTB_OVERLAY="$2"; shift 2 ;;
    --execute) EXECUTE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

for value in SDK CONFIG BOARDID BOARDSKU FAB CHIP_SKU; do
  if [ -z "${!value}" ]; then
    echo "Missing --$(echo "$value" | tr 'A-Z_' 'a-z-')" >&2
    exit 2
  fi
done

[ -d "$SDK" ] || { echo "SDK does not exist: $SDK" >&2; exit 1; }
[ -f "$SDK/tools/kernel_flash/l4t_initrd_flash.sh" ] || { echo "Missing l4t_initrd_flash.sh" >&2; exit 1; }

soc="t234"
if [[ "$CONFIG" =~ p3834|thor ]] || { [ -f "$SDK/$CONFIG.conf" ] && grep -q 'tegra264\|t264' "$SDK/$CONFIG.conf"; }; then
  soc="t264"
elif [[ "$CONFIG" =~ p3767|p3701|orin ]] || { [ -f "$SDK/$CONFIG.conf" ] && grep -q 'tegra234\|t234' "$SDK/$CONFIG.conf"; }; then
  soc="t234"
elif [ -d "$SDK/source/hardware/nvidia/t264" ] && [ ! -d "$SDK/source/hardware/nvidia/t23x" ]; then
  soc="t264"
fi

if [ -z "$QSPI_LAYOUT" ]; then
  if [ "$soc" = "t264" ]; then
    if [ -f "$SDK/bootloader/flash_l4t_t264_qspi.xml" ]; then
      QSPI_LAYOUT="bootloader/flash_l4t_t264_qspi.xml"
    else
      QSPI_LAYOUT="bootloader/generic/cfg/flash_t264_qspi.xml"
    fi
  else
    QSPI_LAYOUT="bootloader/generic/cfg/flash_t234_qspi.xml"
  fi
fi

for layout in "$QSPI_LAYOUT" "$EXTERNAL_LAYOUT"; do
  if [ -n "$layout" ] && [ ! -f "$SDK/$layout" ]; then
    echo "Warning: layout not found under SDK: $layout" >&2
  fi
done

if [ -z "$EXTERNAL_LAYOUT" ]; then
  if [ "$soc" = "t264" ]; then
    EXTERNAL_LAYOUT="tools/kernel_flash/flash_l4t_t264_nvme.xml"
  else
    if [ -f "$SDK/tools/kernel_flash/flash_l4t_t234_nvme.xml" ]; then
      EXTERNAL_LAYOUT="tools/kernel_flash/flash_l4t_t234_nvme.xml"
    else
      EXTERNAL_LAYOUT="tools/kernel_flash/flash_l4t_nvme.xml"
    fi
  fi
fi

if [ -z "$ROOTDEV" ]; then
  if [ "$soc" = "t264" ]; then
    ROOTDEV="internal"
  else
    ROOTDEV="external"
  fi
fi

cmd=(sudo env "BOARDID=$BOARDID" "BOARDSKU=$BOARDSKU" "FAB=$FAB" "BOARDREV=$BOARDREV" "CHIP_SKU=$CHIP_SKU")
if [ -n "$ADDITIONAL_DTB_OVERLAY" ]; then
  cmd+=("ADDITIONAL_DTB_OVERLAY_OPT=$ADDITIONAL_DTB_OVERLAY")
fi
cmd+=(./tools/kernel_flash/l4t_initrd_flash.sh)

case "$MODE" in
  qspi)
    cmd+=(-p "-c $QSPI_LAYOUT --no-systemimg" --no-flash --massflash "$MASSFLASH" --network "$NETWORK" "$CONFIG" "$ROOTDEV")
    ;;
  internal)
    cmd+=(--no-flash --massflash "$MASSFLASH" --network "$NETWORK" "$CONFIG" "$ROOTDEV")
    ;;
  nvme)
    if [ "$soc" = "t264" ]; then
      cmd+=(--external-device "$EXTERNAL_DEVICE" -c "$EXTERNAL_LAYOUT" -S "$ROOTFS_SIZE" --no-flash --massflash "$MASSFLASH" --network "$NETWORK" "$CONFIG" "$ROOTDEV")
    else
      cmd+=(--external-device "$EXTERNAL_DEVICE" -c "$EXTERNAL_LAYOUT" -S "$ROOTFS_SIZE" -p "-c $QSPI_LAYOUT --no-systemimg" --no-flash --massflash "$MASSFLASH" --network "$NETWORK" "$CONFIG" "$ROOTDEV")
    fi
    ;;
  *)
    echo "Unsupported --mode: $MODE" >&2
    exit 2
    ;;
esac

echo "Detected SoC profile: $soc"
echo "Massflash command:"
printf 'cd %q &&' "$SDK"
printf ' %q' "${cmd[@]}"
printf '\n'

if [ "$EXECUTE" -eq 1 ]; then
  require_sudo
  echo "Execution note: NVIDIA's no-flash flow may create a large mfi_$CONFIG/ directory and then gzip it into mfi_$CONFIG.tar.gz."
  if [ "$soc" = "t264" ] && [ "${MASSFLASH:-0}" != "1" ]; then
    echo "Thor note: --massflash $MASSFLASH can duplicate unified flash workspaces. Use --massflash 1 for smoke tests."
  fi
  (cd "$SDK" && "${cmd[@]}")
  artifact="$SDK/mfi_$CONFIG.tar.gz"
  if [ -f "$artifact" ]; then
    md5sum "$artifact" > "$SDK/chksum-$CONFIG.txt"
    sha256sum "$artifact" >> "$SDK/chksum-$CONFIG.txt"
    echo "Wrote $SDK/chksum-$CONFIG.txt"
  fi
else
  echo "Dry run only. Add --execute to run."
fi
