---
name: jetson-dts-port
description: Modify Jetson Linux device tree sources for custom carrier-board bring-up. Use when adapting devkit DTS and DTSI files to a schematic, changing I2C SPI UART GPIO PCIe USB CSI camera audio display regulator fixed-clock or overlay nodes, selecting source files under source hardware nvidia t23x or t264, validating includes, and preparing source-DTS mode for kernel DTB builds.
---

# Jetson DTS Port

## Overview

Use this skill only when the task requires source device tree edits. If the user supplies prebuilt DTB or DTBO files and wants firmware first, use `jetson-board-config` and `jetson-firmware-build` instead.

## Workflow

1. Identify SDK root and SoC with `jetson-bsp-context`.
2. Locate the nearest reference DTS using `scripts/find-dts-references.py`.
3. Preserve NVIDIA's layering:
   - SoC files describe common controller blocks.
   - Module files describe SOM-level resources.
   - Carrier files describe connectors, buses, regulators, endpoint wiring, and board-specific enablement.
   - Overlay files describe optional hardware combinations.
4. Apply the schematic-derived changes in the smallest carrier or overlay file that owns the hardware.
5. Validate includes, labels, phandles, GPIO macros, and regulator references.
6. Build DTBs through `jetson-firmware-build`, then verify the generated `.dtb` or `.dtbo` is the one referenced by the board config.

## Porting Checklist

- Confirm the bus instance and pinmux match before enabling a node.
- Check `status`, `compatible`, `reg`, `interrupts`, `clocks`, `resets`, `power-domains`, `phys`, `phy-names`, and supplies.
- Keep camera, display, audio, and PCIe changes separated when possible. These subsystems have different debug loops.
- Avoid editing generated pinmux BCT output by hand unless the user explicitly requests it.
- For first firmware validation with supplied binaries, do not reconstruct DTS from a decompiled DTB unless the user asks for source recovery.

## Commands

Find likely reference files:

```bash
python3 jetson-dts-port/scripts/find-dts-references.py \
  --sdk "$L4T_DIR" \
  --soc t264 \
  --terms p4071 p3834 camera
```

## References

- Read `references/dts-porting-notes.md` for file placement and edit boundaries.
- Read `references/prebuilt-vs-source-dts.md` when deciding whether to modify sources or use supplied binaries.
