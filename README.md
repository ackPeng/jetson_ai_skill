# Jetson BSP Skills

This repository distills Jetson BSP bring-up workflows into Codex skills. It is aimed at custom carrier-board work on NVIDIA Jetson platforms, especially Orin/t234 with JetPack 6.x and Thor/t264 with JetPack 7.x.

The skills are designed to be used as a sequence. Start with context detection, validate or create the board config, prepare BSP artifacts, then generate or use flash packages.

## Skill Map

| Skill | Use For | Owns |
| --- | --- | --- |
| `jetson-bsp-context` | Identify SDK root, SoC profile, L4T/JetPack version, board tuple, and next step | Discovery and routing |
| `jetson-board-config` | Create or validate Jetson `<board>.conf` files | `DTB_FILE`, `TBCDTB_FILE`, BCT fields, flash layouts, board identity checks |
| `jetson-dts-port` | Modify source DTS/DTSI for a custom carrier board | Source device tree edits and reference discovery |
| `jetson-firmware-build` | Prepare rootfs, kernel, modules, DTBs, BCTs, and depmod | Build-side BSP artifacts before flashing |
| `jetson-flash-package` | Generate no-flash images, massflash packages, and run flash-only or online flashing | `l4t_initrd_flash.sh`, `flash.sh`, massflash, board tuple, checksums |

## Recommended Flow

1. Use `jetson-bsp-context` when the SDK path, board config, SoC profile, or board identity tuple is unclear.
2. Use `jetson-board-config` to create or validate the board `.conf`.
3. Use `jetson-dts-port` only when source DTS/DTSI files need to be changed. If the vendor only supplies binary DTBs/BCTs, stay in prebuilt-artifacts mode.
4. Use `jetson-firmware-build` to prepare `rootfs`, install kernel artifacts, install prebuilt DTB/BCT files, and run `depmod`.
5. Use `jetson-flash-package` to create no-flash/massflash packages or flash a recovery-mode device.

The pinmux spreadsheet editing/export step is intentionally outside these skills for now. The skills consume exported pinmux/BCT files or supplied binaries.

## Common Commands

Probe an SDK:

```bash
python3 jetson-bsp-context/scripts/probe-l4t.py \
  --sdk /home/galbot/jetson/JP7.1/Linux_for_Tegra \
  --json
```

Validate a Thor board config with the project reference tuple:

```bash
python3 jetson-board-config/scripts/check-board-conf.py \
  --sdk /home/galbot/jetson_firmware/Linux_for_Tegra \
  --config jetson-agx-thor-devkit \
  --boardid 3834 --boardsku 0008 --fab 400 --boardrev G.5 --chip-sku 00:00:00:A0
```

Prepare rootfs:

```bash
jetson-firmware-build/scripts/prepare-rootfs.sh \
  --sdk /home/galbot/jetson/JP7.1/Linux_for_Tegra \
  --rootfs-tar /path/to/Tegra_Linux_Sample-Root-Filesystem.tbz2 \
  --yes
```

Print a Thor massflash package command without executing it:

```bash
jetson-flash-package/scripts/make-massflash.sh \
  --sdk /home/galbot/jetson_firmware/Linux_for_Tegra \
  --config jetson-agx-thor-devkit \
  --boardid 3834 --boardsku 0008 --fab 400 --boardrev G.5 --chip-sku 00:00:00:A0 \
  --mode internal --rootdev internal --massflash 1
```

Add `--execute` only after reviewing the printed command.

## Important Notes

- Offline package generation must pass `BOARDID`, `BOARDSKU`, `FAB`, `BOARDREV`, and `CHIP_SKU` because no recovery-mode Jetson is available for EEPROM/chip probing.
- CI-derived Seeed/Orin tuples and the project Thor reference tuple live in `jetson-bsp-context/references/board-identity-tuples.md`.
- Online flashing commands may omit the board tuple when NVIDIA tools can read a connected recovery-mode target.
- For Thor/t264 R38 flows, local NVMe/UFS rootfs commonly uses `rootdev=internal`.
- `--massflash 5` can create very large `mfi_<board>/` directories because it stores multiple flashing workspaces. Use `--massflash 1` for smoke tests.
- A Ctrl-C interrupted `mfi_<board>.tar.gz` is not a valid package. Rename or delete partial tarballs before checksum or handoff.
- Do not run destructive flashing, `--erase-all`, fuse burning, or secure boot provisioning unless explicitly requested.

## References

- NVIDIA Jetson Thor flashing guide: https://docs.nvidia.com/jetson/archives/r38.4/DeveloperGuide/SD/FlashingSupportJetsonThor.html#before-you-begin
- Local CI examples and working notes live under `参考/`.

## Repository Layout

```text
jetson-bsp-context/      SDK and board-context discovery
jetson-board-config/     Board config creation and validation
jetson-dts-port/         Source device tree porting
jetson-firmware-build/   Rootfs, kernel, module, DTB, and BCT preparation
jetson-flash-package/    No-flash, massflash, flash-only, and online flashing
参考/                    Source reference files used while distilling the skills
```
