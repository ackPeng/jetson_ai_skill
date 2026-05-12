---
name: jetson-bsp-context
description: Identify Jetson BSP development context before board porting, board configuration, kernel or DTB installation, rootfs preparation, flash image generation, and bring-up debugging. Use when working in or near a Linux_for_Tegra SDK, choosing between JetPack and L4T versions, distinguishing t234 Orin and t264 Thor layouts, collecting CONFIG BOARDID BOARDSKU FAB BOARDREV CHIP_SKU values, or deciding which Jetson BSP skill should handle the next step.
---

# Jetson BSP Context

## Overview

Use this skill first when the request does not already pin down the SDK root, SoC, L4T profile, board config name, and board identity tuple. Produce a short context report, then route the work to the narrower skill.

## Workflow

1. Locate the SDK root. Prefer a user-provided `Linux_for_Tegra` path. Otherwise inspect the paths in `references/sdk-layout.md`.
2. Identify the profile:
   - `t234` means Orin-class BSP flow, typically JP6 or L4T r36.
   - `t264` means Thor-class BSP flow, typically JP7 or L4T r38.
   - Some SDKs contain both; choose from the board config or SoC-specific DTB names.
3. Collect the board identity tuple: `CONFIG`, `BOARDID`, `BOARDSKU`, `FAB`, `BOARDREV`, and `CHIP_SKU`.
   - When the user is working from this repository's CI-supported boards, consult `references/board-identity-tuples.md` before guessing tuple values.
4. Check whether the task is source-DTS mode or prebuilt-artifacts mode. If the user has only DTB and BCT binaries or exported files, route to prebuilt-artifacts mode.
5. Route the next step:
   - Board config creation or validation: use `jetson-board-config`.
   - Rootfs, kernel, DTB install, and depmod: use `jetson-firmware-build`.
   - No-flash image generation, massflash packages, and flashing: use `jetson-flash-package`.
   - Source device tree editing: use `jetson-dts-port`.

## Commands

Run the probe script when the SDK path or profile is not obvious:

```bash
python3 jetson-bsp-context/scripts/probe-l4t.py \
  --sdk /home/galbot/jetson/JP7.1/Linux_for_Tegra
```

For JSON output:

```bash
python3 jetson-bsp-context/scripts/probe-l4t.py \
  --sdk /home/galbot/jetson/JP7.1/Linux_for_Tegra \
  --json
```

## Guardrails

- Do not mix r36 Orin assumptions with r38 Thor assumptions. Re-check the profile whenever a config, DTB, or BCT filename changes between `tegra234` and `tegra264`.
- Treat the SDK root as a build workspace. Do not clean `rootfs`, replace DTBs, generate massflash output, or flash a device from this skill.
- Prefer existing board configs and CI matrix values over guessed board IDs.

## References

- Read `references/sdk-layout.md` for the local SDK roots and important directories.
- Read `references/version-profiles.md` when the task involves JP6, JP7, r36, r38, Orin, or Thor version boundaries.
- Read `references/board-identity-tuples.md` for CI-derived Seeed board tuples and the project Thor reference tuple.
