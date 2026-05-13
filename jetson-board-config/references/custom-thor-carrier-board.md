# Custom Thor Carrier Board Pattern

Use this reference when a Thor SDK already contains a custom carrier-board config and vendor-supplied artifacts, or when creating a new config from a Thor devkit base. The `recomputer-thor-carrier-j601` SDK layout is a concrete example of this pattern.

## Observed J601 tuple

The inspected custom board uses the Jetson AGX Thor T5000 module tuple:

```bash
BOARDID=3834
BOARDSKU=0008
FAB=400
BOARDREV=G.5
CHIP_SKU=00:00:00:A0
```

The board config name is `recomputer-thor-carrier-j601`, so the SDK root contains:

```text
recomputer-thor-carrier-j601.conf
```

## File layout

Keep custom carrier files in the same locations NVIDIA flash scripts already search:

```text
$L4T_DIR/
  recomputer-thor-carrier-j601.conf
  kernel/
    Image
    dtb/
      tegra264-p4071-0000+p3834-0008-recomputer-carrier.dtb
  bootloader/
    generic/BCT/
      recomputer-thor-carrier-j601-pinmux.dts
      recomputer-thor-carrier-j601-padvoltage-default.dts
    recomputer-thor-carrier-j601-pinmux.dtsi
    recomputer-thor-carrier-j601-padvoltage-default.dtsi
    recomputer-thor-carrier-j601-gpio-default.dtsi
  source/
    hardware/nvidia/t264/nv-public/nv-platform/
      tegra264-p4071-0000+p3834-0008-recomputer-carrier.dts
      Makefile
```

For pinmux and padvoltage, the `.dts` files under `bootloader/generic/BCT/` can be thin wrappers that include exported `.dtsi` payloads. In the observed SDK, the payload `.dtsi` files live under `bootloader/`, not under `bootloader/generic/BCT/`, so validate with the SDK's tools instead of assuming one fixed include directory.

For a real custom carrier, the pinmux-derived files are the first files that should come from the carrier schematic and NVIDIA's pinmux spreadsheet export. In the observed J601 SDK, that board-specific set is:

```text
bootloader/generic/BCT/<board>-pinmux.dts
bootloader/generic/BCT/<board>-padvoltage-default.dts
bootloader/<board>-pinmux.dtsi
bootloader/<board>-padvoltage-default.dtsi
bootloader/<board>-gpio-default.dtsi
```

The pinmux wrapper includes `<board>-pinmux.dtsi`, and that payload includes `<board>-gpio-default.dtsi`. The board config references only `PINMUX_CONFIG` and `PMC_CONFIG`; the GPIO payload is pulled in through the include chain.

## Board config recipe

Start from the nearest Thor devkit config, usually `p3834-0008-p4071-0000-nvme.conf` for the T5000 module on the P4071 carrier family. Keep common firmware, memory, storage, and fuse settings inherited unless the vendor BSP replaces them.

Use a minimal override policy. The J601 config differs from the Thor devkit baseline only in:

```text
DTB_FILE
PINMUX_CONFIG
PMC_CONFIG
```

It keeps `TBCDTB_FILE="${DTB_FILE}"` and leaves these inherited devkit/module artifacts unchanged: `BPFDTB_FILE`, `BPFFILE`, `EMC_BCT`, `WB0SDRAM_BCT`, `BPMP_MEM_CONFIG`, `MISC_CONFIG`, `SCR_CONFIG`, `PMIC_CONFIG`, `DEVICE_CONFIG`, `DEVICEPROD_CONFIG`, `PROD_CONFIG`, `MB2_BCT`, `MINRATCHET_CONFIG`, `GPIOINT_CONFIG`, and `UPHY_CONFIG`.

The J601-style custom board uses these carrier-specific assignments:

```bash
source "${LDK_DIR}/t264.conf.common";

DTB_FILE="tegra264-p4071-0000+p3834-0008-recomputer-carrier.dtb";
TBCDTB_FILE="${DTB_FILE}";
PINMUX_CONFIG="recomputer-thor-carrier-j601-pinmux.dts";
PMC_CONFIG="recomputer-thor-carrier-j601-padvoltage-default.dts";

EXTERNAL_PT_LAYOUT="tools/kernel_flash/flash_l4t_t264_nvme.xml";
EXTERNAL_DEVICE="nvme0n1p1";
```

For a pure naming-flow test that reuses devkit electrical content, either keep the devkit artifact filenames or make board-name copies only for the small set under test, such as `DTB_FILE`, `PINMUX_CONFIG`, and `PMC_CONFIG`. Do not create renamed copies of BPMP, PMIC, UPHY, memory, firewall, ratchet, GPIO interrupt, or device/product BCT files unless those files were actually regenerated or supplied by the board vendor.

Avoid this over-broad pattern:

```bash
BPFDTB_FILE="<board>-bpmp.dtb";
PMIC_CONFIG="<board>-pmic.dts";
UPHY_CONFIG="<board>-uphy-lanes.dts";
GPIOINT_CONFIG="<board>-gpioint.dts";
MISC_CONFIG="<board>-misc.dts";
SCR_CONFIG="<board>-firewall.dts";
DEVICE_CONFIG="<board>-device.dts";
DEVICEPROD_CONFIG="<board>-deviceprod.dts";
PROD_CONFIG="<board>-prod.dts";
MB2_BCT="<board>-mb2-bct-misc.dts";
MINRATCHET_CONFIG="<board>-ratchet.dts";
```

