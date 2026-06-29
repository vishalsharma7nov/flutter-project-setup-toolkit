# Using flutter_project_setup_toolkit with multiple apps

Share one toolkit checkout across several Flutter apps. Each app keeps its own `release-toolkit.config.json` and env files.

## Repository layout

```text
workspace/
├── flutter-project-setup-toolkit/     # shared toolkit (clone or path dependency)
├── consumer-app-a/
│   ├── release-toolkit.config.json
│   └── scripts/
│       ├── rtk-locate.sh
│       ├── classify-version-bump.sh
│       ├── build-android.sh
│       └── build-ios-ipa.sh
└── consumer-app-b/
    ├── release-toolkit.config.json
    └── scripts/
        └── ...
```

**Option A — toolkit inside one app repo**

```text
my_flutter_app/
├── flutter-project-setup-toolkit/
├── release-toolkit.config.json
└── scripts/
    └── classify-version-bump.sh
```

**Option B — toolkit as a sibling directory**

```text
projects/
├── flutter-project-setup-toolkit/
└── my_flutter_app/
    └── scripts/rtk-locate.sh   # finds ../flutter-project-setup-toolkit
```

## Per-app config

Each app defines its own environments and version keys:

| App | Config | Example dev env | Example prod env |
|-----|--------|-----------------|------------------|
| App A | `release-toolkit.config.json` | `.env/dev.env` | `.env/prod.env` |
| App B | `release-toolkit.config.json` | `.secrets/app.local.env` | `.secrets/app.prod.env` |

Use `main_dart_env_rules` when the active environment is selected in `lib/main.dart` (see [configuration.md](configuration.md)).

Set `build.ios_flavor` and `build.android_flavor` per app when flavors differ.

## Wrapper scripts

Thin shell wrappers in each app call the Dart package:

```bash
dart run :classify_version_bump --env prod --suggest --verbose
dart run :build_android --env prod --aab
dart run :build_ios_ipa --env prod
```

Or use generated app scripts:

```bash
./scripts/classify-version-bump.sh --env prod --suggest --verbose
./scripts/build-android.sh --env prod --aab
```

Example `rtk-locate.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
APP_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$APP_ROOT/../flutter-project-setup-toolkit/lib/sh/locate-toolkit.sh"
_rtk_locate_toolkit "$APP_ROOT" || exit 1
```

Adjust the `source` path to match where you cloned the toolkit.

## Custom toolkit path

```bash
export FLUTTER_PROJECT_SETUP_TOOLKIT=/path/to/flutter-project-setup-toolkit
```

Works from any app wrapper script. The legacy `FLUTTER_RELEASE_TOOLKIT` env var is still supported.

## Publishing the toolkit

1. Push `flutter-project-setup-toolkit/` as its own GitHub repo (see [publishing.md](publishing.md)).
2. Consumers install via `dart pub global activate flutter_project_setup_toolkit` or a `dev_dependencies` path/git ref.
3. Local development can still use `FLUTTER_PROJECT_SETUP_TOOLKIT` or a path dependency.
