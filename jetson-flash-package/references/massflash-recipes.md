# Massflash Recipes

Always validate the board config first.

## Before flashing or packaging

The SDK root must contain the expected `bootloader/`, `kernel/`, `rootfs/`, `nv_tegra/`, and `tools/kernel_flash/` content. For online flashing, connect the host to the Jetson recovery port with a reliable USB cable and put the board into Force Recovery Mode.

Install host flash dependencies when needed:

```bash
sudo tools/l4t_flash_prerequisites.sh
```

The generic Thor command syntax is:

```bash
sudo ./tools/kernel_flash/l4t_initrd_flash.sh [options] <board> <rootdev>
```

For most Jetson Thor local NVMe/UFS root filesystem flows, use `internal` as `<rootdev>`.

Offline massflash package generation must pass the board identity tuple explicitly because no Jetson in recovery mode is available for EEPROM/chip probing. Online flashing commands may omit the tuple when the connected recovery-mode device can be probed by NVIDIA's scripts. For this repository's module-level board tuples, read `../../jetson-bsp-context/references/board-identity-tuples.md`.

## Jetson Thor online flash

Flash a recovery-mode Jetson Thor target directly with the board config defaults:

```bash
sudo ./tools/kernel_flash/l4t_initrd_flash.sh \
  jetson-agx-thor-devkit internal
```

Flash with explicit external NVMe layout when the board package requires it:

```bash
sudo ./tools/kernel_flash/l4t_initrd_flash.sh \
  --external-device nvme0n1p1 \
  -c tools/kernel_flash/flash_l4t_t264_nvme.xml \
  jetson-agx-thor-devkit internal
```

Use the convenience script when you want NVIDIA's script to auto-detect the connected recovery-mode board:

```bash
sudo ./nvsdkmanager_flash.sh --storage nvme0n1p1
```

Omit `--storage` when the board default storage is desired.

## QSPI only

For t234 style QSPI-only package:

```bash
sudo env BOARDID=3767 BOARDSKU=0003 FAB=300 BOARDREV=N.2 CHIP_SKU=00:00:00:D6 \
  ./tools/kernel_flash/l4t_initrd_flash.sh \
  -p "-c bootloader/generic/cfg/flash_t234_qspi.xml --no-systemimg" \
  --no-flash --massflash 5 --network usb0 \
  my-config external
```

## QSPI plus NVMe

For t234 style QSPI plus NVMe package:

```bash
sudo env BOARDID=3767 BOARDSKU=0003 FAB=300 BOARDREV=N.2 CHIP_SKU=00:00:00:D6 \
  ./tools/kernel_flash/l4t_initrd_flash.sh \
  --external-device nvme0n1p1 \
  -c tools/kernel_flash/flash_l4t_t234_nvme.xml \
  -S 80GiB \
  -p "-c bootloader/generic/cfg/flash_t234_qspi.xml --no-systemimg" \
  --no-flash --massflash 5 --network usb0 \
  my-config external
```

For t264 SDKs, replace the external layout with `tools/kernel_flash/flash_l4t_t264_nvme.xml` and use `bootloader/flash_l4t_t264_qspi.xml` as the QSPI layout only when you are intentionally using an Orin-like split internal/external command.

## Jetson Thor local NVMe/UFS

NVIDIA's r38.4 Thor flashing guide says `l4t_initrd_flash.sh` is the primary flashing tool and that `<rootdev>` should usually be `internal` for local NVMe SSD or UFS root filesystems. Thor board configs can carry the default `EXTERNAL_PT_LAYOUT` and `EXTERNAL_DEVICE`, so the command can be shorter than the t234 QSPI-plus-NVMe recipe.

Generate Thor no-flash images from a connected recovery-mode target, letting the tools read board information:

```bash
sudo ./tools/kernel_flash/l4t_initrd_flash.sh \
  --no-flash \
  jetson-agx-thor-devkit internal
```

Generate a Thor massflash package from a populated SDK when no target is connected:

```bash
sudo env BOARDID=3834 BOARDSKU=0008 FAB=400 BOARDREV=G.5 CHIP_SKU=00:00:00:A0 \
  ./tools/kernel_flash/l4t_initrd_flash.sh \
  --no-flash --massflash 5 --network usb0 \
  jetson-agx-thor-devkit internal
```

If the board package or official example explicitly requires an external-device workflow, use:

```bash
sudo env BOARDID=3834 BOARDSKU=0008 FAB=400 BOARDREV=G.5 CHIP_SKU=00:00:00:A0 \
  ./tools/kernel_flash/l4t_initrd_flash.sh \
  --external-device nvme0n1p1 \
  -c tools/kernel_flash/flash_l4t_t264_nvme.xml \
  --no-flash --massflash 5 --network usb0 \
  jetson-agx-thor-devkit internal
```

Flash previously generated Thor images:

```bash
sudo ./tools/kernel_flash/l4t_initrd_flash.sh \
  --flash-only \
  jetson-agx-thor-devkit internal
```

Flash a generated Thor massflash package:

```bash
sudo ./tools/kernel_flash/l4t_initrd_flash.sh \
  --flash-only --massflash 5 --network usb0 \
  jetson-agx-thor-devkit
```

Use a specific USB recovery path when multiple devices are attached:

```bash
sudo ./tools/kernel_flash/l4t_initrd_flash.sh \
  --flash-only --usb-instance 1-3 \
  jetson-agx-thor-devkit internal
```

## Size and validation notes

For Thor, the observed no-flash flow creates the unpacked `mfi_<board>/` directory before gzip starts. That directory includes `unified_flash/out/bsp_images`, `bsp_images1`, ..., up to the selected massflash count. `--massflash 5` is appropriate for a production multi-device package, but it can require hundreds of GB temporarily and a long single-threaded gzip step.

For skill validation or single-board dry runs, prefer `--massflash 1` first. If the goal is only to confirm dependency resolution and generated flashing workspaces, it is enough to inspect `mfi_<board>/`, `tools/kernel_flash/initrdflashparam.txt`, `bootloader/flashcmd.txt`, and the internal/external image directories. Only wait for `mfi_<board>.tar.gz` and checksum generation when the package must be copied to another machine or archived.

## Skill script

Use `scripts/make-massflash.sh` to print or execute these commands with a consistent board tuple and checksum generation.

For less common options such as `--direct`, `--external-only`, `--append`, `--qspi-only`, secure boot keys, disk encryption, `--keep`, `--reuse`, `--showlogs`, and partition-specific `-k`, consult NVIDIA's Thor flashing guide:

https://docs.nvidia.com/jetson/archives/r38.4/DeveloperGuide/SD/FlashingSupportJetsonThor.html#before-you-begin
