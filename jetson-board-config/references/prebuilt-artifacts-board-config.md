# Prebuilt Artifacts Board Config

Use this mode when pinmux and DTB artifacts are supplied without source.

## Inputs

- Exported BCT files from pinmux spreadsheet or prior BSP.
- Prebuilt `.dtb` and optional `.dtbo` files.
- A matching devkit board config to source or copy.
- Board identity tuple: `BOARDID`, `BOARDSKU`, `FAB`, `BOARDREV`, `CHIP_SKU`.

## Board config rules

1. Keep the board config filename stable and use it as `CONFIG`.
2. Point `DTB_FILE` and `TBCDTB_FILE` at the supplied DTB filename after installing it to `kernel/dtb/`.
3. Point BCT fields at supplied files installed to `bootloader/generic/BCT/`.
4. Keep inherited values for firmware binaries and memory configs unless the supplied BSP explicitly replaces them.
5. Use the matching flash layout for the boot media. For NVMe rootfs, verify both the external layout and QSPI layout.
6. Validate with `scripts/check-board-conf.py` before running massflash.

## Failure patterns

- The board config names a DTB that was overwritten by a later kernel build.
- A BCT filename exists in source control but was not copied into `bootloader/generic/BCT/`.
- `EXTERNAL_PT_LAYOUT` names a t234 XML while the DTB is tegra264, or the reverse.
- `BOARDID` and `BOARDSKU` are inherited from a devkit job and do not match the module being flashed.
