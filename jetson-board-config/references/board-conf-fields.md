# Board Config Fields

Board configs are shell fragments sourced by `flash.sh` and `l4t_initrd_flash.sh`. Keep them small, explicit, and close to a matching devkit config.

## Identity tuple

The build or flash environment normally supplies:

- `CONFIG`: board config name without `.conf`
- `BOARDID`: module board ID, such as `3767`, `3701`, or `3834`
- `BOARDSKU`: module SKU
- `FAB`: module or board FAB value
- `BOARDREV`: board revision
- `CHIP_SKU`: chip SKU string

Use these values whenever generating a no-device firmware package. If a target is connected in recovery mode for online flashing, NVIDIA's scripts can read the board and chip information from the device, so vendor flash wrappers may not pass the tuple explicitly.

Thor note: NVIDIA and vendor board spec files may intentionally leave `BOARDREV` empty for `jetson-agx-thor-devkit`. In that case, pass `BOARDREV=` to flash tools and use `check-board-conf.py --allow-empty-boardrev`.

## DTB fields

- `DTB_FILE`: kernel DTB used by the target.
- `TBCDTB_FILE`: bootloader DTB. Often equals `DTB_FILE`.
- `BPFDTB_FILE`: BPMP firmware DTB for platforms that use it.
- `BPFFILE`: BPMP firmware binary path.
- `OVERLAY_DTB_FILE`: comma-separated DTBO overlays passed to flash.
- `DCE_OVERLAY_DTB_FILE`: DCE overlay list when used.

Expected location is usually `kernel/dtb/`, except some firmware files live under `bootloader/` or `bootloader/generic/`.

## BCT fields

Expected location is usually `bootloader/generic/BCT/`.

- `PINMUX_CONFIG`: pinmux output from spreadsheet or board port.
- `PMC_CONFIG`: pad voltage configuration.
- `PMIC_CONFIG`: PMIC configuration.
- `DEVICE_CONFIG`: storage device controller config.
- `DEVICEPROD_CONFIG`: controller production settings.
- `PROD_CONFIG`: common production settings.
- `MB2_BCT`: MB2 misc BCT.
- `UPHY_CONFIG`: UPHY lane owner map.
- `EMC_BCT`, `WB0SDRAM_BCT`, `BPMP_MEM_CONFIG`: memory and BPMP memory configs.
- `SCR_CONFIG`: MB2 firewall or SCR config.
- `MINRATCHET_CONFIG`: rollback protection ratchet config.
- `GPIOINT_CONFIG`: GPIO interrupt map.

## Flash layout fields

- `EMMC_CFG`: internal layout in `bootloader/generic/cfg/`.
- `EXTERNAL_PT_LAYOUT`: external storage layout, often under `tools/kernel_flash/`.
- `EXTERNAL_DEVICE`: target external root device such as `nvme0n1p1`.

For QSPI plus NVMe massflash, the command often combines an external layout with `-p "-c bootloader/generic/cfg/flash_t234_qspi.xml --no-systemimg"` or the t264 equivalent.

For Jetson Thor, the common devkit flow uses `rootdev=internal` even when the local root filesystem is on NVMe or UFS. The board config can define `EXTERNAL_PT_LAYOUT=tools/kernel_flash/flash_l4t_t264_nvme.xml` and `EXTERNAL_DEVICE=nvme0n1p1`, while the flash command remains `l4t_initrd_flash.sh ... jetson-agx-thor-devkit internal`.
