# Build scripts

Release build wrappers around `flutter build` that load dart-defines from your env file and show a confirmation summary before building.

## Prerequisites

- Flutter SDK (or FVM) on `PATH`
- **Android**: Android SDK, JDK, signing configured in the Flutter project
- **iOS**: macOS, Xcode, CocoaPods; valid signing & provisioning

## Android

```bash
dart run :build_android --project /path/to/app --env prod
dart run :build_android --project . --env-file .env/release.env
dart run :build_android --project . --env prod --aab
dart run :build_android --project . --env staging --flavor staging
```

Or from app scripts:

```bash
./scripts/build-android.sh --project /path/to/app --env prod
```

### Output locations

| Format | Typical path |
|--------|----------------|
| APK | `build/app/outputs/flutter-apk/*.apk` |
| AAB | `build/app/outputs/bundle/release/*.aab` |

### Environment variables

| Variable | Description |
|----------|-------------|
| `RTK_PROJECT` | Project root |
| `ENV_FILE` | Env file path |
| `APP_ENV` | Optional extra `--dart-define=APP_ENV=...` |
| `BUILD_FORMAT` | `apk` or `aab` |
| `ANDROID_FLAVOR` | Product flavor |
| `SKIP_CONFIRM` | `true` to skip prompt |
| `FLUTTER_CMD` | e.g. `fvm flutter` |

## iOS

```bash
dart run :build_ios_ipa --project /path/to/app --env prod
dart run :build_ios_ipa --project . --env-file .env/release.env --no-organizer
```

Or:

```bash
./scripts/build-ios-ipa.sh --project /path/to/app --env prod
```

### Output locations

| Artifact | Path |
|----------|------|
| Archive | `build/ios/archive/*.xcarchive` |
| IPA | `build/ios/ipa/*.ipa` |

When `open_organizer` is true (default), the `.xcarchive` opens in Xcode Organizer after a successful build.

### Environment variables

| Variable | Description |
|----------|-------------|
| `RTK_PROJECT` | Project root |
| `ENV_FILE` | Env file path |
| `IOS_SCHEME` | Xcode scheme (default `Runner`) |
| `IOS_FLAVOR` | Flutter flavor |
| `OPEN_ORGANIZER` | `true` / `false` |
| `SKIP_CONFIRM` | `true` to skip prompt |

## Resolving the env file

Priority:

1. `--env-file` or `ENV_FILE`
2. `--env <name>` via `environments` in config
3. `main_dart_env_rules` match in `lib/main.dart` → environment name → config path

If none resolve, the script exits with an error message.

## CI usage

```bash
export SKIP_CONFIRM=true
export RTK_PROJECT="$GITHUB_WORKSPACE"
./scripts/build-android.sh --env prod --aab
```

Non-interactive shells and `CI=true` / `GITHUB_ACTIONS=true` also skip confirmation automatically.

## Comparison to raw `flutter build`

These scripts add:

- Project root discovery (`pubspec.yaml` walk-up)
- Config-driven env file resolution
- Pre-build parameter summary (secrets masked)
- Optional confirmation gate
- Consistent artifact path reporting

They do **not** manage signing credentials, store uploads, or fastlane — only the local `flutter build` invocation.

## Build from a Git remote (CLI)

Build a project cloned from GitHub or any Git host without a local checkout:

```bash
dart run flutter_project_setup_toolkit:build_distribution \
  --git-url git@github.com:org/my-app.git \
  --ref main \
  --env prod \
  --target android_apk \
  --auth ssh
```

HTTPS private repos (token is session-only, never logged):

```bash
dart run flutter_project_setup_toolkit:build_distribution \
  --git-url https://github.com/org/private-app.git \
  --ref main \
  --env prod \
  --auth https_token \
  --token "$GITHUB_TOKEN"
```

Monorepo subdirectory:

```bash
dart run flutter_project_setup_toolkit:build_distribution \
  --git-url git@github.com:org/mono.git \
  --subdir apps/mobile \
  --env prod
```

Preflight via Studio API: `POST /api/distribution/repo/preflight` with a `source` JSON block.

## Providing env secrets safely

When the env file is not in the repo, pass a local overlay for this build only:

```bash
dart run flutter_project_setup_toolkit:build_distribution \
  --project /path/to/app \
  --env prod \
  --env-source-file ~/.secrets/myapp/prod.env
```

Studio build API accepts `env_source`:

```json
{
  "mode": "local_file",
  "path": "/Users/me/.secrets/myapp/prod.env"
}
```

or `session_values` with a key map. Values are not written to the project repo or persisted in logs.

Open Distribution Studio:

```bash
dart run :build_distribution --project .
dart run :toolkit_studio --view build
./scripts/build-distribution.sh
```

See [toolkit-studio.md](toolkit-studio.md#distribution-studio-build) for GUI features (AAB, cancel, secure env, Git remote).

## Quick Test Studio (GUI)

For the fastest path from a **local project folder** or **Git repo** to a device build (Flutter **app or plugin**):

```bash
dart run :toolkit_studio --view quick-test
```

**Local folder (default):** click **Browse…** or enter the project path, then **Check project**.

**Git URL:** switch to Git mode, paste the URL, and click **Check repo**.

1. Choose source (local folder or Git) and validate
2. Provide env secrets only if the app requires dart-defines (optional for plain Flutter apps)
3. Select connected devices (optional)
4. Click **Run quick test**

| Step | Android | iOS (macOS) |
|------|---------|-------------|
| Build | Release APK | `flutter build ios` for device install; `flutter build ipa` for TestFlight |
| Install | `adb install -r` on selected devices | `flutter install` on USB-connected iPhone |
| Artifacts | APK under `build/app/outputs/` | IPA/archive under `build/ios/` |

**Plugins:** Quick Test detects `flutter: plugin:` in `pubspec.yaml` and builds the **`example/`** app (where the plugin is exercised). Set Git subdirectory to `example` if you only want that folder.

**TestFlight vs device install:** the TestFlight IPA is uploaded through Xcode Organizer or Transporter — it is not installed over USB. Device testing uses `flutter build ios` + `flutter install` instead.

See [toolkit-studio.md](toolkit-studio.md#quick-test-studio-quick-test) for API details and limitations.
