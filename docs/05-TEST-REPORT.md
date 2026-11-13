# Validation Report

## 1. Scope

Validation covers the generator resources, template rendering, template references, archive
structure and generated-project acceptance builds for Minecraft 1.21.11 with Fabric Loader 0.20.1 and
Fabric API 0.141.6.

## 2. Environment

| Item | Value |
|---|---|
| Operating system | Windows 11 |
| Plugin build JDK | 25 |
| Generated-mod JDK | 21 |
| Gradle | 9.8.0 |
| Fabric Loom | 1.14 (remap) |
| Minecraft | 1.21.11 |
| Mappings | Mojang official, named namespace |
| Plugin archive | `build/dist/generator-fabric-1.21.11.zip` |

## 3. Static validation

The `PluginValidator` tool parses every generator resource and checks:

- FreeMarker syntax for all templates;
- YAML syntax for all definition and mapping documents;
- `#include` and `@addTemplate` resolution;
- definition-to-template references;
- forbidden 26.x-only API usage;
- plugin metadata, build invariants, access-widener namespace, wrapper configuration and license.

Result:

```
templates parsed : 1677
yaml documents   : 171
includes checked : 836
template refs    : 645
resources        : 1887
RESULT: OK
```

The archive checker reports 2000 entries, a valid structure and the SHA-256 digest of the packaged
plugin.

## 4. API verification

API signatures were verified against the mapped Minecraft 1.21.11 jar and the Fabric API 0.141.6
modules with `javap`. The verification covered, among others:

- `BlockBehaviour` light and interaction hooks;
- `AbstractWidget`/`AbstractButton`/`AbstractSliderButton` render methods;
- `Item.Properties#component`, `BlocksAttacks`, `DataComponents`;
- `SavedDataType`, `ItemInput`, `Recipe#assemble`;
- `PayloadTypeRegistry`, `KeyBindingHelper`, `EntityModelLayerRegistry`, `ParticleFactoryRegistry`,
  `ItemGroupEvents`, `FuelRegistryEvents`, `ServerWorldEvents`,
  `ServerEntityWorldChangeEvents`, `PlayerLookup`, `FluidRenderHandlerRegistry`.

## 5. Acceptance builds

Four representative workspaces were generated and built with Gradle:

| Workspace | Build | Runtime |
|---|---|---|
| Better Melon | Passed | Client starts; world creation and item/block rendering verified |
| Croparium Full | Passed | Client starts; block placement and configuration loading verified |
| Croparium Lite | Passed | Client starts; crops, cross models and screens verified |
| Everrose | Passed | Client starts; armour, items and custom models verified |

The acceptance builds exercise blocks, items, tools, armour, crops, custom models, GUIs, menus,
variables, configurations, fluids, world generation, procedures and triggers.

## 6. Runtime checks

- World creation and chunk generation complete without registry errors.
- Player variables and world/map variables persist correctly.
- Block entities are registered before placement and do not raise null-type exceptions.
- Transparent blocks, plants and fluids use the correct render layer.
- Armour equipment layers and inventory models render correctly.
- Custom item and block models resolve their textures.

## 7. Distribution

| Item | Value |
|---|---|
| Archive | `build/dist/generator-fabric-1.21.11.zip` |
| Size | 1,238,241 bytes |
| Entries | 2000 |
| SHA-256 | `C76908BCF2189732A7D0A6A2A87AD64F7AFEF9206710FC4667233E57A0725C76` |
| License | CC BY-NC 4.0 |

All wrapper files in the plugin and generated workspace template use the official public Gradle
distribution URL. The packaged archive contains no local drive path, `file:///` URL or
`Reference resources` reference in its text resources.

## 8. Validation commands

```powershell
.\plugin\gradlew.bat -p plugin build packagePlugin --offline --no-daemon --console=plain
pwsh -NoProfile -File .\plugin\tools\validate.ps1
pwsh -NoProfile -File .\plugin\tools\check-archive.ps1
```

## 9. Known constraints

Known limitations and roadmap items are listed in `06-KNOWN-LIMITATIONS.md`. They do not affect the
acceptance-build results above.
