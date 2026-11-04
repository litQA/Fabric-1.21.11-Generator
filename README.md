<img width="1000" height="200" alt="fabric generator banner 1 21 11" src="https://github.com/user-attachments/assets/64b8a675-95d7-4568-9708-b1874f7f938a" />

# Fabric 1.21.11 generator

Self-contained Gradle project that builds `generator-fabric-1.21.11.zip`, an MCreator generator
plugin for **Minecraft 1.21.11** on **MCreator 2026.3.44621** (`202600344621`).

Only this folder is needed to build. No parent files, no MCreator checkout, no network access.

## Layout

```
plugin/
  build.gradle                 resource build + checkPluginResources + packagePlugin
  settings.gradle              optional :MCreator include when mcreator_path is set
  gradle.properties            version pins (Minecraft, MCreator, Loader, API, Gradle)
  gradlew / gradle/wrapper     Gradle 9.8.0 wrapper
  src/main/resources/
    plugin.json                plugin id / weight / supportedversions
    LICENSE
    fabric-1.21.11/            entry generator (the only generator.yaml)
    fabric-1.21.11-base/
      datapack/                embedded datapack layer (no generator.yaml)
      neoforge/                embedded shared layer (no generator.yaml)
  tools/
    validate.ps1               3-stage offline validation
    PluginValidator.java       FreeMarker / SnakeYAML / build invariant checker
    check-archive.ps1          archive structure verification
```

## Build

```powershell
$env:GRADLE_USER_HOME = "<workspace>\caches\gradle"

# wrapper: resolves the local file:/// Gradle distribution configured in gradle-wrapper.properties
.\plugin\gradlew.bat -p plugin build packagePlugin --offline --no-daemon

# or the extracted distribution
.\caches\gradle-dist\gradle-9.8.0\bin\gradle.bat -p plugin build packagePlugin --offline --no-daemon
```

Output: `plugin/build/dist/generator-fabric-1.21.11.zip` (written to `dist`, not `libs`, so IDE
archive previews cannot lock the artifact).

A plain `gradle build` also works when a Gradle 9.8+ distribution is on `PATH`. The build is
resource-only; the declared Java 25 toolchain is used for the validation tooling. Generated mods
target Java 21.

## Offline Gradle distribution

Both wrappers (plugin and generated workspace) ship with:

```
distributionUrl=file\:///…/Reference resources/gradle-9.8.0-bin.zip
# distributionUrl=https\://services.gradle.org/distributions/gradle-9.8.0-bin.zip
```

Switch both directions with:

```powershell
pwsh -NoProfile -File .\plugin\tools\set-gradle-distribution.ps1 -Mode Local    # offline tests
pwsh -NoProfile -File .\plugin\tools\set-gradle-distribution.ps1 -Mode Public   # before shipping
```

Use `-TargetScope Plugin|Workspace|All` (default `All`) to limit the change.


## Validate

```powershell
pwsh -NoProfile -File .\plugin\tools\validate.ps1        # Gradle checks + javac + FreeMarker/YAML
pwsh -NoProfile -File .\plugin\tools\check-archive.ps1   # archive layout + SHA-256
```

`validate.ps1` compiles `PluginValidator.java` against `freemarker-2.3.35.jar` and
`snakeyaml-engine-3.2.jar` from the MCreator installation (`-McRoot` to override, `-SkipGradle`
to run only the Java stage).

## Workspace migration guard

Workspaces created by 1.0.0-beta contain a class tweaker whose header declares the `official`
namespace. Loom rejects that for obfuscated 1.21.11 (`Namespace mismatch, expected named got
official`). Since 1.0.3-beta the workspace build script rewrites a stale header to `named` during
project configuration, before Loom reads it.

Important: MCreator preprocesses `workspacebase/` files with **FreeMarker**, so build.gradle must
not contain stray `${...}` outside the expressions MCreator provides (`${modid}`, `${generator.*}`).
A GString in the guard aborted `setupWorkspaceBase` in 1.0.2. `PluginValidator` now renders the
template to catch this.

The guard is part of the generated workspace base and is injected when MCreator copies the base
(triggered by the `subversion` bump or *Generate code*). Afterwards plain Gradle sync/builds are
enough.
## Version pins

| Pin | Value | Where |
|---|---|---|
| Minecraft | 1.21.11 | `gradle.properties`, `generator.yaml` folder name, workspace dependency |
| Fabric Loader | 0.20.1 | `gradle.properties`, `fabric.mod.json.ftl`, workspace build |
| Fabric API | 0.141.6 | `gradle.properties`, `generator.yaml` `buildfileversion` |
| Java | 21 (mod bytecode) / 25 (build toolchain) | workspace build, `fabric.mod.json.ftl`, `mixin.json.ftl` |
| Data pack format | 94.1 | `datapack/templates/pack.mcmeta.ftl` |

Changing a pin requires updating the matching file; `checkPluginResources` and
`PluginValidator` fail the build when the values diverge.

## DSH Empowers Accelerated Plugin Development

<img width="1000" alt="dsh" src="https://github.com/user-attachments/assets/1b0b22c9-5213-48eb-9e51-6de70e852dec" />

This project includes code generated with **DSH (AI)** assistance.

## Licence

The packaged `LICENSE` is **CC BY-NC 4.0** (project decision). `NOTICE.md` records the GPL-3.0
upstream attribution for Fabric-Generator-MCreator and the MCreator generator resources; keep it
with every redistribution.


# MCreator - Minecraft Mod Maker

[![MCreator](https://mcreator.net/image/brand/mcreator300s.png)](https://mcreator.net/)

MCreator is an open-source software used to make Minecraft Java Edition mods, Minecraft Bedrock Edition Add-Ons, resource packs, and data packs using an intuitive easy-to-learn interface or with an integrated code editor. It is used worldwide by Minecraft players, aspiring mod developers, for education, online classes, and STEM workshops. 

NOT AN OFFICIAL MINECRAFT PRODUCT. NOT APPROVED BY OR ASSOCIATED WITH MOJANG OR MICROSOFT.
