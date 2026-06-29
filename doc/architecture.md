# Architecture presets

The toolkit scaffolds **folder layouts** and optional **bootstrap files** based on an architecture preset stored in `release-toolkit.config.json` under `architecture`.

Choose a preset during **Setup Studio** (step 3) or **Feature Studio**, or set it in config and use `make_feature`.

## Preset catalog

### Core layouts

| Preset ID | Label | Default feature path |
|-----------|-------|----------------------|
| `feature_first_clean` | Feature-first clean architecture | `lib/features/<name>/` |
| `layer_first_clean` | Layer-first clean architecture | `lib/features/<name>/` |
| `simple` | Simple (screens + services) | `lib/features/<name>/` |
| `compass_mvvm` | Flutter Compass / MVVM hybrid | `lib/ui/<name>/` |

### Pattern-based

| Preset ID | Label | Notes |
|-----------|-------|-------|
| `mvvm` | MVVM | `viewmodels/`, `views/` |
| `mvc` | MVC | `controllers/`, `views/` |
| `mvi` | MVI | Intent/state/reducer folders |
| `hexagonal` | Hexagonal (ports & adapters) | `ports/`, `adapters/` |
| `redux` | Redux | Adds `lib/store/` at bootstrap |

### State-management aligned

| Preset ID | Label | Suggested state management |
|-----------|-------|---------------------------|
| `bloc_centric` | BLoC-centric clean arch | `bloc` |
| `riverpod_first` | Riverpod-first clean arch | `riverpod` (+ `lib/core/di/`) |
| `getx_module` | GetX module | `getx` (base path `lib/modules/`) |
| `stacked` | Stacked (MVVM) | — |

### Advanced (Tier 4)

| Preset ID | Label | Description |
|-----------|-------|-------------|
| `micro_feature` | Micro-feature monorepo | Melos workspace: `apps/shell/`, `packages/<feature>/` |
| `custom` | Custom JSON template | Mason-style paths with `{{feature}}`, `{{prefix}}`, `{{Prefix}}` |

## Config shape

```json
{
  "architecture": {
    "preset": "feature_first_clean",
    "feature_base_path": "lib/features",
    "layers": {
      "domain": true,
      "data": true,
      "presentation": true,
      "use_cases": true
    },
    "bootstrap": {
      "core": true,
      "app_router": true,
      "shared": false,
      "melos": false,
      "flavor_mains": false,
      "scaffold_test_mirror": false
    },
    "core_modules": {
      "errors": false,
      "logging": false,
      "theme": false,
      "connectivity": false
    },
    "routing": "go_router",
    "dependency_injection": "get_it",
    "scaffold_starter_code": false,
    "custom_template_path": "templates/architecture/custom_feature.example.json"
  }
}
```

### `layers`

Toggle which clean-arch layers are created per feature (`domain`, `data`, `presentation`, `use_cases`).

### `bootstrap`

| Field | Effect |
|-------|--------|
| `core` | Creates `lib/core/` tree (network, theme, utils — varies by preset) |
| `app_router` | Creates `lib/app/router/` and router stub |
| `shared` | Creates `lib/shared/widgets/` |
| `melos` | For `micro_feature`: writes `melos.yaml` and `apps/shell/` |
| `flavor_mains` | Creates `lib/main_<env>.dart` per configured environment |
| `scaffold_test_mirror` | When scaffolding features, mirrors `*_test.dart` stubs under `test/` |

### `core_modules`

Optional cross-cutting stubs under `lib/core/`:

| Module | Files created |
|--------|---------------|
| `errors` | `failures.dart`, `exceptions.dart` |
| `logging` | `app_logger.dart` |
| `theme` | `app_theme.dart` (light/dark) |
| `connectivity` | `network_info.dart` abstract stub |

Enable in **Setup Studio** step 3 or set in config before running setup.

### `routing`

| Value | Bootstrap |
|-------|-----------|
| `go_router` | `lib/app/router/app_router.dart` with `GoRouter` stub |
| `auto_route` | `@AutoRouterConfig` stub (codegen deps not added automatically) |
| `none` | No router file (flavor mains still work if enabled) |

### `dependency_injection`

Documented in config: `get_it`, `injectable`, `riverpod`, or `none`. DI wiring is left for your team to connect.

## Flavor entrypoints

When `bootstrap.flavor_mains` is true, the setup wizard creates one Dart entrypoint per environment name from your plan, e.g.:

```text
lib/main_dev.dart
lib/main_staging.dart
lib/main_prod.dart
```

Run with:

```bash
flutter run -t lib/main_prod.dart --dart-define=APP_ENV=prod
```

Environment names come from `environments` in config (e.g. `dev`, `staging`, `prod`).

## Test mirror

When `bootstrap.scaffold_test_mirror` is true, `make_feature` (and Feature Studio apply) creates test stubs mirroring scaffolded `.dart` files:

```text
lib/features/auth/presentation/pages/auth_page.dart
test/lib/features/auth/presentation/pages/auth_page_test.dart
```

Each stub contains a minimal `flutter_test` `main()` with a TODO.

## Micro-feature monorepo

Preset `micro_feature` bootstraps:

```text
melos.yaml
apps/shell/pubspec.yaml
apps/shell/lib/main.dart
packages/
```

Scaffolding a feature creates `packages/<feature>/` with clean-arch folders under `lib/src/`.

## Custom JSON template

For preset `custom`, provide `custom_template_path` or inline `custom_template` in config.

Example: [`templates/architecture/custom_feature.example.json`](../templates/architecture/custom_feature.example.json)

Supported variables:

| Variable | Example (`ride_history`) |
|----------|--------------------------|
| `{{feature}}` | `ride_history` |
| `{{feature_snake}}` | `ride_history` |
| `{{prefix}}` | `ride_history_` |
| `{{Prefix}}` | `RideHistory` |

```json
{
  "feature_base_path": "lib/features/{{feature}}",
  "directories": ["domain", "data", "presentation/pages"],
  "files": ["presentation/pages/{{prefix}}page.dart"]
}
```

## CLI usage

```bash
# Scaffold using config preset
dart run :make_feature --project . --feature billing

# Override preset for one scaffold (Feature Studio or API)
dart run :make_feature --project . --feature auth --dry-run

# Bootstrap architecture folders only (via setup wizard apply)
dart run :setup_project --project .
```

## Compatibility warnings

Setup Studio shows a warning when the chosen **state management** conflicts with the preset (e.g. `redux` preset with `bloc`). Warnings are advisory — you can still apply.

## See also

- [Architecture audit](architecture-audit.md) — detect drift and import violations
- [Feature scaffolding](feature-scaffolding.md) — `make_feature` details
- [Configuration](configuration.md) — full config reference
