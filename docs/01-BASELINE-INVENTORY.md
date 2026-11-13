# Technical Baseline

## 1. Purpose

This document records the source baseline, target platform and repository layout used to build the
Fabric 1.21.11 generator. It is a reference for maintainers who need to reproduce the build or
evaluate future upgrades.

## 2. Target platform

| Item | Value |
|---|---|
| Minecraft | 1.21.11 |
| Java runtime (generated mods) | Java 21 |
| Java runtime (plugin build) | JDK 25 |
| Fabric Loader | 0.20.1 |
| Fabric API | 0.141.6 |
| Fabric Loom | 1.14 (remap variant) |
| Gradle | 9.8.0 |
| Mappings | Mojang official mappings, named development namespace |
| MCreator plugin API | `supportedversions: [202600344621, 202600399999]` |

## 3. Source trees

| Source | Files | Role |
|---|---:|---|
| Fabric-Generator-MCreator 1.21.8 (2026.1 line) | 725 | Behavioural baseline and 1.21.x API reference |
| Fabric-Generator-MCreator 26.1.2 (2026.2 line) | 729 | Primary template donor |
| Fabric-Generator-MCreator 26.3 (2026.3 line) | 734 | Feature and definition reference |
| NeoForge 26.1.2 generator | — | Embedded base layer (`neoforge`) |
| Datapack 26.1.2 generator | — | Embedded base layer (`datapack`) |

The 26.1.2 tree is used as the main donor because it is the first complete Fabric tree after
Minecraft 1.21.11 and already contains the data-pack format, component and rendering APIs required by
that release. The 1.21.8 tree supplies proven 1.21.x implementations where a 26.x construct does not
exist in 1.21.11.

## 4. Repository layout

```
plugin/
  build.gradle                 resource build, checks and packaging
  gradle.properties            version and toolchain properties
  src/main/resources/
    plugin.json                plugin identity and compatibility range
    LICENSE                    CC BY-NC 4.0
    NOTICE.md                  attribution
    fabric-1.21.11/            entry generator
      generator.yaml           imports, base templates, Java model key
      *.definition.yaml        element definitions
      common.*.yaml            shared element initialisers
      templates/               Java, JSON and resource templates
      procedures/              procedure templates and helpers
      triggers/                trigger templates
      workspacebase/           project skeleton copied into each workspace
    fabric-1.21.11-base/
      datapack/                data-pack templates, mappings, formats
      neoforge/                base Java templates, AI tasks, config support
  tools/                       static validator and archive checker
  docs/                        documentation set
  CHANGELOG.md
```

## 5. Generator architecture

The plugin is a resource-only MCreator generator:

1. `plugin.json` registers the generator at weight 10 for the supported MCreator API range.
2. `generator.yaml` imports the embedded `datapack` and `neoforge` layers, excluding their procedure
   and trigger directories so the Fabric implementations take precedence.
3. Element definitions map MCreator model fields to Java/JSON templates.
4. `common.*.yaml` files generate shared initialisation classes (`Blocks`, `Items`, `BlockEntities`,
   `Entities`, …) for elements that exist only as base types.
5. `workspacebase/` provides `build.gradle`, the Gradle wrapper, access widener migration and the
   `mcreator.gradle` hook used by MCreator.
6. `subversion` in `generator.yaml` invalidates cached workspace bases when the base changes.

## 6. Version invariants

- Generated mods target Java 21 and Fabric Loader 0.20.1 or newer.
- The access widener uses the `named` namespace because Minecraft 1.21.11 is still an obfuscated
  release; Loom runs the development environment in the named namespace.
- Data-pack format is `94.1` (minimum and maximum).
- The Gradle wrapper uses the official Gradle distribution URL. A local distribution can be selected
  for offline development by passing an explicit archive to `tools/set-gradle-distribution.ps1`;
  generated workspace templates always keep the public URL.

## 7. Related documents

- `02-ADAPTATION.md` — adaptation decisions and compatibility adjustments
- `03-DIFF-MATRIX.md` — source-to-target difference matrix
- `04-FEATURE-MAPPING.md` — feature coverage
- `05-TEST-REPORT.md` — validation report
- `06-KNOWN-LIMITATIONS.md` — known limitations and roadmap
- `07-RELEASE-VERIFICATION.md` — release verification checklist
