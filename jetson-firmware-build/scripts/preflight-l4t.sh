#!/usr/bin/env bash
set -euo pipefail

SDK=""
CONFIG=""
ROOTFS_TAR=""
CROSS_PREFIX="${CROSS_COMPILE:-}"
REQUIRE_BOARD_VARS=0
ALLOW_EMPTY_BOARDREV=0

usage() {
  cat <<'EOF'
Usage: preflight-l4t.sh --sdk SDK --config CONFIG [options]

Options:
  --rootfs-tar PATH       Rootfs tarball to verify
  --cross-prefix PREFIX   Cross compiler prefix ending in aarch64...-
  --require-board-vars    Require BOARDID BOARDSKU FAB BOARDREV CHIP_SKU in env
  --allow-empty-boardrev  Allow BOARDREV to be empty when board vars are required
  -h, --help              Show help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --sdk) SDK="$2"; shift 2 ;;
    --config) CONFIG="$2"; shift 2 ;;
    --rootfs-tar) ROOTFS_TAR="$2"; shift 2 ;;
    --cross-prefix) CROSS_PREFIX="$2"; shift 2 ;;
    --require-board-vars) REQUIRE_BOARD_VARS=1; shift ;;
    --allow-empty-boardrev) ALLOW_EMPTY_BOARDREV=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

[ -n "$SDK" ] || { echo "Missing --sdk" >&2; exit 2; }
[ -d "$SDK" ] || { echo "SDK does not exist: $SDK" >&2; exit 1; }

fail=0
check_path() {
  if [ ! -e "$1" ]; then
    echo "MISSING: $1"
    fail=1
  else
    echo "OK: $1"
  fi
}

check_path "$SDK/apply_binaries.sh"
check_path "$SDK/flash.sh"
check_path "$SDK/tools/kernel_flash/l4t_initrd_flash.sh"
check_path "$SDK/bootloader/generic/BCT"
check_path "$SDK/bootloader/generic/cfg"
check_path "$SDK/kernel/dtb"
check_path "$SDK/rootfs"
check_path "$SDK/source/nvbuild.sh"

if [ -n "$CONFIG" ]; then
  if [ -f "$SDK/$CONFIG.conf" ]; then
    echo "OK: $SDK/$CONFIG.conf"
  elif [ -f "$CONFIG" ]; then
    echo "OK: $CONFIG"
  else
    echo "MISSING: board config $CONFIG"
    fail=1
  fi
fi

if [ -n "$ROOTFS_TAR" ]; then
  check_path "$ROOTFS_TAR"
fi

if [ -n "$CROSS_PREFIX" ]; then
  check_path "${CROSS_PREFIX}gcc"
fi

if [ "$REQUIRE_BOARD_VARS" -eq 1 ]; then
  for var in BOARDID BOARDSKU FAB BOARDREV CHIP_SKU; do
    if [ "$var" = "BOARDREV" ] && [ "$ALLOW_EMPTY_BOARDREV" -eq 1 ]; then
      echo "OK ENV: BOARDREV=${BOARDREV:-} (empty allowed)"
      continue
    fi
    if [ -z "${!var:-}" ]; then
      echo "MISSING ENV: $var"
      fail=1
    else
      echo "OK ENV: $var=${!var}"
    fi
  done
fi

exit "$fail"
