# Version Profiles

Keep version and SoC assumptions explicit.

## t234 Orin profile

Typical for JetPack 6.x and L4T r36.x. The provided CI file uses:

- `JETPACKVER=6.2`
- `JETSONVER=36.4.3`
- `ROOTFS_NAME=Tegra_Linux_Sample-Root-Filesystem_r36.4.3_aarch64.tbz2`
- `tegra234` DTB and BCT filenames
- `flash_t234_qspi.xml`
- `flash_l4t_nvme.xml` or `flash_l4t_t234_nvme.xml` depending on SDK layout

Common board IDs in the CI:

- `3767` for Orin NX and Orin Nano family
- `3701` for AGX Orin family

## t264 Thor profile

Typical for JetPack 7.x and L4T r38.x. Thor-capable SDKs usually contain:

- `t264.conf.common`
- `tegra264` DTB and BCT filenames
- `flash_l4t_t264_nvme.xml`
- `flash_l4t_t264_ufs.xml`
- P3834 module references and P3971 or P4071 carrier references
- `rootdev=internal` for the normal Jetson Thor local NVMe/UFS root filesystem flow
- extra firmware classes not present in the t234 flow, such as ATF `bl31_t264.fip`, Hafnium, HPSE, StrongBox, MB2-RF, AON, ADSP0, and ADSP1 binaries

## Mixed SDK caution

Some SDKs contain both t23x and t264 files. Select the active profile from the board config and DTB names, not from the SDK folder name alone.
