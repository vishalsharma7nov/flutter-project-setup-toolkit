# Architecture audit

Detect layout mismatches and architecture violations in an existing Flutter project.

## CLI

```bash
dart run :architecture_audit --project /path/to/app
dart run :architecture_audit /path/to/app --json
```

Or after global install:

```bash
architecture_audit --project .
```

### Exit codes

| Code | Meaning |
|------|---------|
| `0` | No error-severity issues |
| `1` | At least one error (e.g. cross-feature data import) |
| `64` | Invalid project path / not a Flutter app |

### Human-readable output

```
Architecture audit: /path/to/app
Configured preset: feature_first_clean
Detected preset: feature_first_clean (80% confidence)
No issues found.
```

When drift is detected:

```
Drift: configured preset differs from detected layout
Issues:
  [warn] preset_drift: Config preset is simple but layout suggests feature_first_clean
  [error] cross_feature_data_import: Presentation imports another feature's data layer (billing) [lib/features/auth/presentation/auth_screen.dart]
```

### JSON output

```bash
dart run :architecture_audit --project . --json
```

```json
{
  "project_path": "/path/to/app",
  "configured_preset": "feature_first_clean",
  "detection": {
    "suggested_preset": "feature_first_clean",
    "confidence": 0.8,
    "signals": ["feature-first clean layers in auth"],
    "drift": false,
    "matches_config": true
  },
  "issues": [],
  "issue_count": 0
}
```

## What is checked

### Preset detection (heuristics)

Scans `lib/` (and repo root for monorepo signals):

| Signal | Suggests |
|--------|----------|
| `packages/` + `melos.yaml` | `micro_feature` |
| `lib/modules/` | `getx_module` |
| `lib/ui/` | `compass_mvvm` |
| `lib/store/` | `redux` |
| `lib/features/*/data` + `domain` | `feature_first_clean` |
| `lib/features/*/screens` | `simple` |
| `lib/features/*/viewmodels` | `mvvm` |
| Top-level `lib/data` + `lib/presentation` | `layer_first_clean` |

Confidence is the winning score divided by total signals. **Drift** is reported when configured preset in `release-toolkit.config.json` differs from detection and confidence ≥ 45%.

### Cross-feature data imports

Flags **errors** when a feature's `presentation/` layer imports another feature's `data/` layer (package or relative imports). This enforces clean-arch boundaries between features.

## Studio API

Available when Toolkit Studio is running:

```http
GET /api/setup/architecture/detect?path=/path/to/app
GET /api/setup/architecture/audit?path=/path/to/app
```

Aliases:

- `/api/architecture/detect`
- `/api/architecture/audit`

Response bodies match the CLI JSON structures.

## CI integration

```yaml
- name: Architecture audit
  run: |
    dart pub global activate flutter_project_setup_toolkit
    architecture_audit --project "${{ github.workspace }}"
```

Fail the job on exit code `1` to block merges with cross-feature data imports.

## See also

- [Architecture presets](architecture.md)
- [Configuration](configuration.md)