That pattern makes the config look custom but increases risk, because those artifacts are module/platform firmware inputs, not carrier pinmux exports.

## DTS build/install recipe

When source is available, add the custom DTB to the Thor platform Makefile:

```make
dtb-y += tegra264-p4071-0000+p3834-0008-recomputer-carrier.dtb
```

The observed vendor-added build helper flow is:

```bash
cd "$L4T_DIR/source"
./nvbuild.sh
./do_copy.sh
./nvbuild.sh -i
```

`do_copy.sh` is not a guaranteed NVIDIA SDK script; in the inspected J601 SDK it is a vendor/project artifact-copy helper. It bridges NVIDIA's build output directory and the BSP staging directory: build products come from `source/kernel_out/`, while flash/package generation later reads from `kernel/Image` and `kernel/dtb/`. In this SDK it copies:

```text
source/kernel_out/kernel/kernel-noble/arch/arm64/boot/Image -> kernel/Image
source/kernel_out/kernel-devicetree/generic-dts/dtbs/*.dtb -> kernel/dtb/
```

If `source/do_copy.sh` is absent, copy the required artifacts explicitly from `source/kernel_out/` into `kernel/Image` and `kernel/dtb/`.

After kernel install, ensure the runtime rootfs has the selected kernel:

```bash
cp "$L4T_DIR/kernel/Image" "$L4T_DIR/rootfs/boot/Image"
sudo "$L4T_DIR/tools/l4t_update_initrd.sh"
```

If the board is binary-only, skip source rebuild and only verify the supplied `kernel/Image`, `kernel/dtb/*.dtb`, `rootfs/lib/modules/<kernel-version>/`, and BCT files.

For rootfs and toolchain preparation, treat the vendor `thor_build_flash.sh prepare` stage as a useful phase reference: clean/extract rootfs, run `apply_binaries.sh`, optionally tag `nv_tegra_release`, and extract the cross toolchain. Keep release-matched package URLs in the firmware-build skill reference: `../../jetson-firmware-build/references/rootfs-toolchain-sources.md`.

## Flash and package recipe

For direct online flashing, a vendor helper script may rely on the attached recovery-mode board:

```bash
sudo env BOARDID=3834 BOARDSKU=0008 FAB=400 BOARDREV=G.5 CHIP_SKU=00:00:00:A0 \
  ./tools/kernel_flash/l4t_initrd_flash.sh \
  recomputer-thor-carrier-j601 internal
```

For no-device package generation, pass the tuple explicitly:

```bash
sudo env BOARDID=3834 BOARDSKU=0008 FAB=400 BOARDREV=G.5 CHIP_SKU=00:00:00:A0 \
  ./tools/kernel_flash/l4t_initrd_flash.sh \
  --no-flash --massflash 1 --network usb0 \
  recomputer-thor-carrier-j601 internal
```

The same command can be produced by the flash-package helper:

```bash
jetson-flash-package/scripts/make-massflash.sh \
  --sdk "$L4T_DIR" \
  --config recomputer-thor-carrier-j601 \
  --boardid 3834 --boardsku 0008 --fab 400 --boardrev G.5 --chip-sku 00:00:00:A0 \
  --mode internal --rootdev internal --massflash 1
```

## Validation checklist

Run board-config validation before building or packaging:

```bash
python3 jetson-board-config/scripts/check-board-conf.py \
  --sdk "$L4T_DIR" \
  --config recomputer-thor-carrier-j601 \
  --boardid 3834 --boardsku 0008 --fab 400 --boardrev G.5 --chip-sku 00:00:00:A0
```

Then check:

- `DTB_FILE` exists under `kernel/dtb/`.
- `TBCDTB_FILE` is either a real UEFI DTB or intentionally equals `DTB_FILE`.
- `PINMUX_CONFIG` and `PMC_CONFIG` wrappers exist under `bootloader/generic/BCT/`.
- Included pinmux, GPIO, and padvoltage payloads exist where the SDK scripts can resolve them.
- `EXTERNAL_PT_LAYOUT` is a t264 layout when the selected DTB is `tegra264-*`.
- `rootdev` is `internal` for the normal Thor local NVMe/UFS flow unless the vendor BSP says otherwise.

## Thor-specific cautions

- Some Thor devkit configs use a separate `uefi_tegra264-*.dtb`; J601 uses `TBCDTB_FILE="${DTB_FILE}"`. Treat both as valid patterns, but verify the file actually exists.
- The observed config changes `PMIC_CONFIG` when `board_id=3834`, `board_sku=0008`, and `FAB > 400`. Do not silently reuse `FAB=400` for later module revisions without checking whether the PMIC BCT switch should apply.
- `jetson_board_spec.cfg` may not list the custom carrier board name. For offline CI or massflash package creation, explicit `BOARDID`, `BOARDSKU`, `FAB`, `BOARDREV`, and `CHIP_SKU` environment variables are the important inputs.
- Vendor scripts often combine prepare, build, and flash. Split those phases inside the skill workflow so package generation can be reproduced without a connected board.
