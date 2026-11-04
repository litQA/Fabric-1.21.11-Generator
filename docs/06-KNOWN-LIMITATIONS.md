# Known Limitations and Roadmap

## 1. Risk register

Severity: **High** — delivery blocker; **Medium** — may affect specific element types; **Low** —
documented limitation with a workaround.

| ID | Severity | Area | Description | Mitigation | Status |
|---|---|---|---|---|---|
| R1 | Medium | Generator API | Definitions follow the 2026.3 schema; future MCreator API changes may require definition updates. | Version range is explicit in `plugin.json`; validate against each MCreator release. | Open |
| R2 | Medium | Minecraft API | Templates must track Minecraft 1.21.11 API changes. | API signatures verified with `javap`; templates covered by the validation suite. | Open |
| R3 | Low | Mappings | Block/item/entity mapping tables originate from the 26.1.2 line. Registry entries that do not exist in 1.21.11 could be offered to users. | Mapping tables are reviewed when updating the generator; unresolved entries are reported. | Open |
| R4 | Medium | Gradle | The wrapper defaults to a local Gradle distribution. | `tools/set-gradle-distribution.ps1` switches between local and public URLs. | By design |
| R5 | Low | Configuration | Configuration code requires Forge Config API Port and Night Config. | Added conditionally when a configuration element is generated; declared in `fabric.mod.json`. | By design |
| R6 | Low | Entity NBT | Fabric has no persistent per-entity data equivalent to NeoForge. | `entity_nbt_*` uses a session-local UUID map; values do not survive a world reload. | Limitation |
| R7 | Low | Fluid tinting | `SimpleFluidRenderHandler` uses a fixed tint. | Biome-aware tinting is approximated with a static ARGB value. | Limitation |
| R8 | Low | Item remainders | `Item#getCraftingRemainder` is final in 1.21.11. | Static remainders use `craftRemainder`; per-craft damage remainders are unsupported. | Limitation |
| R9 | Low | Features | Some 2026.3 features are not implemented yet. | Listed in section 3 and in `04-FEATURE-MAPPING.md`. | Roadmap |
| R10 | Low | Distribution | The plugin archive is built as a resource-only ZIP. | Validated by `check-archive.ps1`; installable as a generator plugin. | By design |

## 2. Known limitations

1. **Entity NBT persistence** — `entity_nbt_*` values are stored per server session and are not saved
   with the world.
2. **Fluid tint** — fluid render handlers use a static tint instead of biome/position sampling.
3. **Per-craft damage remainders** — not available in 1.21.11; static remainders are supported.
4. **Configuration runtime dependency** — projects using configuration elements require the Forge
   Config API Port mod at runtime.
5. **Render layers** — custom JSON models with translucency require the block transparency type to be
   set accordingly.
6. **Mapping coverage** — mapping tables are shared with the 26.1.2 line; 1.21.11-only entries may be
   missing from selector lists.

## 3. Roadmap

| Priority | Item | Dependency |
|---|---|---|
| 1 | Enchantment effect components | 2026.3 enchantment schema |
| 2 | Loot modifiers | 2026.3 loot modifier schema |
| 3 | Armour unbreakable flag | 2026.3 armour definition |
| 4 | Custom AI attack goals | 2026.3 AI task schema |
| 5 | Raytrace reset, synced-data and cross-product procedure blocks | 2026.3 procedure definitions |
| 6 | Biome-aware fluid tint | Position-aware fluid render handler |

## 4. Maintenance guidance

- Run `validate.ps1` and `check-archive.ps1` before every release.
- Rebuild the acceptance workspaces after changing definitions, workspace base files or mappings.
- Update `03-DIFF-MATRIX.md` when porting a new MCreator or Minecraft API change.
- Keep `plugin.json`, `gradle.properties` and `CHANGELOG.md` in sync for each release.
