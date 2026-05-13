# Rootfs And Toolchain Sources

Use this reference when preparing a Jetson Linux SDK rootfs and cross compiler before a firmware build.

## Version coupling

Keep the rootfs package, BSP driver package, and toolchain tied to the intended JetPack/L4T release. Do not reuse an r38 package with an r36 BSP, or a rootfs from one r38 minor release with another minor release, unless the vendor BSP explicitly documents that combination.

For JP7.1 / Thor r38.4.0, the project reference URLs are:

```bash
ROOTFS_URL="https://developer.nvidia.com/downloads/embedded/L4T/r38_Release_v4.0/source/ubuntu_noble-l4t_aarch64_src.tbz2"
TOOLCHAIN_URL="https://developer.nvidia.com/downloads/embedded/L4T/r38_Release_v2.0/release/x-tools.tbz2"
```

The inspected vendor helper uses a mirrored or renamed rootfs tarball name (`Tegra_Linux_Sample-Root-Filesystem_r38.4.0_aarch64.tbz2`) and a repacked toolchain name. Treat those names as vendor packaging details; the release-matched NVIDIA URL is the stronger source-of-truth when reconstructing the flow for a fresh SDK.

For other JetPack releases, use the corresponding NVIDIA Jetson Linux download page and match the `rXX_Release_vY.Z` path for that release. If a vendor SDK bundles or mirrors the packages, prefer the vendor-provided package names for that SDK and record the source URL in build notes.

## Rootfs prepare pattern

The useful part of a vendor `prepare` script is the phase split, not the hard-coded mirror URL:

1. Assert the SDK shape and board config exist.
2. Reuse or download the version-matched rootfs tarball.
3. Clean `rootfs/` only after an explicit destructive flag or user confirmation.
4. Extract with permissions preserved:

```bash
sudo tar xpf "$ROOTFS_TAR" -C "$L4T_DIR/rootfs"
```

5. Run `apply_binaries.sh`. Some Thor/OpenRM vendor SDKs use:

```bash
sudo ./apply_binaries.sh --openrm
```

Other SDKs may use no extra argument:

```bash
sudo ./apply_binaries.sh
```

6. Optionally append a build marker to `rootfs/etc/nv_tegra_release`.

The skill helper supports local or remote rootfs packages:

```bash
jetson-firmware-build/scripts/prepare-rootfs.sh \
  --sdk "$L4T_DIR" \
  --rootfs-url "$ROOTFS_URL" \
  --apply-binaries-arg --openrm \
  --mark-release "custom Thor prepare $(date +%Y-%m-%d)" \
  --yes
```

Use `--rootfs-tar /path/to/file.tbz2` instead of `--rootfs-url` when the package is already downloaded.

## Toolchain prepare pattern

Download or reuse the version-matched toolchain archive, extract it into a stable SDK-local directory, then point `CROSS_COMPILE` at the compiler prefix.

Example pattern:

```bash
mkdir -p "$L4T_DIR/l4t-gcc"
wget -O "$L4T_DIR/x-tools.tbz2" "$TOOLCHAIN_URL"
tar xf "$L4T_DIR/x-tools.tbz2" -C "$L4T_DIR/l4t-gcc"

find "$L4T_DIR/l4t-gcc" -path '*/bin/*gcc' -name 'aarch64*gcc' -print
export CROSS_COMPILE="$L4T_DIR/l4t-gcc/<extracted-dir>/bin/<aarch64-prefix>-"
```

Vendor SDKs may use a repacked toolchain name such as `aarch64--glibc--stable-2022.08-1.tar.bz2`; in that case, keep the vendor `TOOLCHAIN_NAME`, `TOOLCHAIN_DIRNAME`, and `CROSS_COMPILE` values together.

## Why `thor_build_flash.sh prepare` matters

The observed J601 `prepare` stage is a good model for skill behavior because it separates rootfs/toolchain setup from kernel build and flashing. The skill should preserve that split:

- `prepare`: rootfs extraction, `apply_binaries`, optional release marker, toolchain extraction.
- `build`: `nvbuild.sh`, optional vendor/project `do_copy.sh` or explicit Image/DTB copy, module install, initrd update, rootfs customization.
- `flash/package`: `l4t_initrd_flash.sh`, no-flash package generation, massflash, direct online flash.

Keep `flash/package` in `jetson-flash-package`; do not hide flashing inside a generic prepare/build helper.

## `do_copy.sh` role

When a project or vendor SDK provides `source/do_copy.sh`, treat it as a convenience artifact-copy script. It usually copies selected files from `source/kernel_out/` into the locations consumed by later firmware package generation:

```text
source/kernel_out/.../arch/arm64/boot/Image -> kernel/Image
source/kernel_out/.../dtbs/*.dtb              -> kernel/dtb/
source/kernel_out/.../dtbs/*.dtbo             -> kernel/dtb/
```

It is not a guaranteed NVIDIA SDK script, and it is not the module installation step. Modules are installed separately through `INSTALL_MOD_PATH="$L4T_DIR/rootfs"` and `./nvbuild.sh -i`.

If `source/do_copy.sh` is absent, locate the built `Image`, DTBs, and overlays under `source/kernel_out/` and copy only the artifacts referenced by the selected board config and flash flow.
