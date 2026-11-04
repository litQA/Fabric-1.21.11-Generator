# Adaptation Notes

## 1. Scope

The generator adapts the Fabric-Generator-MCreator 26.1.2 tree to Minecraft 1.21.11 and the MCreator
2026.3 plugin API, with 1.21.8 behaviour used where the 26.x implementation depends on APIs that do
not exist in 1.21.11. This document summarises the structural decisions and the compatibility
adjustments applied to the templates.

## 2. Structure

| Area | Decision |
|---|---|
| Entry generator | `fabric-1.21.11/` with `generator.yaml`, element definitions, mappings, templates, procedures and triggers |
| Base layers | `fabric-1.21.11-base/datapack` and `fabric-1.21.11-base/neoforge` embedded in the plugin |
| Base-layer imports | `datapack` and `neoforge` imported from the entry generator; their `procedures` and `triggers` are excluded so Fabric implementations are authoritative |
| Java models | `java_models.key: mojmap-1.21.x` |
| Workspace base | `workspacebase/` copied into every generated project; `subversion` invalidates stale copies |
| Distribution | Resource-only ZIP built by `plugin/build.gradle`; no compiled plugin classes |

## 3. Build and runtime versions

- Generated projects use Java 21, Fabric Loader 0.20.1 and Fabric API 0.141.6.
- The plugin itself is built with JDK 25.
- Fabric Loom 1.14 is configured with Mojang official mappings and the remap variant of the Loom
  plugin because Minecraft 1.21.11 is an obfuscated release.
- The access widener header uses the `named` namespace; an `official` header is rejected by Loom with
  `Namespace mismatch, expected named got official`.
- Data-pack format is `94.1`; resource-pack format is handled by MCreator's workspace generation.
- The Gradle wrapper points to a local distribution by default. `tools/set-gradle-distribution.ps1`
  switches between local and public URLs, and the public URL is retained as a comment.

## 4. Compatibility adjustments

### 4.1 Generator API

- Definitions declare `base_types` so MCreator tracks the shared initialisation templates in
  `common.*.yaml` (`Blocks`, `Items`, `BlockEntities`, `Entities`, and related classes).
- Type predicates use `w.hasElementsOfBaseType(...)`, `types.<name>?has_content` and explicit element
  filters. MCreator 2026.3 always exposes `types` keys, so null checks alone are not sufficient.
- `mod.java`, `mod_client.java` and the mixin configuration use the 2026.3 type-predicate forms.
- Definitions that reference fields introduced in MCreator 2026.3 (`forceRedstoneConductor`,
  `multipartModel`, `block_base_properties`, `fragments`) are consumed by the ported templates.

### 4.2 Minecraft API

| Area | Adjustment |
|---|---|
| Rendering | `GuiGraphics`-based `render`/`renderBackground`/`renderLabels`/`renderWidget`; `renderContents` for button subclasses; 3-argument container-screen constructor with `imageWidth`/`imageHeight` |
| Menus | `ClickType` for `AbstractContainerMenu#clicked` |
| Items | `Item.Properties#craftRemainder`; no override of the final `Item#getCraftingRemainder`; `component(...)` instead of `delayedComponent` |
| Blocks | `hasPostProcess` instead of `postProcess`; light hooks `getLightBlock` and `getLightColor`; `PlayerLookup.world` |
| Data components | `BlocksAttacks` and banner-pattern components constructed directly, with `Holder` values where required |
| Recipes and commands | `ItemInput#getItem`, `createItemStack(int, boolean)`, `Recipe#assemble(RecipeInput, HolderLookup.Provider)` |
| Saved data | `SavedDataType` identifiers are file-name safe (`<modid>_worldvars`, `<modid>_mapvars`) |
| World generation | `minecraft:uniform` int providers for patch spread; 1.21.11 has no trapezoid `IntProvider` |
| Render layers | Explicit `BlockRenderLayerMap` registration for transparent blocks, plants and fluids |

### 4.3 Fabric API

| Removed / renamed in 26.x | 0.141.6 form |
|---|---|
| `KeyMappingHelper` | `KeyBindingHelper.registerKeyBinding` |
| `ModelLayerRegistry` | `EntityModelLayerRegistry.registerModelLayer` |
| `ParticleProviderRegistry` | `ParticleFactoryRegistry` |
| `CreativeModeTabEvents` | `ItemGroupEvents.modifyEntriesEvent` |
| `PayloadTypeRegistry.serverboundPlay/clientboundPlay` | `playC2S` / `playS2C` |
| `FabricPotionBrewingBuilder` | `FabricBrewingRecipeRegistryBuilder` |
| `FluidRenderingRegistry` | `FluidRenderHandlerRegistry` with `SimpleFluidRenderHandler` |
| `FuelValueEvents` | `FuelRegistryEvents` |
| `ServerLevelEvents` | `ServerWorldEvents` |
| `ServerEntityLevelChangeEvents` | `ServerEntityWorldChangeEvents` (`AFTER_*_CHANGE_WORLD`) |
| `END_LEVEL_TICK` | `END_WORLD_TICK` |
| Attachment-based variables | `AttachmentRegistry` / `AttachmentType` (Fabric data-attachment API) |

### 4.4 Procedure and trigger coverage

The Fabric entry generator provides implementations for the procedure blocks and triggers used by
the supported element set, including block-inventory access, entity NBT, item-use events, dimension
travel, world load/unload and command parameters. NeoForge-only implementations are not imported.

### 4.5 Workspace base

`workspacebase/build.gradle` provides:

- Loom 1.14 with Mojang mappings and the remap namespace;
- Fabric Loader and Fabric API dependencies;
- an access-widener namespace migration guard;
- conditional Forge Config API Port and Night Config dependencies when a configuration element is
  generated;
- Java 21 release/toolchain settings;
- the `mcreator.gradle` include.

The Gradle wrapper uses a local distribution by default to keep repeated builds deterministic.

## 5. Validation

The repository includes:

- `tools/PluginValidator.java` and `tools/validate.ps1` — FreeMarker parsing, YAML parsing, include
  and template-reference resolution, forbidden-API checks and build invariants;
- `tools/check-archive.ps1` — archive structure, version and SHA-256 report;
- `build.gradle` checks for plugin metadata, versions, access-widener namespace, wrapper URL, license
  and guard presence.

See `05-TEST-REPORT.md` for the validation results.
