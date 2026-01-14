<!-- modrinth_exclude.start -->
# Mod-template (multi-loader)

<!-- build_test.start -->
![Test 1.21.11](https://img.shields.io/badge/1.21.11-failure-red?style=flat) ![Test 1.21.10](https://img.shields.io/badge/1.21.10-failure-red?style=flat) ![Test 1.21.1](https://img.shields.io/badge/1.21.1-failure-red?style=flat) ![Test 1.20.4](https://img.shields.io/badge/1.20.4-failure-red?style=flat) ![Test 1.19.4](https://img.shields.io/badge/1.19.4-failure-red?style=flat) 
<!-- build_test.end -->
<!-- modrinth_exclude.end -->
## Project Description

This repository now demonstrates a multi-loader layout:

```
mod-template/
├── common/           # shared Java-only logic (no loader APIs)
├── loader-fabric/    # Fabric/Loom project, applies build.main.gradle
├── loader-forge/     # NeoForge project powered by ModDevGradle
├── loader-paper/     # Paper plugin (Paperweight userdev)
└── loader-velocity/  # Velocity proxy plugin
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

# Paper 1.21.1
./gradlew :loader-paper:reobfJar -PmcVersion=1.21.1

# Velocity (API 3.3.0-SNAPSHOT)
./gradlew :loader-velocity:build -PmcVersion=3.3.0-SNAPSHOT
```

Use `build_all.sh` (or `build_all.ps1` on Windows) to iterate over every loader and Minecraft
version derived from mcmeta. The list starts at `buildFromVersion` in `gradle.properties` and
includes all newer stable releases. The scripts run Gradle on Java 21 (loom + NeoForge requirement),
while the build logic itself targets the appropriate bytecode level per Minecraft version.

## mcmeta integration

This template expects the mcmeta Gradle plugin to be available so it can resolve Minecraft + loader versions (including Loom). Point `mcmetaPluginPath` (Gradle property) or `MCMETA_PLUGIN_PATH` (env var) to the mcmeta Gradle plugin directory. Example:

```bash
./gradlew :loader-fabric:build -PmcmetaPluginPath=../../tools/mcmeta-gradle/gradle-plugin
```

When `minecraft_version` is not set, mcmeta uses the latest stable release. The build expects mcmeta data to be available, so keep the plugin path configured.

### NeoForge specifics

- NeoForge builds resolve loader + API versions from mcmeta and Maven metadata based on `-PmcVersion`.
- The build list is driven by `buildFromVersion` in `gradle.properties` (all newer stable releases).
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
their respective subprojects (e.g. `loader-fabric/src/main/resources/fabric.mod.json`). Use `paper_main_class` / `velocity_main_class` in `gradle.properties` if you want custom plugin entry classes for the server/proxy loaders.

## License

This project is licensed under the Non‑Commercial MIT license.
See [LICENSE.md](LICENSE.md) for the full license text.

## Contributing

Issues and pull requests are welcome.
Please discuss major changes in an issue first to ensure they align with the project's goals.

## Examples

Replace this section with screenshots or usage examples if available.
