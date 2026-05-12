# SDK Layout

Use the user-provided `Linux_for_Tegra` directory as `$L4T_DIR`. If no SDK root
is provided, search the current project for directories named `Linux_for_Tegra`
before falling back to machine-specific paths.

An SDK root should contain at least:

- `$L4T_DIR/apply_binaries.sh`
- `$L4T_DIR/flash.sh`
- `$L4T_DIR/tools/kernel_flash/l4t_initrd_flash.sh`
- `$L4T_DIR/bootloader/generic/BCT/`
- `$L4T_DIR/bootloader/generic/cfg/`
- `$L4T_DIR/kernel/dtb/`
- `$L4T_DIR/rootfs/`
- `$L4T_DIR/source/nvbuild.sh`

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
