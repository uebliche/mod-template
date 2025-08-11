<!-- modrinth_exclude.start -->
# Mod-template

<!-- build_test.start -->
![Test 1.21.8](https://img.shields.io/badge/1.21.8-success-brightgreen?style=flat) ![Test 1.21.7](https://img.shields.io/badge/1.21.7-success-brightgreen?style=flat) ![Test 1.21.6](https://img.shields.io/badge/1.21.6-success-brightgreen?style=flat) ![Test 1.21.5](https://img.shields.io/badge/1.21.5-success-brightgreen?style=flat) ![Test 1.21.4](https://img.shields.io/badge/1.21.4-success-brightgreen?style=flat) ![Test 1.21.3](https://img.shields.io/badge/1.21.3-success-brightgreen?style=flat) ![Test 1.21.2](https://img.shields.io/badge/1.21.2-success-brightgreen?style=flat) ![Test 1.21.1](https://img.shields.io/badge/1.21.1-success-brightgreen?style=flat) ![Test 1.21](https://img.shields.io/badge/1.21-success-brightgreen?style=flat) ![Test 1.20.6](https://img.shields.io/badge/1.20.6-success-brightgreen?style=flat) ![Test 1.20.5](https://img.shields.io/badge/1.20.5-success-brightgreen?style=flat) ![Test 1.20.4](https://img.shields.io/badge/1.20.4-success-brightgreen?style=flat) ![Test 1.20.3](https://img.shields.io/badge/1.20.3-success-brightgreen?style=flat) ![Test 1.20.2](https://img.shields.io/badge/1.20.2-success-brightgreen?style=flat) ![Test 1.20.1](https://img.shields.io/badge/1.20.1-success-brightgreen?style=flat) ![Test 1.20](https://img.shields.io/badge/1.20-success-brightgreen?style=flat) ![Test 1.19.4](https://img.shields.io/badge/1.19.4-success-brightgreen?style=flat) ![Test 1.19.3](https://img.shields.io/badge/1.19.3-success-brightgreen?style=flat) ![Test 1.19.2](https://img.shields.io/badge/1.19.2-success-brightgreen?style=flat) ![Test 1.19.1](https://img.shields.io/badge/1.19.1-success-brightgreen?style=flat) ![Test 1.19](https://img.shields.io/badge/1.19-success-brightgreen?style=flat) ![Test 1.18.2](https://img.shields.io/badge/1.18.2-success-brightgreen?style=flat) ![Test 1.18](https://img.shields.io/badge/1.18-success-brightgreen?style=flat) 
<!-- build_test.end -->
<!-- modrinth_exclude.end -->
## Project Description

This repository provides a minimal template for creating Fabric mods.
It sets up Manifold, Loom and common project scaffolding so you can focus on writing game logic instead of build tooling.

## Prerequisites

* Java Development Kit (JDK) 21 or higher
* Git

Gradle is provided via the wrapper script included in this repository.

## Build & Run

Clone the repository and invoke the build:

```bash
./gradlew build
```

The resulting mod jar will be placed in `build/libs`.

## Customisation

Adjust the mod id, name and other metadata in `gradle.properties`.
Resource files such as textures, lang files and data packs live under `src/main/resources`.
Rename the `assets/mod-template` folder to match your mod id when customising.

## License

This project is licensed under the Non‑Commercial MIT license.
See [LICENSE.md](LICENSE.md) for the full license text.

## Contributing

Issues and pull requests are welcome.
Please discuss major changes in an issue first to ensure they align with the project's goals.

## Examples

Replace this section with screenshots or usage examples if available.
