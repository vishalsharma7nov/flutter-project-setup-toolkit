# Toolkit Studio

**Toolkit Studio** is a local web dashboard (and optional macOS desktop app) that unifies project setup, distribution builds, quick test from Git, feature scaffolding, and version bumping.

```bash
# From toolkit repo root
dart run :toolkit_studio
./scripts/toolkit-studio.sh

# With project pre-selected
dart run :toolkit_studio --project /path/to/app

# Browser instead of macOS desktop
dart run :toolkit_studio --browser

# Deep link to a studio
dart run :toolkit_studio --view setup
dart run :toolkit_studio --view build
dart run :toolkit_studio --view feature
dart run :toolkit_studio --view version
dart run :toolkit_studio --view quick-test
dart run :toolkit_studio --view ci
dart run :toolkit_studio --view qa
dart run :toolkit_studio --view docs
dart run :toolkit_studio --view packages
dart run :toolkit_studio --view doctor
```

Default URL: `http://127.0.0.1:8765`

## Hub

The hub (`/`) provides:

- **Project picker** — load, analyze, repair, or create a Flutter project
- **Environment bar** — Dart, Flutter, and Xcode detection
- **Studio cards** — navigate to each workflow

| Card | Route | Purpose |
|------|-------|---------|
| Setup flutter project | `/setup` | First-time config, architecture, API protocol |
| Build APK & IPA | `/build` | Distribution Studio |
| Quick Test | `/quick-test` | Git URL → build & install on devices |
| CI/CD | `/ci` | Generate, test locally, publish GitHub Actions workflows |
| Add feature | `/feature` | Feature scaffolding |
| Add package | `/packages` | Search pub.dev or paste link; install dependencies |
| Bump version | `/version` | Semver classification and env updates |
| Project doctor | `/doctor` | Config, env files, signing hints, architecture audit summary |
| QA release notes | `/qa` | Compare commits; export QA handoff |
| Project documentation | `/docs` | Generate README and `doc/` guides |

## Setup Studio (`/setup`)

Step-by-step wizard:

1. **Project** — path and detection
2. **Environments** — dev/prod/staging presets, env file paths
3. **Versions** — version key names, optional flavors, `main.dart` rules
4. **Toolkit** — install mode, architecture preset, API protocol, state management, bootstrap options
5. **Review** — preview plan, compatibility warnings, apply or dry-run

### Architecture options (step 4)

- **Architecture preset** — all 15 presets (grouped: Core, Pattern-based, State-management, Advanced)
- **Custom template path** — when preset is `custom`
- **Core modules** — errors, logging, theme, connectivity stubs
- **Bootstrap extras** — flavor `main_<env>.dart` files, test mirror under `test/`
- **API protocol** — REST, gRPC, GraphQL, external SDK, etc.
- **External SDK** — git URL, ref, package path (when protocol is `external_sdk`)
- **State management** — bloc, riverpod, provider, getx, none
- **Optional feature scaffold** — create first feature during setup

### API endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/setup/detect?path=` | Project detection for wizard |
| POST | `/api/setup/env-paths` | Compute env file paths from GUI state |
| POST | `/api/setup/preview` | Preview setup plan |
| POST | `/api/setup/apply` | Apply setup (async; poll status) |
| GET | `/api/setup/apply/status?offset=` | Apply logs |
| GET | `/api/setup/architecture/detect?path=` | Infer architecture preset |
| GET | `/api/setup/architecture/audit?path=` | Architecture audit report |

## Distribution Studio (`/build`)

Build **Android APK/AAB** and **iOS IPA** with live logs in the browser.

### Features

- Environment picker from `release-toolkit.config.json`
- Android APK and AAB targets
- iOS IPA with scheme detection
- **Cancel build** button
- **Secure env overlay** — local file, paste, or key-value map (not written to repo)
- **Git remote builds** — clone from GitHub/Git with SSH or HTTPS token
- iOS scheme dropdown from detected Xcode schemes

### API endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/distribution/project` | Loaded project info |
| POST | `/api/distribution/preflight` | Validate build parameters |
| POST | `/api/distribution/repo/preflight` | Validate Git remote source |
| POST | `/api/distribution/build` | Start build |
| POST | `/api/distribution/cancel` | Cancel running build |
| GET | `/api/distribution/status?offset=` | Build logs |
| GET/POST | `/api/distribution/config` | Studio config |

See [building.md](building.md) for CLI equivalents.

## CI Studio (`/ci`)

Generate **GitHub Actions** workflows from `release-toolkit.config.json`, run **local smoke tests**, and **publish via pull request** only after a green test.

Requires a loaded Flutter project with config. See [ci-studio.md](ci-studio.md) for presets, secrets, and act usage.

```bash
dart run :toolkit_studio --view ci --project .
dart run :ci_studio --project . --write --test
```

## Package Studio (`/packages`)

Search **pub.dev** or paste a package URL/name, preview metadata, and install into the **loaded project** with `flutter pub add` or `dart pub add` (regular or dev dependencies).

Requires a loaded Flutter project from the hub. See [package-studio.md](package-studio.md).

## Quick Test Studio (`/quick-test`)

Paste a **Git repository URL** for a Flutter **app or plugin**, validate it, build **APK** and (on macOS) **TestFlight IPA**, and **install on connected devices** when possible. **Plugins** are built and installed through their **`example/`** app automatically.

No local project checkout is required — Quick Test works from the hub without loading a project folder first.

### Features

- Git URL with branch, subdirectory, SSH / HTTPS / token auth
- Flutter validation and structure warnings
- Connected device list (`flutter devices`) with install checkboxes
- **Android**: build APK + `adb install` on selected devices
- **iOS device**: `flutter build ios` + `flutter install` (requires Xcode signing)
- **TestFlight**: `flutter build ipa` + archive path (upload via Xcode Organizer — **not** USB sideload)
- Secure env overlay when the cloned repo has no env file (optional — builds proceed without dart-defines when env is not configured)

