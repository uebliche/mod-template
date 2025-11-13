<!-- modrinth_exclude.start -->
# Mod-template (multi-loader)

<!-- build_test.start -->
![Test 1.21.10](https://img.shields.io/badge/1.21.10-success-brightgreen?style=flat) ![Test 1.21.1](https://img.shields.io/badge/1.21.1-success-brightgreen?style=flat) ![Test 1.20.4](https://img.shields.io/badge/1.20.4-success-brightgreen?style=flat) ![Test 1.19.4](https://img.shields.io/badge/1.19.4-success-brightgreen?style=flat) 
<!-- build_test.end -->
<!-- modrinth_exclude.end -->
## Project Description

This repository now demonstrates a multi-loader layout:

```
mod-template/
├── common/           # shared Java-only logic (no loader APIs)
├── loader-fabric/    # Fabric/Loom project, applies build.main.gradle
└── loader-forge/     # NeoForge project powered by ModDevGradle
```

Use `common` for gameplay/state code, and keep loader shims thin.

## Prerequisites

* Java Development Kit (JDK) 21 or higher
* Git

Gradle is provided via the wrapper script included in this repository.

## Build & Run

Clone the repository and invoke the build for a specific loader/version:

```bash
# Fabric 1.21.1
./gradlew :loader-fabric:build -PmcVersion=1.21.1

# NeoForge 1.21.10
./gradlew :loader-forge:runClient -PmcVersion=1.21.10
```

Use `mods/mod-template/build_all.sh` (or `build_all.ps1` on Windows) to iterate over every combination defined in
`versions.matrix.json`. The scripts run Gradle on Java 21 (loom + NeoForge requirement), while the build logic itself targets the appropriate bytecode level per Minecraft version.

### NeoForge specifics

- Supported NeoForge/Minecraft targets live in `versions.matrix.json`. Each entry only needs the `mc` version; the build resolves both the matching NeoForge artifact and a compatible loader range automatically. Add optional fields (`neoForge`, `loaderVersionRange`, `properties`) only if you need to override the defaults.
- Fabric targets default to the stable Minecraft releases at or above `buildFromVersion` (from `gradle.properties`). Add entries under the `fabric` key in `versions.matrix.json` only when you need to pin/skip specific releases; otherwise the automation derives the list for you.
- When adding another Minecraft/NeoForge pair, drop a new JSON object into the `forge` list. Optional `properties` can pass extra `-P` flags to Gradle builds (used by the CI matrix and the `build_all.*` scripts).
- Local dev uses ModDevGradle’s `forgeclientdev` target: `./gradlew :loader-forge:runClient -PmcVersion=<version>` boots with the shared `common` code already on the classpath.

## Updating build.main.gradle

The file `build.main.gradle` is vendored from the upstream [uebliche/mod-template](https://github.com/uebliche/mod-template) repository.
To update it to the latest version, run:

```bash
curl -L https://raw.githubusercontent.com/uebliche/mod-template/main/build.main.gradle -o build.main.gradle
```

Commit the refreshed file to keep the template in sync with upstream.

## Customisation

Adjust shared metadata in `gradle.properties`. Loader-specific files live under
their respective subprojects (e.g. `loader-fabric/src/main/resources/fabric.mod.json`).

## License

This project is licensed under the Non‑Commercial MIT license.
See [LICENSE.md](LICENSE.md) for the full license text.

## Contributing

Issues and pull requests are welcome.
Please discuss major changes in an issue first to ensure they align with the project's goals.

## Examples

Replace this section with screenshots or usage examples if available.
