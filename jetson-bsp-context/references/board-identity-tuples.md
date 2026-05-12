# Board Identity Tuples

Use this reference when an offline no-device package build needs explicit board
identity variables:

```bash
BOARDID=<id> BOARDSKU=<sku> FAB=<fab> BOARDREV=<rev> CHIP_SKU=<chip-sku>
```

These are project reference values for common Jetson modules. They are not
universal NVIDIA defaults. Prefer them for offline package generation only when
the exact target module is known, and still verify against the current SDK
`jetson_board_spec.cfg` or the target board's EEPROM/chip data when available.

## Module Tuples

| Module family | BOARDID | BOARDSKU | FAB | BOARDREV | CHIP_SKU |
| --- | ---: | ---: | ---: | --- | --- |
| Orin NX 16GB | `3767` | `0000` | `300` | `G.3` | `00:00:00:D3` |
| Orin NX 8GB | `3767` | `0001` | `300` | `M.3` | `00:00:00:D4` |
| Orin Nano 8GB | `3767` | `0003` | `300` | `N.2` | `00:00:00:D6` |
| Orin Nano 4GB | `3767` | `0004` | `300` | `N.2` | `00:00:00:D6` |
| AGX Orin 32GB | `3701` | `0004` | `500` | `J.0` | `00:00:00:D2` |
| AGX Orin 64GB | `3701` | `0005` | `500` | `M.0` | `00:00:00:D0` |
| AGX Thor T5000 reference | `3834` | `0008` | `400` | `G.5` | `00:00:00:A0` |

Some Orin Nano 4GB workflows need a matching `chip_info.bin_bak`. For Thor
local NVMe/UFS flows, use `rootdev=internal` unless the board package says
otherwise.