### Limitations

- Git clones rarely include secrets — provide env via overlay when the app needs dart-defines; otherwise Quick Test builds without an env file
- **Flutter plugins** must include a runnable `example/` app (standard `flutter create --template=plugin` layout)
- iOS USB install needs development/distribution certs configured in Xcode
- TestFlight IPA is for App Store Connect upload, not direct device install
- Windows/Linux hosts: Android APK + install only (iOS toggles hidden)

### API endpoints

| Method | Path | Description |
|--------|------|-------------|
| POST | `/api/quick-test/preflight` | Clone, Flutter check, devices, env |
| POST | `/api/quick-test/run` | Start pipeline (202) |
| GET | `/api/quick-test/status?offset=` | Logs, artifact paths, and `artifact_urls` |
| GET | `/api/quick-test/artifacts/download?path=` | Download build artifact (APK/IPA) |
| POST | `/api/quick-test/cancel` | Cancel running process |

### Mobile companion (Android / iOS)

Use the **`studio_app`** native app on a phone while your **Mac** remains the build host:

1. On Mac: `./scripts/toolkit-studio.sh --host lan` (prints a LAN URL for pairing)
2. Install `studio_app` on Android or iOS (`cd studio_app && flutter run`)
3. Enter Mac IP + port, paste Git URL, tap **Build & install on this device**

The mobile app sends `install_mode: client_download` so the Mac builds only; Android phones download the APK over WiFi and open the system installer. **iOS over WiFi cannot sideload** — the app shows TestFlight/USB guidance after the Mac build completes.

Run options for mobile clients:

| Field | Value |
|-------|-------|
| `platform` | `android` or `ios` (auto from device OS) |
| `install_mode` | `client_download` |
| `install_to_devices` | `false` |

Deep link:

```bash
dart run :toolkit_studio --view quick-test
./scripts/toolkit-studio.sh --view quick-test
./scripts/toolkit-studio.sh --host lan --view quick-test
```

## Feature Studio (`/feature`)

Scaffold feature modules without re-running full setup.

- Pick architecture preset and API protocol
- Preview folder tree before apply
- Save architecture/API changes back to `release-toolkit.config.json`
- Respects `scaffold_test_mirror` from config

### API endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/feature/detect?path=` | Load project config and options |
| POST | `/api/feature/preview` | Preview scaffold |
| POST | `/api/feature/apply` | Create feature folders |
| GET | `/api/feature/status` | Apply status |
| POST | `/api/feature/save-config` | Update config architecture/API |

## Version Studio (`/version`)

GUI for `classify_version_bump`:

- Pick environment or env file
- Preview semver bump from latest commit (or specific commit)
- Dry-run or apply version key updates to env files
- Shows Android and iOS tracks separately

### API endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/version/environments?path=` | List configured environments |
| POST | `/api/version/preview` | Classify bump + suggest versions |
| POST | `/api/version/apply` | Write env file updates |

Body fields: `project`, `commit` (default `HEAD`), `env`, `env_file`, `dry_run`.

## QA Release Notes Studio (`/qa`)

Compare **HEAD~1 → HEAD** (or **last tag → HEAD**) and export a QA handoff document.

- Preview Markdown, copy to clipboard, download multiple formats
- Summary cards: time estimate, risk, platforms, Go/No-Go
- Audience modes: QA, PM, Executive
- Optional GitHub compare / PR links when `gh` is available
- Quick Test deep link for the same commit

### API endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/qa/compare-options?project=` | Compare range dropdown options |
| POST | `/api/qa/preview` | Generate handoff (JSON + markdown) |
| GET | `/api/qa/download` | Download export (`format`, `base_mode`, `audience`) |

See [qa-release-notes.md](qa-release-notes.md) for formats and CI usage.

## Project Doctor (`/doctor`)

Health check for a loaded Flutter project — no write actions.

- Dart/Flutter on PATH, `pubspec.yaml`, `lib/main.dart`
- `release-toolkit.config.json` and env file paths
- Android/iOS signing hints (keystore, Xcode scheme)
- Architecture audit summary (preset drift, cross-feature imports)

Works without loading a project from the hub first (enter path on the doctor page). Also used internally by Docs Studio.

### API endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/doctor?path=` | Run all checks; JSON report |

## Project Docs Studio (`/docs`)

Generate README and `doc/` guides from static analysis. See [project-docs.md](project-docs.md) for the full file list, overwrite policies, and CLI (`project_docs`).

### API endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/docs/detect?path=` | Scan project; list missing docs |
| POST | `/api/docs/preview` | Preview generated files + diffs |
| POST | `/api/docs/write` | Write documentation to disk |

## Shared hub APIs

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/environment` | Dart/Flutter/Xcode capabilities |
| GET | `/api/bootstrap` | Current project path |
| POST | `/api/project` | Set active project |
| GET | `/api/project/analyze?path=` | Structure analysis |
| POST | `/api/project/create` | `flutter create` new project |

## macOS desktop app

See [studio-desktop.md](studio-desktop.md). The desktop shell embeds the same UI and opens the project picker on launch.

## Ports

| Studio | Default port |
|--------|----------------|
| Toolkit Studio hub | 8765 |
| Setup Studio (standalone `setup_studio`) | 8766 |

Use `--port` to override.

## See also

- [Setup wizard](setup-wizard.md) — terminal equivalent of Setup Studio
- [Feature scaffolding](feature-scaffolding.md)
- [Version classification](versioning.md)
- [Building](building.md)
