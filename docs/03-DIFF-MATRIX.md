# Difference Matrix

This document summarises the differences between the source generator lines and the delivered
Fabric 1.21.11 generator. It is intended for reviewers and maintainers.

## 1. Generator structure

| Aspect | 1.21.8 line | 26.1.2 line | Delivered 1.21.11 |
|---|---|---|---|
| Entry generator | `fabric-1.21.8` | `fabric-26.1.2` | `fabric-1.21.11` |
| Base layers | embedded | embedded | embedded `datapack` + `neoforge` |
| Java model key | `mojmap-1.21.x` | `mojmap-26.1.x` | `mojmap-1.21.x` |
| Loom | remap | unobfuscated | remap |
| Data-pack format | 61 | 94.1 | 94.1 |
| Access widener | `named` | not applicable | `named` |

## 2. Source-to-target API matrix

| Area | 26.x form | 1.21.11 form | Files |
|---|---|---|---|
| GUI rendering | `render`, `renderBackground`, `renderLabels`, `renderWidget`, 3-arg container constructor | Same API; `renderWidget` is final for buttons, so subclasses use `renderContents`; sliders use `public renderWidget` | `gui`, `screens`, `overlay` templates |
| Menus | `ClickType` | `ClickType` | `gui_container.java.ftl` |
| Item remainder | `Item.Properties#craftRemainder` | Same; `getCraftingRemainder` is final and is not overridden | `item`, `tool` templates |
| Item components | `delayedComponent` | `component(...)` | `item`, `tool` templates |
| Block post-processing | `postProcess` | `hasPostProcess` | `block`, `fluidblock`, `plant` |
| Light hooks | `getLightDampening`, `getLightCoords` | `getLightBlock`, `getLightColor` | block, fluid, particle, procedure helpers |
| Model submission | `submitModel(..., Identifier, ...)` | `submitModel(..., RenderType, ...)` | item and projectile renderers |
| Recipes | `assemble(RecipeInput)` | `assemble(RecipeInput, HolderLookup.Provider)` | smelting helper |
| Command item parameter | `ItemInput#item`, `createItemStack(int)` | `ItemInput#getItem`, `createItemStack(int, boolean)` | command helper |
| Saved data | `SavedDataType(Identifier, ...)` | `SavedDataType(String, ...)` | variables template |
| World generation | trapezoid `IntProvider` | uniform `IntProvider` | patch feature placement |
| Render layers | model-level render type | `BlockRenderLayerMap` | block, plant, fluid, client initialiser |

## 3. Fabric API matrix

| 26.x | Fabric API 0.141.6 |
|---|---|
| `KeyMappingHelper.registerKeyMapping` | `KeyBindingHelper.registerKeyBinding` |
| `ModelLayerRegistry.registerModelLayer` | `EntityModelLayerRegistry.registerModelLayer` |
| `ParticleProviderRegistry.getInstance()` | `ParticleFactoryRegistry.getInstance()` |
| `CreativeModeTabEvents.modifyOutputEvent` | `ItemGroupEvents.modifyEntriesEvent` |
| `PayloadTypeRegistry.serverboundPlay()` | `PayloadTypeRegistry.playC2S()` |
| `PayloadTypeRegistry.clientboundPlay()` | `PayloadTypeRegistry.playS2C()` |
| `FabricPotionBrewingBuilder.BUILD` | `FabricBrewingRecipeRegistryBuilder.BUILD` |
| `FluidRenderingRegistry.register` | `FluidRenderHandlerRegistry.INSTANCE.register` with `SimpleFluidRenderHandler` |
| `FuelValueEvents.BUILD` | `FuelRegistryEvents.BUILD` |
| `ServerLevelEvents` | `ServerWorldEvents` |
| `ServerEntityLevelChangeEvents.AFTER_*_CHANGE_LEVEL` | `ServerEntityWorldChangeEvents.AFTER_*_CHANGE_WORLD` |
| `ServerTickEvents.END_LEVEL_TICK` | `ServerTickEvents.END_WORLD_TICK` |
| `PlayerLookup.level` | `PlayerLookup.world` |

## 4. MCreator API differences

| Area | 2026.2 form | 2026.3 form | Handling |
|---|---|---|---|
| Element base types | Declared by imported base layers | Must be declared by the entry generator's definitions | Ported `base_types` into 14 definitions |
| Type map | Optional keys | Every type key is present | Use `types.<name>?has_content` and `hasElementsOfBaseType` |
| Block fields | — | `forceRedstoneConductor`, `multipartModel` | Consumed by block templates |
| Definition fragments | — | `fragments` | Used by armour/tool definitions |
| Block base properties | — | `block_base_properties` | Used by block templates |
| Configuration element | Separate plugin | Separate plugin, Fabric API Port | Conditional dependency at workspace level |

## 5. Data formats

| Asset | Format | Notes |
|---|---|---|
| `pack.mcmeta` | 94.1 | Data pack |
| Advancements | 1.21.11 schema | Ported from 26.1.2 |
| Recipes | 1.21.11 schema | Item inputs use `ItemInput` helpers |
| Loot tables | 1.21.11 schema | No changes required |
| World generation | 1.21.11 registry paths (`configured_feature`, `placed_feature`) | Uniform spread providers |
| Item model definitions | `assets/<namespace>/items/<item>.json` | 1.21.11 item-model system |
| Equipment assets | `assets/<namespace>/equipment/<name>.json` | 1.21.11 equipment layers |

## 6. Summary

The delivered generator keeps the 26.1.2 structure, templates and feature set, replaces 26.x-only
Minecraft and Fabric API constructs with their 1.21.11 equivalents, and adopts the 2026.3 definition
conventions required by the target plugin API.
