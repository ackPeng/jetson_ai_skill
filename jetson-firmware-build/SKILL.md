---
name: jetson-firmware-build
description: "Prepare Jetson Linux rootfs, apply binaries, build and install kernel modules and DTBs, install prebuilt DTB or BCT artifacts, and run depmod before flashing. Use for the post board-config BSP build flow including rootfs extraction, apply_binaries.sh, kernel nvbuild.sh, INSTALL_MOD_PATH, prebuilt vendor DTB/BCT installation, rootfs customization, and CI-derived firmware build reproduction. Hand off flash package generation and actual flashing to jetson-flash-package."
---

# Jetson Firmware Build

## Overview

Use this skill after the board config is chosen or created. It implements the build side of the BSP bring-up loop: rootfs, kernel artifacts, prebuilt artifacts when provided, and module dependency generation.

## Modes

Use source-DTS mode when the DTS is edited and rebuilt from source.

Use prebuilt-artifacts mode when the user supplies DTB, DTBO, pinmux, GPIO, padvoltage, PMIC, UPHY, or other BCT files without source. This is the default for the first validation plan.

## Workflow

1. Run `jetson-bsp-context` if the SDK root or SoC profile is unclear.
2. Run `jetson-board-config` and validate the `.conf` file before building.
3. Run `scripts/preflight-l4t.sh` to check SDK shape, board variables, toolchain, rootfs tarball, and build scripts.
4. Prepare rootfs with `scripts/prepare-rootfs.sh` if the rootfs is not already populated.
5. Build kernel and install modules with `scripts/build-kernel-install.sh` when kernel sources or modules must be rebuilt.
6. In prebuilt-artifacts mode, run `scripts/install-prebuilt-artifacts.sh` after kernel build and before package generation. If a vendor SDK already contains compiled Thor kernel, modules, DTBs, BPMP DTBs, and BCT files, do not rebuild source; verify the supplied binaries.
7. Hand off to `jetson-flash-package` for no-flash image generation, massflash package creation, flash-only, online flashing, and checksums.

## Command Pattern

Preflight:

```bash
jetson-firmware-build/scripts/preflight-l4t.sh \
  --sdk /home/galbot/jetson/JP7.1/Linux_for_Tegra \
  --config my-custom-board \
  --rootfs-tar /path/to/Tegra_Linux_Sample-Root-Filesystem.tbz2 \
  --require-board-vars
```

For Thor board specs with an intentionally empty `BOARDREV`, add `--allow-empty-boardrev`.

Prepare rootfs:

```bash
jetson-firmware-build/scripts/prepare-rootfs.sh \
  --sdk /home/galbot/jetson/JP7.1/Linux_for_Tegra \
  --rootfs-tar /path/to/Tegra_Linux_Sample-Root-Filesystem.tbz2 \
  --yes
```

Install supplied DTB and BCT files:

```bash
jetson-firmware-build/scripts/install-prebuilt-artifacts.sh \
  --sdk /home/galbot/jetson/JP7.1/Linux_for_Tegra \
  --dtb-dir /path/to/prebuilt-dtb \
  --bct-dir /path/to/exported-bct \
  --copy-to-rootfs-boot
```

## Thor R38 Notes

- `jetson-agx-thor-devkit.conf` resolves through `t264.conf.common` and typically uses `tegra264-*` DTBs/BCTs, `bootloader/flash_l4t_t264_qspi.xml`, and `tools/kernel_flash/flash_l4t_t264_nvme.xml`.
- Thor configs may leave `BOARDREV` empty in `jetson_board_spec.cfg`; pass `BOARDREV=` explicitly and validate with `--allow-empty-boardrev`.
- Thor uses extra firmware classes compared with t234, including `bl31_t264.fip`, `hafnium_t264.fip`, `hpse*`, `sb*`, `mb2rf_t264.bin`, `aon-fw_t264.bin`, and `adsp0/1-fw_t264.bin`. Keep vendor-supplied binaries together.
- Supplier binary-only SDKs should be treated as prebuilt-artifacts mode: copy their DTB/BCT/kernel/module payloads into the BSP, confirm `rootfs/boot/Image`, `rootfs/boot/initrd`, `rootfs/lib/modules/<version>`, and `kernel/dtb/*.dtb`, then hand off to `jetson-flash-package`.

## Guardrails

- Treat `rootfs` cleanup as destructive. Require `--yes` before deleting rootfs contents.
- Prefer `depmod -b rootfs` from the host over chroot for module dependency generation unless target-side package installation is explicitly needed.
- Reinstall prebuilt DTB and BCT artifacts after any kernel build that can overwrite `kernel/dtb`.
- Do not run `l4t_initrd_flash.sh`, `flash.sh`, or destructive flash operations from this skill; use `jetson-flash-package`.

## References

- Read `references/ci-derived-flow.md` for the flow distilled from the provided GitLab CI.
- Read `references/prebuilt-artifacts-mode.md` for the first validation plan.
