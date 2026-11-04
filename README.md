# Fabric 1.21.11 Generator

A Fabric generator for Minecraft 1.21.11. The project produces an installable MCreator generator
archive with Fabric Loader 0.20.1 and Fabric API 0.141.6 support.

## Requirements

- JDK 25 for building the plugin (generated projects target Java 21)
- Gradle 9.8.0, or the bundled wrapper
- MCreator with the plugin API range declared in `plugin.json`

## Build

```powershell
.\gradlew.bat build packagePlugin --offline --no-daemon --console=plain
```

Output: `build/dist/generator-fabric-1.21.11.zip`.

## Install

1. Close MCreator.
2. Copy the archive to the MCreator `plugins` directory.
3. Start MCreator and select the Fabric 1.21.11 generator for a new workspace.
4. Run **Generate code** once to copy the workspace base.

## Validation

```powershell
pwsh -NoProfile -File .\tools\validate.ps1
pwsh -NoProfile -File .\tools\check-archive.ps1
```

`validate.ps1` checks FreeMarker/YAML syntax, include resolution, template references and forbidden
API usage. `check-archive.ps1` reports the archive structure and SHA-256 digest.

## Layout

```
src/main/resources/
  plugin.json                 plugin metadata
  fabric-1.21.11/             entry generator
  fabric-1.21.11-base/        embedded datapack and NeoForge layers
  LICENSE                     CC BY-NC 4.0
  NOTICE.md                   attribution
docs/                         documentation
CHANGELOG.md                  release history
```

## Documentation

- `docs/01-BASELINE-INVENTORY.md` — technical baseline
- `docs/02-ADAPTATION.md` — adaptation notes
- `docs/03-DIFF-MATRIX.md` — difference matrix
- `docs/04-FEATURE-MAPPING.md` — feature coverage
- `docs/05-TEST-REPORT.md` — validation report
- `docs/06-KNOWN-LIMITATIONS.md` — limitations and roadmap
- `docs/07-RELEASE-VERIFICATION.md` — release verification checklist

## License

CC BY-NC 4.0. See `LICENSE` and `NOTICE.md` for attribution.
