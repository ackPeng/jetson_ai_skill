# Prebuilt Versus Source DTS

Use prebuilt-artifacts mode when:

- The user has supplied `.dtb`, `.dtbo`, and BCT files.
- The goal is to validate board config, rootfs, kernel install, and massflash first.
- DTS source is unavailable or intentionally out of scope.

Use source-DTS mode when:

- The user provides schematic details and wants AI to modify DTS or DTSI files.
- The generated DTB must be reproducible from source.
- A runtime issue requires source-level changes.

Do not decompile a DTB into source as a default workflow. Decompilation is useful for inspection, but it loses comments, include structure, and intent.
