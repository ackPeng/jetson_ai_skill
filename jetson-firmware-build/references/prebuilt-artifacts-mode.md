# Prebuilt Artifacts Mode

Use this mode for the first validation plan: the user already has pinmux and device tree binaries and does not want AI to edit DTS yet.

## Inputs

- `bct-dir`: directory containing exported BCT files, such as pinmux, GPIO, padvoltage, PMIC, UPHY, and storage configs.
- `dtb-dir`: directory containing `.dtb` and `.dtbo` files.
- Board config pointing at those filenames.
- Rootfs tarball.
- Optional cross toolchain prefix.

## Order

1. Install BCT files into `bootloader/generic/BCT/`.
2. Install DTB and DTBO files into `kernel/dtb/`.
3. Validate the board config.
4. Prepare rootfs and apply binaries.
5. Build and install kernel modules if needed.
6. Reinstall prebuilt DTB and DTBO files after the build.
7. Copy DTBO or required DTB files to `rootfs/boot/` if the runtime image expects them there.
8. Hand off to `jetson-flash-package` to generate massflash or flash the target.

## Why reinstall after build

`nvbuild.sh` builds DTBs and many workflows copy results into `kernel/dtb/`. If the validation depends on supplied binaries, reinstall them after build so the later flash package uses the intended DTB.
