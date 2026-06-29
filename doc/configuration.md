# Configuration

Projects integrate **flutter_project_setup_toolkit** with `release-toolkit.config.json` at the Flutter app root (beside `pubspec.yaml`).

## Minimal config

```json
{
  "environments": {
    "dev": ".env/development.env",
    "prod": ".env/production.env"
  }
}
```

Paths are relative to the project root unless absolute.

## Full example

See [`release-toolkit.config.example.json`](../release-toolkit.config.example.json).

## Sections

### `environments`

Maps a short name to an env file used with Flutter `--dart-define-from-file`.

Build scripts resolve `--env prod` to the configured path. The version classifier uses the same mapping for `--env` and `--apply-env`.

Use `--env both` to update every configured environment independently.

### `default_environment`

Optional. Names the environment used when `--env` is omitted and `lib/main.dart` rules do not match. Set automatically by `setup_project`.

```json
{
  "default_environment": "dev"
}
```

### `state_management`

Default for feature scaffolding: `bloc`, `riverpod`, `provider`, `getx`, or `none`.

### `architecture`

Folder layout and bootstrap options. See [architecture.md](architecture.md) for preset catalog.

| Field | Description |
|-------|-------------|
| `preset` | One of 15 preset IDs (e.g. `feature_first_clean`, `micro_feature`, `custom`) |
| `feature_base_path` | Root for features (default varies by preset) |
| `layers` | Toggle `domain`, `data`, `presentation`, `use_cases` |
| `bootstrap` | `core`, `app_router`, `shared`, `melos`, `flavor_mains`, `scaffold_test_mirror` |
| `core_modules` | `errors`, `logging`, `theme`, `connectivity` stubs |
| `routing` | `go_router`, `auto_route`, or `none` |
| `dependency_injection` | `get_it`, `injectable`, `riverpod`, `none` |
| `custom_template_path` | Path to JSON template when `preset` is `custom` |
| `custom_template` | Inline template object (alternative to path) |

### `api`

Backend integration options. See [api-layer.md](api-layer.md).

| Field | Description |
|-------|-------------|
| `protocol` | `rest`, `grpc`, `graphql`, `external_sdk`, etc. |
| `rest_client` | `dio` or `http` |
| `use_retrofit` | Retrofit-style REST |
| `codegen` | `json_serializable`, `freezed` hints |
| `base_url_env_key` | Env key for API URL (default `API_BASE_URL`) |
| `external_sdk` | Git dependency config for vendor SDKs |

### `version_keys`

Override env file key names if your project does not use the defaults:

```json
{
  "version_keys": {
    "android_name": "APP_VERSION_NAME",
    "android_code": "APP_VERSION_CODE",
    "ios_marketing": "BUNDLE_VERSION_STRING",
    "ios_build": "BUNDLE_VERSION"
  }
}
```

| Key | Typical use |
|-----|-------------|
| `android_name` | Android `versionName` |
| `android_code` | Android `versionCode` |
| `ios_marketing` | iOS marketing version |
| `ios_build` | iOS build number (resets when marketing version changes) |

### `build`

Optional defaults for platform build scripts:

```json
{
  "build": {
    "android_flavor": null,
    "ios_flavor": null,
    "ios_scheme": "Runner",
    "open_organizer": true
  }
}
```

Null or omitted values mean “not set” (no `--flavor` unless passed on CLI).

### `main_dart_env_rules`

Optional rules to pick an environment by scanning `lib/main.dart`:

```json
{
  "main_dart_env_rules": [
    {
      "match": "const environment = Environment.production;",
      "environment": "prod"
    }
  ]
}
```

When a rule’s `match` string appears in `main.dart`, build scripts and the classifier can default to that environment without passing `--env`.

## Overrides without config

| Mechanism | Used by |
|-----------|---------|
| `--env-file path` | All tools |
| `ENV_FILE=path` | Build scripts |
| `--config path` | Classifier |
| `RTK_CONFIG=path` | Build scripts |
| `RTK_PROJECT=path` | All tools (project root) |

## Env file format

Plain `KEY=value` lines. Comments (`#`) and blank lines are allowed.

```env
APP_ENV=production
APP_VERSION_NAME=1.2.3
APP_VERSION_CODE=42
BUNDLE_VERSION_STRING=1.2.3
BUNDLE_VERSION=42
API_BASE_URL=https://api.example.com
```

Sensitive values are masked in build confirmation output when the key name contains `KEY`, `SECRET`, `TOKEN`, or `PASSWORD`.

## See also

- [Setup wizard](setup-wizard.md)
- [Architecture presets](architecture.md)
- [API layer](api-layer.md)
- [Troubleshooting](troubleshooting.md)
