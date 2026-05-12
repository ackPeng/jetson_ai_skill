# DTS Porting Notes

Use the smallest file that owns the hardware boundary.

## File families

- `source/hardware/nvidia/t23x/nv-public/`: t234 Orin sources.
- `source/hardware/nvidia/t264/nv-public/`: t264 Thor sources.
- `source/hardware/nvidia/tegra/nv-public/`: shared overlay fragments.
- `nv-soc/`: SoC-level controller definitions and common properties.
- `nv-platform/`: module plus carrier board combinations.
- `overlay/`: optional hardware overlays and camera, audio, connector variants.

## Edit boundaries

- Put connector and carrier routing changes in carrier DTS or overlay files.
- Put SOM-only changes in module DTSI files only when the module design changed.
- Do not hand-edit generated pinmux BCT output as part of DTS porting.
- Keep camera overlays separate from base carrier enablement when possible.

## Validation hints

- Build with the SDK make path rather than standalone `dtc` when possible.
- Check include paths and labels before deeper debugging.
- Confirm the board config references the generated filename.
- If prebuilt DTB mode is active, do not edit DTS sources for the first validation.
