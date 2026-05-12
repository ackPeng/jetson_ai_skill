# SDK Layout

Known SDK roots from the project notes:

- `/home/galbot/jetson/JP7.1/Linux_for_Tegra/`
- `/home/galbot/jetson_firmware/Linux_for_Tegra/`

An SDK root should contain at least:

- `apply_binaries.sh`
- `flash.sh`
- `tools/kernel_flash/l4t_initrd_flash.sh`
- `bootloader/generic/BCT/`
- `bootloader/generic/cfg/`
- `kernel/dtb/`
- `rootfs/`
- `source/nvbuild.sh`

SoC-specific source locations:

- Orin t234: `source/hardware/nvidia/t23x/nv-public/`
- Thor t264: `source/hardware/nvidia/t264/nv-public/`
- Shared Tegra overlays: `source/hardware/nvidia/tegra/nv-public/`

Important generated or installed artifact locations:

- Kernel image: `kernel/Image`
- Runtime DTBs and overlays: `kernel/dtb/`
- Optional boot copies: `rootfs/boot/`
- MB1 and MB2 BCT inputs: `bootloader/generic/BCT/`
- BPMP DTBs: commonly `bootloader/generic/`
- Internal flash layouts: `bootloader/generic/cfg/`
- Some Thor QSPI layouts: `bootloader/`
- External flash layouts: `tools/kernel_flash/`
