# Release Verification Checklist

This checklist is used to verify a packaged generator on a clean MCreator installation before
release. Complete every section and record the result.

## 1. Installation

- [ ] Close MCreator.
- [ ] Copy `build/dist/generator-fabric-1.21.11.zip` to the MCreator `plugins` directory.
- [ ] Start MCreator and confirm the generator appears under **Generator: Fabric 1.21.11**.
- [ ] Create a new workspace with the generator; confirm the workspace opens without errors.
- [ ] Confirm **Generate code** completes and the project base is copied.

## 2. Generated project

- [ ] `gradle build` completes without compilation errors.
- [ ] `runClient` starts and reaches the main menu.
- [ ] Create a new world; confirm chunk generation and registry loading complete.
- [ ] Enter the world; confirm no crash report is produced.

## 3. Functional checks

| Area | Check |
|---|---|
| Blocks | Place, break and rotate representative blocks; confirm models, textures and transparency |
| Plants | Place crops and cross models; confirm cutout rendering and growth |
| Items | Confirm inventory icons and held models for standard, custom-model and armour items |
| Armour | Equip a full set; confirm worn and inventory rendering |
| GUI | Open a generated screen; confirm widgets, sliders, labels and tooltips |
| Menus | Move items in a generated container; confirm slot handling |
| Variables | Change player/world/map variables, reload the world and confirm persistence |
| Configuration | Edit a configuration value and confirm it is applied |
| Fluids | Place and bucket a generated fluid; confirm rendering and tint |
| World generation | Locate generated features, ores and structures in a new world |
| Procedures | Trigger representative procedures and confirm expected behaviour |
| Networking | Use a key binding or command that sends a payload |

## 4. Distribution checks

- [ ] Archive contains `plugin.json`, `LICENSE`, `NOTICE.md` and the generator directories.
- [ ] `plugin.json` version matches the release version.
- [ ] Archive SHA-256 matches the release record.
- [ ] License and attribution files are present.

## 5. Sign-off

| Item | Value |
|---|---|
| Release version | |
| Archive SHA-256 | |
| MCreator version | |
| Windows version | |
| Java version | |
| Tester | |
| Date | |
| Result | Pass / Fail |

Record any failed check with the console log, the affected element and the generated file path.
