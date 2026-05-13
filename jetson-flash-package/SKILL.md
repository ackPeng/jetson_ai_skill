---
name: jetson-flash-package
description: "Create and use Jetson Linux flash images, no-flash packages, massflash packages, and flash-only workflows with l4t_initrd_flash.sh or flash.sh. Use whenever the user asks to make a Jetson firmware/flash package, generate mfi_<board>.tar.gz, run massflash, flash a board in recovery mode, inspect flash package dependencies, pass BOARDID/BOARDSKU/FAB/BOARDREV/CHIP_SKU for offline generation, or compare Orin t234 and Thor t264 flashing commands."
---

# Jetson Flash Package

## Overview

Use this skill after `jetson-firmware-build` has prepared the SDK root: populated `rootfs`, installed kernel Image/modules/DTBs, applied vendor binaries, and validated board config references.

This skill owns the flashing boundary: no-flash image generation, massflash package creation, flash-only execution, online recovery-mode flashing, board identity tuples, checksums, and package inspection.

## Workflow

1. Confirm the SDK root, board config, SoC profile, and target storage.
2. Check that `bootloader/`, `kernel/`, `rootfs/`, `nv_tegra/`, and `tools/kernel_flash/l4t_initrd_flash.sh` exist.
3. Decide whether the task is offline package generation or online flashing:
   - Offline package/no-device CI: pass `BOARDID`, `BOARDSKU`, `FAB`, `BOARDREV`, and `CHIP_SKU` explicitly.
   - Online flashing with a board in recovery mode: NVIDIA scripts may read board and chip information directly.
   - For common module tuples or the project Thor reference, consult `../jetson-bsp-context/references/board-identity-tuples.md`.
   - For a Thor custom carrier like `recomputer-thor-carrier-j601`, consult `../jetson-board-config/references/custom-thor-carrier-board.md`.
4. For Thor t264, prefer `rootdev=internal` for local NVMe/UFS flows unless the board package says otherwise.
5. Print the exact command before execution. Treat sudo, `--flash-only`, `--erase-all`, and partition-specific flashing as high-impact operations.
6. When generating a package, inspect `mfi_<board>/` and only wait for `mfi_<board>.tar.gz` when the package must be copied or archived.
7. After a complete package is generated, write md5 and sha256 checksums.

## Common Commands

Read `references/massflash-recipes.md` for copy-ready commands covering:

- Thor direct online flash.
- Thor no-flash image generation and flash-only.
- Thor massflash package generation and massflash execution.
- Orin t234 QSPI-only and QSPI plus NVMe massflash.
- Size and validation notes for large `mfi_<board>/` directories.

Use `scripts/make-massflash.sh` to print or execute a consistent no-flash massflash command:

```bash
jetson-flash-package/scripts/make-massflash.sh \
  --sdk "$L4T_DIR" \
  --config jetson-agx-thor-devkit \
  --boardid 3834 --boardsku 0008 --fab 400 --boardrev G.5 --chip-sku 00:00:00:A0 \
  --mode internal --rootdev internal --massflash 1
```

Add `--execute` only after reviewing the printed command.

## Guardrails

- Do not flash unless the user explicitly asks to flash or the task clearly requires it.
- Do not assume a connected Jetson is disposable. Confirm the target board/config/storage before `--flash-only`, direct online flash, `--erase-all`, or partition flashing.
- Do not treat a Ctrl-C interrupted `mfi_<board>.tar.gz` as usable. Rename or delete partial tarballs before checksums or handoff.
- Do not burn fuses, provision secure boot keys, erase all storage, or run destructive partition operations unless explicitly requested.
- For Thor package validation, prefer `--massflash 1` first; `--massflash 5` can create five `bsp_images*` workspaces and require hundreds of GB temporarily.

## Official Reference

For additional parameters and current Thor-specific options, consult NVIDIA's Jetson Thor flashing guide, especially "Before You Begin" and "Basic Flashing Script Usage":

https://docs.nvidia.com/jetson/archives/r38.4/DeveloperGuide/SD/FlashingSupportJetsonThor.html#before-you-begin

For project board identity examples, read `../jetson-bsp-context/references/board-identity-tuples.md`.

For custom Thor carrier board packaging, read `../jetson-board-config/references/custom-thor-carrier-board.md`.
