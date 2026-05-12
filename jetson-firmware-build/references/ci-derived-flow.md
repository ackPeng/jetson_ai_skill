# CI-Derived Firmware Flow

The provided GitLab CI performs this sequence:

1. Validate `CONFIG`, `BOARDID`, `BOARDSKU`, `FAB`, `BOARDREV`, and `CHIP_SKU`.
2. Sync submodules.
3. Clean `rootfs/`.
4. Download and extract `ROOTFS_NAME`.
5. Apply special board workarounds, such as Orin Nano 4GB `chip_info.bin_bak`.
6. Run `apply_binaries.sh`.
7. Append image and commit metadata to `rootfs/etc/nv_tegra_release`.
8. Adjust kernel printk level in `rootfs/etc/sysctl.conf`.
9. Install or unpack cross toolchain.
10. Export `ARCH=arm64` and `CROSS_COMPILE`.
11. Run `source/nvbuild.sh`.
12. Run `source/do_copy.sh` when present.
13. Set `INSTALL_MOD_PATH` to `rootfs` and run `source/nvbuild.sh -i`.
14. Copy overlays to `rootfs/boot/`.
15. Optionally generate QSPI-only massflash with `jetson-flash-package`.
16. Optionally chroot into rootfs for package customization.
17. Run module dependency update.
18. Generate QSPI plus NVMe massflash with `jetson-flash-package`.
19. Write md5 and sha256 checksums with `jetson-flash-package`.

The skills split this into smaller explicit scripts so each step can be checked before the next one runs. Build artifacts stop at this skill; flash image generation and device flashing belong to `jetson-flash-package`.
