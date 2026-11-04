# Feature Mapping

This document records how the MCreator 2026.3 feature set maps to the Fabric 1.21.11 generator.
Status values:

- **Supported** — implemented and generated for Fabric 1.21.11.
- **Partial** — implemented with a documented limitation.
- **Not applicable** — depends on a platform feature that Fabric 1.21.11 does not provide.
- **Roadmap** — planned; not generated yet.

## 1. Block and item features

| # | Feature | Fabric 1.21.11 | Notes |
|---:|---|---|---|
| 1 | Multipart block models | Supported | `multipartModel` is consumed by the block templates |
| 2 | Forced redstone conduction | Supported | `forceRedstoneConductor` |
| 3 | Block base property sets | Supported | Stairs, slabs, fences, walls, doors, trapdoors, panes, leaves |
| 4 | Item model definitions | Supported | `assets/<namespace>/items/<item>.json` |
| 5 | Equipment assets | Supported | `assets/<namespace>/equipment/<name>.json` |
| 6 | Crafting remainders | Supported | `craftRemainder`; per-craft damage remainders are not available in 1.21.11 |
| 7 | Enchantment effects | Roadmap | Requires the 2026.3 enchantment component schema |
| 8 | Loot modifiers | Roadmap | Requires the 2026.3 loot modifier schema |
| 9 | Creative tab title/icon | Supported | Tab initialiser |
| 10 | Armour unbreakable flag | Roadmap | Pending the 2026.3 armour definition update |
| 11 | Piglin currency tag | Supported | Item tag generation |
| 12 | Banner patterns | Supported | `ProvidesBannerPatterns` component |
| 13 | Shield behaviour | Supported | `BlocksAttacks` component |
| 14 | Custom item properties | Supported | `itemproperties` mappings |
| 15 | Fluid rendering | Partial | Static tint; biome-aware fluid tint is approximated |

## 2. Entity and world features

| # | Feature | Status | Notes |
|---:|---|---|---|
| 16 | Custom AI attack goals | Roadmap | 2026.3 AI task schema |
| 17 | Raytrace reset conditions | Roadmap | Procedure block |
| 18 | Synced-data conditions | Roadmap | Procedure block |
| 19 | Cross-product maths | Roadmap | Procedure block |
| 20 | Dimension travel triggers | Supported | `ServerEntityWorldChangeEvents` |
| 21 | World load/unload triggers | Supported | `ServerWorldEvents` |
| 22 | Custom world generation features | Supported | Configured and placed features |
| 23 | Structure features | Supported | Structure feature and configuration templates |

## 3. Configuration and integration

| # | Feature | Status | Notes |
|---:|---|---|---|
| 24 | Configuration files | Supported | Forge Config API Port 21.11.1, conditional dependency |
| 25 | Commands | Supported | Brigadier integration |
| 26 | Networking payloads | Supported | `playC2S` / `playS2C` |
| 27 | Key bindings | Supported | `KeyBindingHelper` |
| 28 | Data attachments (variables) | Supported | `AttachmentRegistry` |
| 29 | Config UI | Supported | Generated configuration screen |

## 4. Roadmap

The remaining items require the corresponding 2026.3 schema or additional runtime APIs:

- enchantment effect components;
- loot modifiers;
- armour unbreakable flag;
- custom AI attack goals;
- raytrace reset, synced-data and cross-product procedure blocks;
- biome-aware fluid tinting.

See `06-KNOWN-LIMITATIONS.md` for impact and scheduling notes.
