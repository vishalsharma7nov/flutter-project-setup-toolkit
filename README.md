# Flutter Project Setup Toolkit

**Dart package and CLI** for Flutter project setup, architecture scaffolding, release builds, and version workflows.

Structure your project **once** — env files, version keys, architecture preset, wrapper scripts — then classify semver from git, bump version keys, and ship APK/AAB/IPA with the right environment loaded automatically.

```bash
git clone https://github.com/vishalsharma7nov/flutter-project-setup-toolkit.git
cd flutter-project-setup-toolkit
dart pub get
dart run :toolkit_studio
```

On macOS, `./scripts/toolkit-studio.sh` opens the **desktop app** by default. Use `--browser` for the web UI.

**Full documentation:** [doc/README.md](doc/README.md)

---

## What you get

| Capability | CLI / UI |
|------------|----------|
| **Toolkit hub** | `toolkit_studio` — project picker, create/repair, studio navigation |
| **Project setup** | `setup_project`, Setup Studio (`/setup`) |
| **Architecture scaffolding** | 15 presets, core modules, flavor mains, test mirrors, custom templates |
| **Feature modules** | `make_feature`, Feature Studio (`/feature`) |
| **Version bumps** | `classify_version_bump`, Version Studio (`/version`) |
| **QA release notes** | QA Release Notes Studio (`/qa`) — commit compare & handoff exports |
| **Android builds** | `build_android` — APK & AAB |
| **iOS builds** | `build_ios_ipa` — IPA (macOS) |
| **Distribution GUI** | `build_distribution`, Distribution Studio (`/build`) — Git remote, secure env overlay |
| **Quick Test** | Quick Test Studio (`/quick-test`) — Git URL → build → device install |
| **Package install** | Package Studio (`/packages`) — search pub.dev or paste link, install dependencies |
| **CI Studio** | CI Studio (`/ci`) — generate, test, and publish GitHub Actions workflows |
| **Project Docs** | Docs Studio (`/docs`) — generate README and doc/ guides for your app |
| **Project doctor** | Doctor Studio (`/doctor`) — config, env, signing, architecture health |
| **Mobile Quick Test** | `studio_app` on Android/iOS — pair with Mac (`--host lan`), paste repo, install on device |
| **Architecture audit** | `architecture_audit` — drift & import violations |
| **macOS desktop app** | `./scripts/toolkit-studio.sh` — native shell for all studios |

---

## Quick start

### 1. Open Toolkit Studio

```bash
dart run :toolkit_studio
# or: ./scripts/toolkit-studio.sh
```

Pick or create a Flutter project, then use **Setup flutter project** to generate:

- `release-toolkit.config.json`
- Env file templates (`.env/` or `.secrets/`)
- `scripts/` wrappers (`build-android.sh`, `make-feature.sh`, …)
- Optional architecture bootstrap (`lib/core/`, router, flavor mains)

### 2. Terminal setup (alternative)

```bash
dart run :setup_project --project /path/to/your_flutter_app
```

### 3. Scaffold a feature

```bash
dart run :make_feature --project /path/to/app --feature authentication
```

### 4. Release workflow

```bash
# Classify bump from latest commit
dart run :classify_version_bump --project /path/to/app --verbose

# Preview version key updates
dart run :classify_version_bump --project /path/to/app --env prod --apply-env --dry-run

# Build Android AAB
dart run :build_android --project /path/to/app --env prod --aab

# Build iOS IPA (macOS)
dart run :build_ios_ipa --project /path/to/app --env prod
```

---

## Install

### pub.dev (consumers)

```bash
dart pub global activate flutter_project_setup_toolkit
toolkit_studio
setup_project --project /path/to/app
```

Ensure `$HOME/.pub-cache/bin` is on your `PATH`.

### Path dependency in a Flutter app

```yaml
dev_dependencies:
  flutter_project_setup_toolkit:
    path: ../flutter-project-setup-toolkit
```

```bash
dart run flutter_project_setup_toolkit:toolkit_studio
dart run flutter_project_setup_toolkit:setup_project --project .
```

### Clone this repository

```bash
git clone https://github.com/vishalsharma7nov/flutter-project-setup-toolkit.git
cd flutter-project-setup-toolkit
dart pub get
dart run :toolkit_studio
```

Shell scripts in `scripts/` are thin wrappers around Dart executables.

---

## Executables

| Command | Description |
|---------|-------------|
| `toolkit_studio` | Hub UI — all studios (Setup, Build, CI, QA, Docs, …) |
| `setup_project` | Interactive terminal setup wizard |
| `setup_studio` | Setup Studio only (legacy; use hub) |
| `make_feature` | Scaffold feature folders |
| `classify_version_bump` | Semver classification from git |
| `qa_release_notes` | QA handoff JSON/Markdown from git or codebase scan |
| `codebase_understand` | Heuristic project scan (modules, routes, deps) |
| `project_docs` | Generate README and `doc/` guides (CLI) |
| `ci_studio` | Generate, test, and publish GitHub Actions workflows |
| `build_android` | Release APK or AAB |
| `build_ios_ipa` | Release IPA |
| `build_distribution` | Distribution Studio GUI |
| `architecture_audit` | Architecture detect + compliance report |

