# Interactive project setup

`setup_project` walks you through configuring **flutter_project_setup_toolkit** for a Flutter app: environments, env file paths, architecture preset, API protocol, version keys, and wrapper scripts.

**Prefer a GUI?** Use **Toolkit Studio** → Setup (`/setup`) or:

```bash
dart run :toolkit_studio --view setup --project .
dart run :setup_studio --project .
```

## Quick start

```bash
cd /path/to/your_flutter_app
dart pub global activate flutter_project_setup_toolkit   # once
dart run :setup_project --project .
```

Or with a path dependency:

```bash
dart run flutter_project_setup_toolkit:setup_project --project .
```

## What it asks (terminal wizard)

1. **Environments** — dev + prod, dev + staging + prod, or custom names
2. **Env file location** — `.env/`, `.secrets/`, or a custom directory
3. **Default environment** — the one you work on most (used when `--env` is omitted)
4. **Version key names** — defaults or custom (`APP_VERSION_NAME`, etc.)
5. **Build flavors** — optional iOS/Android flavor names
6. **`main.dart` rules** — auto-detected patterns for environment selection
7. **Toolkit install mode** — dev dependency, local clone, or pub global
8. **State management** — bloc, riverpod, provider, getx, or none
9. **Architecture preset** — 15 layout presets (terminal) or full picker in Setup Studio
10. **API protocol** — REST, gRPC, GraphQL, external SDK, etc.
11. **Scaffolding** — create env templates and `scripts/` wrappers
12. **CI workflow (optional)** — generate GitHub Actions workflow, or use [CI Studio](ci-studio.md) later
13. **Bootstrap options** (Setup Studio) — core modules, flavor mains, test mirror
14. **Feature to work on (optional)** — scaffold a clean-architecture folder
15. **Auto-install** — adds `flutter_project_setup_toolkit` to `pubspec.yaml` or activates global CLI

After all questions, a **review screen** lets you apply, change individual settings, or cancel.

## What it creates

| Output | Description |
|--------|-------------|
| `release-toolkit.config.json` | Environments, architecture, API, version keys, `default_environment` |
| `.env/*.env` (or `.secrets/*.env`) | Template files with version keys |
| `lib/core/`, router, flavor mains | When architecture bootstrap options are enabled |
| `scripts/classify-version-bump.sh` | Version classifier wrapper |
| `scripts/build-android.sh` | Android release build wrapper |
| `scripts/build-ios-ipa.sh` | iOS IPA build wrapper |
| `scripts/toolkit-studio.sh` | Toolkit Studio hub (setup, build, Quick Test, feature, version) |
| `scripts/setup-studio.sh` | Setup Studio GUI (legacy; hub preferred) |
| `scripts/build-distribution.sh` | Distribution Studio GUI |
| `scripts/make-feature.sh` | Feature scaffold |
| `.github/workflows/*.yml` | When CI workflow generation is enabled (or use CI Studio) |
| `scripts/rtk-locate.sh` | Only when using a local toolkit clone |
| `pubspec.yaml` dev dependency | When using dev dependency mode |

Existing files are skipped unless you pass `--force`.

## Non-interactive (CI / scripting)

```bash
dart run :setup_project \
  --project . \
  --yes \
  --preset dev-prod \
  --env-dir .env \
  --default-env dev
```

| Flag | Description |
|------|-------------|
| `--yes` | Skip prompts; use defaults |
| `--preset` | `dev-prod` or `dev-staging-prod` |
| `--env-dir` | `.env` or `.secrets` |
| `--default-env` | Default working environment name |
| `--toolkit-path` | Relative path to toolkit checkout for `dart pub add --path` |
| `--make-feature` | Scaffold a feature after setup |
| `--feature-base-path` | Base directory for `--make-feature` |
| `--state-management` | `bloc`, `riverpod`, `provider`, `getx`, `none` |
| `--force` | Overwrite existing config/scripts |
| `--dry-run` | Print planned changes only |
| `--gui` | Open Setup Studio |

## Setup Studio GUI fields

Setup Studio (step 4) additionally exposes:

| Field | Config path |
|-------|-------------|
| Architecture preset | `architecture.preset` |
| Custom template path | `architecture.custom_template_path` |
| Core modules toggles | `architecture.core_modules.*` |
| Flavor mains | `architecture.bootstrap.flavor_mains` |
| Test mirror | `architecture.bootstrap.scaffold_test_mirror` |
| API protocol | `api.protocol` |
| External SDK git URL | `api.external_sdk` |

Architecture detect/audit APIs are available during setup — see [architecture-audit.md](architecture-audit.md).

## After setup

1. Fill in API keys and secrets in env files
2. Run `dart run :classify_version_bump --verbose` or open Version Studio
3. Build with `dart run :build_android --env prod` or Distribution Studio
4. Audit architecture: `dart run :architecture_audit --project .`

## See also

- [Toolkit Studio](toolkit-studio.md)
- [Architecture presets](architecture.md)
- [Configuration](configuration.md)
