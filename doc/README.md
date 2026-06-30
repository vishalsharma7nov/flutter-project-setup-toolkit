# Documentation

Complete guides for **Flutter Project Setup Toolkit** (`flutter_project_setup_toolkit`).

## Getting started

| Guide | Description |
|-------|-------------|
| [Setup wizard](setup-wizard.md) | First-time project configuration (CLI and Setup Studio) |
| [Configuration](configuration.md) | `release-toolkit.config.json` reference |
| [Toolkit Studio](toolkit-studio.md) | Hub UI: Setup, Build, Quick Test, Feature, Version, Package, CI, QA, Docs, Doctor |
| [Studio desktop app](studio-desktop.md) | macOS native shell for Toolkit Studio |

## Architecture & scaffolding

| Guide | Description |
|-------|-------------|
| [Architecture presets](architecture.md) | 15 layout presets, core modules, routing, micro-feature monorepo, custom templates |
| [Feature scaffolding](feature-scaffolding.md) | `make_feature` CLI and Feature Studio |
| [Package Studio](package-studio.md) | Search pub.dev and install dependencies |
| [Project Docs Studio](project-docs.md) | Generate README and doc/ guides for your app |
| [API layer configuration](api-layer.md) | REST, gRPC, GraphQL, external SDK, and related options |
| [Architecture audit](architecture-audit.md) | Detect preset drift, cross-feature import violations |

## Release workflows

| Guide | Description |
|-------|-------------|
| [Version classification](versioning.md) | Semver bump from git commits |
| [QA release notes](qa-release-notes.md) | HEAD~1 vs HEAD handoff for QA teams |
| [CI Studio](ci-studio.md) | Generate, test, and publish GitHub Actions workflows |
| [Build scripts](building.md) | Android APK/AAB, iOS IPA, Git remote, Quick Test |
| [Multiple apps](multi-app-setup.md) | Share one toolkit across projects |

## Publishing

| Guide | Description |
|-------|-------------|
| [Publishing to pub.dev](publishing.md) | Package release checklist |

## Reference

| Resource | Description |
|----------|-------------|
| [`release-toolkit.config.example.json`](../release-toolkit.config.example.json) | Full config example |
| [`templates/architecture/custom_feature.example.json`](../templates/architecture/custom_feature.example.json) | Custom architecture template example |
| [Troubleshooting](troubleshooting.md) | Common errors and fixes |

Shell wrappers in `scripts/` (toolkit repo) and in your app’s `scripts/` (after setup) include **usage comments at the top of each file** — open any `.sh` or run `dart run :<command> --help`.

## CLI executables

All commands are **Dart-only**.

| Executable | Purpose |
|------------|---------|
| `toolkit_studio` | Open Toolkit Studio hub (all studios) |
| `setup_studio` | Setup Studio only (legacy entry; hub preferred) |
| `setup_project` | Interactive terminal setup wizard |
| `make_feature` | Scaffold a feature module |
| `classify_version_bump` | Classify semver bump from git |
| `qa_release_notes` | Export QA handoff JSON/Markdown for CI |
| `codebase_understand` | Heuristic codebase scan (modules, routes, deps) |
| `project_docs` | Generate README and doc/ guides for a Flutter app |
| `ci_studio` | Generate, test, and publish GitHub Actions workflows |
| `build_android` | Release APK or AAB |
| `build_ios_ipa` | Release IPA (macOS) |
| `build_distribution` | Distribution Studio GUI |
| `architecture_audit` | Architecture compliance report |

Run from a cloned toolkit repo:

```bash
dart run :toolkit_studio
dart run :setup_project --project /path/to/app
dart run :architecture_audit --project /path/to/app
```

Or after `dart pub global activate flutter_project_setup_toolkit`:

```bash
toolkit_studio
setup_project --project /path/to/app
```