---

## Architecture presets

15 folder-layout presets including clean architecture, MVVM/MVC/MVI, Redux, hexagonal, BLoC/Riverpod/GetX/Stacked, **micro-feature monorepo** (melos), and **custom JSON templates**.

Optional bootstrap:

- **Core modules** — errors, logging, theme, connectivity stubs under `lib/core/`
- **Routing** — `go_router` or `auto_route` router stubs
- **Flavor mains** — `main_dev.dart`, `main_prod.dart`, … per environment
- **Test mirror** — `test/` stubs mirroring scaffolded feature files

See [doc/architecture.md](doc/architecture.md).

---

## Configuration

Each Flutter app has its own `release-toolkit.config.json`:

```json
{
  "default_environment": "dev",
  "environments": {
    "dev": ".env/development.env",
    "prod": ".env/production.env"
  },
  "architecture": { "preset": "feature_first_clean" },
  "api": { "protocol": "rest" }
}
```

Full example: [`release-toolkit.config.example.json`](release-toolkit.config.example.json)

See [doc/configuration.md](doc/configuration.md).

---

## Toolkit Studio

Local dashboard at `http://127.0.0.1:8765`:

| Studio | Route | Purpose |
|--------|-------|---------|
| Hub | `/` | Project picker, create/repair, navigation |
| Setup | `/setup` | Environments, config, architecture, API |
| Distribution | `/build` | APK, AAB, IPA; Git remote; secure env overlay |
| Quick Test | `/quick-test` | Git URL → build APK/IPA → install on devices (Mac UI or mobile companion) |
| Feature | `/feature` | Scaffold features |
| Package | `/packages` | Search pub.dev or Git; install dependencies |
| Version | `/version` | Classify bump and update env keys |
| Project doctor | `/doctor` | Config, env files, signing hints, architecture audit summary |
| CI/CD | `/ci` | Generate, test, and publish GitHub Actions workflows |
| QA release notes | `/qa` | Compare commits; export QA handoff |
| Project documentation | `/docs` | Generate README and `doc/` guides for your app |

See [doc/toolkit-studio.md](doc/toolkit-studio.md) and [doc/studio-desktop.md](doc/studio-desktop.md).

---

## Architecture audit

```bash
dart run :architecture_audit --project /path/to/app
dart run :architecture_audit --project /path/to/app --json
```

Detects preset drift vs `release-toolkit.config.json` and flags cross-feature `data/` imports in `presentation/`.

See [doc/architecture-audit.md](doc/architecture-audit.md).

---

## Tests

```bash
dart pub get
dart analyze
dart test
```

---

## Documentation

| Guide | Topic |
|-------|-------|
| [doc/README.md](doc/README.md) | Documentation index |
| [doc/setup-wizard.md](doc/setup-wizard.md) | Setup wizard |
| [doc/toolkit-studio.md](doc/toolkit-studio.md) | All Studio UIs and APIs |
| [doc/studio-desktop.md](doc/studio-desktop.md) | macOS desktop app |
| [doc/architecture.md](doc/architecture.md) | Presets, core modules, routing |
| [doc/feature-scaffolding.md](doc/feature-scaffolding.md) | `make_feature` |
| [doc/package-studio.md](doc/package-studio.md) | Package Studio (pub.dev / Git) |
| [doc/api-layer.md](doc/api-layer.md) | API protocol config |
| [doc/versioning.md](doc/versioning.md) | Version classification |
| [doc/qa-release-notes.md](doc/qa-release-notes.md) | QA handoff and `codebase_understand` |
| [doc/ci-studio.md](doc/ci-studio.md) | CI/CD workflow generation |
| [doc/project-docs.md](doc/project-docs.md) | Docs Studio |
| [doc/building.md](doc/building.md) | Android & iOS builds |
| [doc/architecture-audit.md](doc/architecture-audit.md) | Architecture audit CLI |
| [doc/configuration.md](doc/configuration.md) | Config reference |
| [doc/multi-app-setup.md](doc/multi-app-setup.md) | Multiple apps |
| [doc/publishing.md](doc/publishing.md) | pub.dev release |
| [doc/troubleshooting.md](doc/troubleshooting.md) | Common issues |

---

## Publishing

1. Push to [github.com/vishalsharma7nov/flutter-project-setup-toolkit](https://github.com/vishalsharma7nov/flutter-project-setup-toolkit).
2. Push this directory as the repository root.
3. Tag releases: `v0.2.0` (see [CHANGELOG.md](CHANGELOG.md) for history).
4. Optional: `dart pub publish` — see [doc/publishing.md](doc/publishing.md).

---

## License

MIT — see [LICENSE](LICENSE).
