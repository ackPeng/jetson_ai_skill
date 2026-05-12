#!/usr/bin/env bash
set -euo pipefail

SDK=""
CROSS_PREFIX="${CROSS_COMPILE:-}"
INSTALL_MODULES=0
SKIP_BUILD=0

require_sudo() {
  if [ "$(id -u)" -eq 0 ]; then
    return 0
  fi
  if sudo -n true 2>/dev/null; then
    return 0
  fi
  echo "Passwordless sudo is required for this install step." >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: build-kernel-install.sh --sdk SDK --cross-prefix PREFIX [options]

Options:
  --install-modules       Run nvbuild.sh -i with INSTALL_MOD_PATH=SDK/rootfs
  --skip-build            Skip nvbuild.sh and only install modules if requested
  -h, --help              Show help
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --sdk) SDK="$2"; shift 2 ;;
    --cross-prefix) CROSS_PREFIX="$2"; shift 2 ;;
    --install-modules) INSTALL_MODULES=1; shift ;;
    --skip-build) SKIP_BUILD=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

[ -n "$SDK" ] || { echo "Missing --sdk" >&2; exit 2; }
[ -d "$SDK/source" ] || { echo "Missing SDK source directory" >&2; exit 1; }
[ -f "$SDK/source/nvbuild.sh" ] || { echo "Missing source/nvbuild.sh" >&2; exit 1; }
[ -n "$CROSS_PREFIX" ] || { echo "Missing --cross-prefix or CROSS_COMPILE" >&2; exit 2; }
[ -f "${CROSS_PREFIX}gcc" ] || { echo "Missing compiler: ${CROSS_PREFIX}gcc" >&2; exit 1; }

export ARCH=arm64
export CROSS_COMPILE="$CROSS_PREFIX"

if [ "$SKIP_BUILD" -eq 0 ]; then
  echo "Building kernel, modules, and DTBs"
  (cd "$SDK/source" && ./nvbuild.sh)

  if [ -x "$SDK/source/do_copy.sh" ]; then
    echo "Running source/do_copy.sh"
    (cd "$SDK/source" && ./do_copy.sh)
  else
    echo "source/do_copy.sh not found; copying discoverable Image and DTBs"
    require_sudo
    image="$(find "$SDK/source/kernel_out" -path '*/arch/arm64/boot/Image' -type f | head -n 1 || true)"
    if [ -n "$image" ]; then
      sudo install -m 0644 "$image" "$SDK/kernel/Image"
    fi
    if [ -d "$SDK/kernel/dtb" ]; then
      find "$SDK/source/kernel_out" -type f \( -name '*.dtb' -o -name '*.dtbo' \) -print0 |
        while IFS= read -r -d '' file; do
          sudo install -m 0644 "$file" "$SDK/kernel/dtb/"
        done
    fi
  fi
fi

if [ "$INSTALL_MODULES" -eq 1 ]; then
  [ -d "$SDK/rootfs" ] || { echo "Missing SDK/rootfs" >&2; exit 1; }
  require_sudo
  export INSTALL_MOD_PATH="$(realpath "$SDK/rootfs")"
  echo "Installing modules to $INSTALL_MOD_PATH"
  (cd "$SDK/source" && ./nvbuild.sh -i)
  kernel_version="$(find "$SDK/rootfs/lib/modules" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort | tail -n 1 || true)"
  if [ -n "$kernel_version" ]; then
    echo "Updating module dependencies for $kernel_version"
    sudo depmod -b "$SDK/rootfs" "$kernel_version"
  fi
fi
