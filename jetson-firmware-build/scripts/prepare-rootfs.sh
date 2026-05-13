#!/usr/bin/env bash
set -euo pipefail

SDK=""
ROOTFS_TAR=""
ROOTFS_URL=""
YES=0
APPLY_BINARIES=1
APPLY_BINARIES_ARGS=()
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
Usage: prepare-rootfs.sh --sdk SDK (--rootfs-tar ROOTFS_TAR | --rootfs-url URL) --yes [options]

Options:
  --rootfs-url URL         Download rootfs tarball when --rootfs-tar is missing or absent
  --no-apply-binaries       Extract rootfs without running apply_binaries.sh
  --apply-binaries-arg ARG  Extra argument passed to apply_binaries.sh; may be repeated
  --mark-release TEXT       Append a marker line to rootfs/etc/nv_tegra_release
  -h, --help                Show help

This script deletes existing contents under SDK/rootfs. --yes is required.
EOF
}

download_file() {
  url="$1"
  output="$2"

  if [ -f "$output" ]; then
    echo "Reusing $output"
    return
  fi

  if command -v wget >/dev/null 2>&1; then
    wget -O "$output" "$url"
  elif command -v curl >/dev/null 2>&1; then
    curl -L -o "$output" "$url"
  else
    echo "Missing downloader: install wget or curl" >&2
    exit 1
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --sdk) SDK="$2"; shift 2 ;;
    --rootfs-tar) ROOTFS_TAR="$2"; shift 2 ;;
    --rootfs-url) ROOTFS_URL="$2"; shift 2 ;;
    --yes) YES=1; shift ;;
    --no-apply-binaries) APPLY_BINARIES=0; shift ;;
    --apply-binaries-arg) APPLY_BINARIES_ARGS+=("$2"); shift 2 ;;
    --mark-release) MARK_RELEASE="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage; exit 2 ;;
  esac
done

[ -n "$SDK" ] || { echo "Missing --sdk" >&2; exit 2; }
[ -n "$ROOTFS_TAR" ] || [ -n "$ROOTFS_URL" ] || { echo "Missing --rootfs-tar or --rootfs-url" >&2; exit 2; }
[ "$YES" -eq 1 ] || { echo "--yes is required because rootfs cleanup is destructive" >&2; exit 2; }
[ -d "$SDK/rootfs" ] || { echo "Missing rootfs directory: $SDK/rootfs" >&2; exit 1; }
[ -f "$SDK/apply_binaries.sh" ] || { echo "Missing apply_binaries.sh under SDK" >&2; exit 1; }

require_sudo

if [ -z "$ROOTFS_TAR" ]; then
  rootfs_name="${ROOTFS_URL%%\?*}"
  ROOTFS_TAR="$SDK/$(basename "$rootfs_name")"
fi

if [ ! -f "$ROOTFS_TAR" ]; then
  [ -n "$ROOTFS_URL" ] || { echo "Missing rootfs tarball: $ROOTFS_TAR" >&2; exit 1; }
  echo "Downloading rootfs from $ROOTFS_URL"
  download_file "$ROOTFS_URL" "$ROOTFS_TAR"
fi

echo "Cleaning $SDK/rootfs"
sudo find "$SDK/rootfs" -mindepth 1 -maxdepth 1 -exec rm -rf {} +

echo "Extracting $ROOTFS_TAR"
sudo tar xpf "$ROOTFS_TAR" -C "$SDK/rootfs"

if [ "$APPLY_BINARIES" -eq 1 ]; then
  echo "Running apply_binaries.sh"
  (cd "$SDK" && sudo ./apply_binaries.sh "${APPLY_BINARIES_ARGS[@]}")
fi

if [ -n "$MARK_RELEASE" ]; then
  echo "Appending marker to nv_tegra_release"
  echo "# $MARK_RELEASE" | sudo tee -a "$SDK/rootfs/etc/nv_tegra_release" >/dev/null
fi
