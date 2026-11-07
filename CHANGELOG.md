# Changelog

## 2026.3-1.0.10

### Fixed

- Mixin refmaps now use the generated mod id (`<modid>.refmap.json`) instead of the literal
  `modid.refmap.json`, so exported jars load correctly outside the development environment.
- Workspace archive name uses the generated mod id.
All notable changes to the Fabric 1.21.11 generator are recorded in this file.

## 2026.3-1.0.9

### Changed

- Documentation moved to `plugin/docs`.
- Changelog moved to `plugin/CHANGELOG.md`.
- Plugin metadata simplified: the description now identifies the generator as a Fabric 1.21.11
  generator, and credits list the upstream authors.
- Version raised to 1.0.9.

## 2026.3-1.0.8

### Added

- Fabric `BlockRenderLayerMap` registration for transparent blocks, plants and fluids.
- Block-entity initialisation guard based on `hasElementsOfBaseType`.

### Fixed

- Block entities with inventories were not initialised, causing a null block-entity type.
- Saved-data identifiers contained a colon and produced invalid file names.
- Armour item definitions used an incorrect `suffix` variable, leaving inventory models unresolved.
- Crop, cross and custom-model blocks used the default render layer.

## 2026.3-1.0.7

### Fixed

- Slider override visibility (`public renderWidget`).
- Player lookup API (`PlayerLookup.world`).
- Shield sound holders.
- Patch feature spread now uses the 1.21.11 uniform int provider.

## 2026.3-1.0.6

### Added

- Conditional Forge Config API Port and Night Config dependencies for configuration elements.
- `forgeconfigapiport` dependency in `fabric.mod.json` when configuration is used.

### Changed

- Migrated remaining Fabric API names to 0.141.6.
- `SavedDataType` identifiers are strings.
- Button render hooks use `renderContents` where required.
- Banner and shield components use direct `component(...)` values.
- Command-item and smelting helpers use the 1.21.11 APIs.
- Repair-recipe mixin targets `assemble(CraftingInput, HolderLookup.Provider)`.

## 2026.3-1.0.5

### Added

- `base_types` declarations for 14 element definitions.
- Fabric implementations for block-inventory and entity-NBT procedure blocks.
- `player_useitem_finish` trigger with a dedicated event and mixin.

### Changed

- Type predicates use the 2026.3 forms.
- Light hooks migrated to `getLightBlock` and `getLightColor`.
- Item and projectile renderers pass a `RenderType` to `submitModel`.

### Fixed

- Missing initialisation classes (`Blocks`, `Items`, `BlockEntities`, `Entities`, and related).
- Override errors on block and particle light methods.
- Fabric API names removed in 0.141.6.
- Empty procedure expressions caused by missing templates.

## 2026.3-1.0.4

### Fixed

- GUI rendering against the 1.21.11 `GuiGraphics` API.
- Container menus using `ClickType`.
- Item and tool crafting remainders.
- Block post-processing via `hasPostProcess`.

## 2026.3-1.0.3

### Fixed

- Workspace-base copy failure caused by FreeMarker parsing the access-widener guard.
- Access-widener namespace migration is now FreeMarker-safe.

## 2026.3-1.0.2

### Fixed

- Stale class-tweaker header when reusing an existing workspace base.
- Workspace-base migration now rewrites `official` headers to `named`.

## 2026.3-1.0.1

### Fixed

- Access-widener namespace mismatch (`classTweaker v1 named`).
- Data-pack format and loader/API version pins.

## 2026.3-1.0.0

### Added

- Initial Fabric 1.21.11 generator.
- Fabric 26.1.2 template base with 1.21.8 behaviour reference.
- Embedded datapack and NeoForge base layers.
- Workspace base with Loom 1.14, Fabric Loader 0.20.1 and Fabric API 0.141.6.
- Static validator, archive checker and documentation set.
