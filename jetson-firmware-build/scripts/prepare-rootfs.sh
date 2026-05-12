#!/usr/bin/env bash
set -euo pipefail

SDK=""
ROOTFS_TAR=""
YES=0
APPLY_BINARIES=1
MARK_RELEASE=""

require_sudo() {
  if [ "$(id -u)" -eq 0 ]; then
    return 0
  fi
  if sudo -n true 2>/dev/null; then
    return 0
  fi
  echo "Passwordless sudo is required for rootfs cleanup/extraction/apply_binaries." >&2
  exit 1
}

usage() {
  cat <<'EOF'
Usage: prepare-rootfs.sh --sdk SDK --rootfs-tar ROOTFS_TAR --yes [options]

Options:
  --no-apply-binaries       Extract rootfs without running apply_binaries.sh
  --mark-release TEXT       Append a marker line to rootfs/etc/nv_tegra_release
  -h, --help                Show help

This script deletes existing contents under SDK/rootfs. --yes is required.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --sdk) SDK="$2"; shift 2 ;;
    --rootfs-tar) ROOTFS_TAR="$2"; shift 2 ;;
    --yes) YES=1; shift ;;
    --no-apply-binaries) APPLY_BINARIES=0; shift ;;
    --mark-release) MARK_RELEASE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

[ -n "$SDK" ] || { echo "Missing --sdk" >&2; exit 2; }
[ -n "$ROOTFS_TAR" ] || { echo "Missing --rootfs-tar" >&2; exit 2; }
[ "$YES" -eq 1 ] || { echo "--yes is required because rootfs cleanup is destructive" >&2; exit 2; }
[ -d "$SDK/rootfs" ] || { echo "Missing rootfs directory: $SDK/rootfs" >&2; exit 1; }
[ -f "$ROOTFS_TAR" ] || { echo "Missing rootfs tarball: $ROOTFS_TAR" >&2; exit 1; }
[ -f "$SDK/apply_binaries.sh" ] || { echo "Missing apply_binaries.sh under SDK" >&2; exit 1; }

require_sudo

echo "Cleaning $SDK/rootfs"
sudo find "$SDK/rootfs" -mindepth 1 -maxdepth 1 -exec rm -rf {} +

echo "Extracting $ROOTFS_TAR"
sudo tar xpf "$ROOTFS_TAR" -C "$SDK/rootfs"

if [ "$APPLY_BINARIES" -eq 1 ]; then
  echo "Running apply_binaries.sh"
  (cd "$SDK" && sudo ./apply_binaries.sh)
fi

if [ -n "$MARK_RELEASE" ]; then
  echo "Appending marker to nv_tegra_release"
  echo "# $MARK_RELEASE" | sudo tee -a "$SDK/rootfs/etc/nv_tegra_release" >/dev/null
fi
