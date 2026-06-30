# Troubleshooting

Common issues when using Flutter Project Setup Toolkit.

## General

| Problem | Cause | Fix |
|---------|-------|-----|
| `Could not resolve env file` | No config and no `--env-file` | Add `release-toolkit.config.json` or pass `--env-file` |
| `Missing env file: ...` | Wrong path | Create the file; check `environments` in config |
| `Missing lib/main.dart` | Not a Flutter project | Pass correct `--project` (folder with `pubspec.yaml`) |
| Command not found after global install | PATH | Add `$HOME/.pub-cache/bin` to PATH |

## Toolkit Studio

| Problem | Cause | Fix |
|---------|-------|-----|
| Blank page / connection refused | Server not running | Run `dart run :toolkit_studio` from toolkit repo |
| Port in use | Another process on 8765 | `dart run :toolkit_studio --port 8767` |
| macOS desktop blank | Server slow to start | Wait or use `--browser` |
| Folder picker cancels immediately | App behind terminal / double-click Browse | Click the Toolkit window first; wait for one picker dialog |
| Studio changes not visible | HTML cached | Restart `dart run :toolkit_studio` after toolkit updates |
| `Desktop app not found` | Wrong working directory | Run from toolkit repo root where `studio_app/` exists |
| Studio stuck on loading (45s) | `/api/environment` failing | Restart studio; if Docker is not installed, update toolkit (older builds crashed env detect) |
| `path` dependency not found | Wrong toolkit folder in `pubspec.yaml` | Use `flutter-project-setup-toolkit`, not `flutter-release-toolkit` |
| Folder picker cancels immediately | App behind terminal / double-click Browse | Focus the Toolkit window; click Browse once and wait |

## Setup

| Problem | Cause | Fix |
|---------|-------|-----|
| Config already exists | Re-running setup | Enable **Force overwrite** in Review step or `--force` |
| Toolkit install failed | Bad local path | Fix `local_toolkit_path` or switch to pub.dev mode |
| Compatibility warning | Preset vs state management mismatch | Change preset or state management, or ignore if intentional |

## Builds

| Problem | Cause | Fix |
|---------|-------|-----|
| Build confirmation in CI | Interactive prompt | `SKIP_CONFIRM=true` or `CI=true` |
| `Could not find Xcode scheme` | Wrong scheme name | Check `ios/*.xcodeproj/xcshareddata/xcschemes/` |
| iOS build on Linux/Windows | Platform limit | Use macOS or CI macOS runner |
| Flutter build fails | Signing/SDK | Run `flutter doctor` in project |
| Git remote build auth failed | SSH/key or token | Use Distribution Studio preflight or `--auth https_token --token` |

## Version bump

| Problem | Cause | Fix |
|---------|-------|-----|
| `patch` when you expected `minor` | Commit message heuristic | Use conventional commits (`feat:`, `fix:`) |
| iOS build reset to 1 | By design | Marketing version change resets iOS build number |
| No Android keys in env | Missing keys | Add keys or rely on `pubspec.yaml` fallback |

## Architecture

| Problem | Cause | Fix |
|---------|-------|-----|
| Preset drift warning | Layout differs from config | Run audit; update config or refactor folders |
| Cross-feature import error | Presentation imports other feature's data | Move shared code to `domain` or `shared/` |
| Custom template not found | Bad path | Use path relative to project root |

## Tests (toolkit development)

```bash
cd flutter-project-setup-toolkit
dart pub get
dart analyze
dart test
```

## Getting help

```bash
dart run :setup_project --help
dart run :classify_version_bump --help
dart run :build_android --help
dart run :architecture_audit --help
```

## See also

- [Documentation index](README.md)
- [Configuration](configuration.md)
- [Toolkit Studio](toolkit-studio.md)
