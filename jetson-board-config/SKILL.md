---
name: jetson-board-config
description: Create, adapt, and validate Jetson Linux board configuration files used by flash.sh and l4t_initrd_flash.sh. Use for custom carrier board configs, CONFIG conf files, prebuilt DTB and BCT references, DTB_FILE TBCDTB_FILE BPFDTB_FILE PINMUX_CONFIG PMIC_CONFIG PMC_CONFIG UPHY_CONFIG EMMC_CFG EXTERNAL_PT_LAYOUT OVERLAY_DTB_FILE fields, and CONFIG BOARDID BOARDSKU FAB BOARDREV CHIP_SKU matrix checks.
---

# Jetson Board Config

## Overview

Use this skill to create or validate a Jetson board `.conf` file that the SDK can source while generating firmware. It is the bridge between exported pinmux/BCT artifacts, prebuilt or built DTBs, and the flashing tools.

## Workflow

1. Start with `jetson-bsp-context` if the SDK root, SoC, or board identity tuple is unknown.
   - For common module tuples or the project Thor reference, use `../jetson-bsp-context/references/board-identity-tuples.md` as a tuple reference.
2. Choose the nearest devkit board config:
   - For Orin t234, start from `p3768-0000-p3767-0000-a0-nvme.conf`, `p3737-0000-p3701-0000.conf`, or another matching module and carrier reference.
   - For Thor t264, start from `p3834-0008-p4071-0000-nvme.conf` or the matching P-number reference.
3. Create a custom `.conf` at the SDK root. Keep the inherited common file and override only board-specific values.
4. In prebuilt-artifacts mode, reference the supplied BCT and DTB filenames directly. Do not assume the DTB is rebuilt from source.
5. Validate references with `scripts/check-board-conf.py`. For Thor configs whose board spec intentionally leaves `BOARDREV` blank, add `--allow-empty-boardrev`.
6. Hand off to `jetson-firmware-build` after the config is valid.

## Required Checks

Check these fields when present:

- Kernel and boot DTBs: `DTB_FILE`, `TBCDTB_FILE`, `BPFDTB_FILE`, `BPFFILE`, `OVERLAY_DTB_FILE`, `DCE_OVERLAY_DTB_FILE`.
- BCT files: `PINMUX_CONFIG`, `PMC_CONFIG`, `PMIC_CONFIG`, `DEVICE_CONFIG`, `DEVICEPROD_CONFIG`, `PROD_CONFIG`, `MB2_BCT`, `UPHY_CONFIG`, `EMC_BCT`, `WB0SDRAM_BCT`, `BPMP_MEM_CONFIG`, `SCR_CONFIG`, `MINRATCHET_CONFIG`, `GPIOINT_CONFIG`.
- Flash layouts: `EMMC_CFG`, `EXTERNAL_PT_LAYOUT`, `EXTERNAL_DEVICE`.
- Board identity: `CONFIG`, `BOARDID`, `BOARDSKU`, `FAB`, `BOARDREV`, `CHIP_SKU`.

## Commands

Validate a board config:

```bash
python3 jetson-board-config/scripts/check-board-conf.py \
  --sdk "$L4T_DIR" \
  --config p3834-0008-p4071-0000-nvme
```

Validate with explicit board identity:

```bash
python3 jetson-board-config/scripts/check-board-conf.py \
  --sdk "$L4T_DIR" \
  --config my-custom-board \
  --boardid 3834 --boardsku 0008 --fab 500 --boardrev A.0 --chip-sku 00:00:00:D0
```

Validate a Jetson Thor devkit config with the project reference tuple:

```bash
python3 jetson-board-config/scripts/check-board-conf.py \
  --sdk "$L4T_DIR" \
  --config jetson-agx-thor-devkit \
  --boardid 3834 --boardsku 0008 --fab 400 --boardrev G.5 --chip-sku 00:00:00:A0
```

Render a draft custom config from a devkit base:

```bash
python3 jetson-board-config/scripts/render-board-conf.py \
  --base p3834-0008-p4071-0000-nvme \
  --dtb my-board.dtb \
  --pinmux my-pinmux.dts \
  --pmc my-padvoltage.dts \
  --pmic my-pmic.dts \
  --uphy my-uphy.dts \
  --external-layout tools/kernel_flash/flash_l4t_t264_nvme.xml \
  --external-device nvme0n1p1 \
  --overlay my-camera.dtbo \
  --output "$L4T_DIR/my-custom-board.conf"
```

## Guardrails

- Do not edit pinmux spreadsheets from this skill. Accept exported BCT files as inputs.
- Do not edit DTS sources from this skill. Use `jetson-dts-port` for source changes.
- Keep prebuilt DTB filenames stable through the build. Kernel build steps may overwrite `kernel/dtb`; reinstall prebuilt artifacts before massflash when needed.
- If the config sources a devkit config, verify that custom overrides come after the `source` line.
- For Thor, check both kernel DTB and UEFI DTB naming. `DTB_FILE=tegra264-...dtb` and `TBCDTB_FILE=uefi_tegra264-...dtb` are different files, unlike many Orin configs where they may match.

## References

- Read `references/board-conf-fields.md` for field meanings and expected locations.
- Read `references/prebuilt-artifacts-board-config.md` for the first validation plan using supplied DTB and BCT artifacts.
- Read `../jetson-bsp-context/references/board-identity-tuples.md` for module-level board identity examples.
