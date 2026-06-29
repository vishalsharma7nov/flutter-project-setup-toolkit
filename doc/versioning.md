# Version classification

`classify_version_bump` inspects a git commit and suggests a **semver bump level**: `major`, `minor`, or `patch`.

Use the **Version Studio** in Toolkit Studio (`/version`) for a GUI, or the CLI below.

## Usage

```bash
dart run :classify_version_bump --project /path/to/flutter-app --verbose
dart run :classify_version_bump --project . --env prod --suggest --verbose
dart run :classify_version_bump --project . --env both --apply-env --dry-run
```

From app `scripts/`:

```bash
./scripts/classify-version-bump.sh --env prod --suggest --verbose
```

Global install:

```bash
dart pub global activate flutter_project_setup_toolkit
classify_version_bump --project ~/apps/my_app --json
```

## Signals

The classifier combines commit message patterns and changed files:

| Signal | Typical bump |
|--------|----------------|
| `BREAKING CHANGE`, deleted `lib/` Dart files, removed routes | **major** |
| `feat:`, new presentation pages, router/l10n changes | **minor** |
| `fix:`, docs-only, test-only edits | **patch** |

This is a **heuristic** — always review before releasing.

## Version bump behavior

When `--suggest` or `--apply-env` is used, the tool reads current versions from the selected env file(s):

- **Android**: marketing version + integer build/code (both increment)
- **iOS**: marketing version on its own track; build number **resets to 1** when marketing version changes

Android and iOS versions are independent.

If Android keys are missing from an env file, the tool falls back to `pubspec.yaml` `version:` for the current Android baseline.

## Applying changes

```bash
# Interactive: prompts for env (if multiple) and confirmation
dart run :classify_version_bump --project . --apply-env

# Non-interactive
dart run :classify_version_bump --project . --env prod --apply-env --yes
SKIP_CONFIRM=true dart run :classify_version_bump --project . --env prod --apply-env
```

## JSON output

```bash
dart run :classify_version_bump --project . --env prod --suggest --json
```

Includes `commit`, `bump`, `reasons`, `project`, `environments` with per-platform version suggestions and env key diffs.

## Version Studio API

| Method | Path | Body |
|--------|------|------|
| GET | `/api/version/environments?path=` | — |
| POST | `/api/version/preview` | `project`, `commit`, `env`, `env_file` |
| POST | `/api/version/apply` | same + `dry_run` |

## Flags reference

| Flag | Description |
|------|-------------|
| `--project` | Flutter project root |
| `--config` | Path to `release-toolkit.config.json` |
| `--env` | Named environment from config, or `both` |
| `--env-file` | Single env file (bypasses config) |
| `--suggest` | Show suggested next versions |
| `--apply-env` | Write updated version keys |
| `--dry-run` | Preview without writing |
| `--yes` / `-y` | Skip confirmation |
| `--json` | Machine-readable output |
| `--verbose` | Print classification reasons |

## See also

- [Toolkit Studio — Version Studio](toolkit-studio.md#version-studio-version)
- [Configuration](configuration.md)
