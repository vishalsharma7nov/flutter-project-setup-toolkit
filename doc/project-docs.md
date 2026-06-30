# Project Docs Studio

**Docs Studio** scans a Flutter project and generates a complete documentation set: root `README.md`, a `doc/` index, and focused guides for getting started, architecture, features, configuration, development, building, and testing.

Open it from Toolkit Studio:

```bash
dart run :toolkit_studio
# Hub → Project documentation  (/docs)

# Or deep link
dart run :toolkit_studio --view docs --project /path/to/app
```

## What it generates

| File | Purpose |
|------|---------|
| `README.md` | Overview, quick start, platforms, feature summary |
| `doc/README.md` | Documentation index |
| `doc/getting-started.md` | Prerequisites, env files, project health |
| `doc/architecture.md` | Preset, layers, audit issues |
| `doc/features.md` | Modules, screens, routes |
| `doc/configuration.md` | `release-toolkit.config.json` reference |
| `doc/development.md` | Analyze, test, scaffold features |
| `doc/building.md` | Release builds and CI hints |
| `doc/testing.md` | Test inventory and smoke checklist |

Content is **deterministic** — built from static analysis (`codebase_snapshot`, architecture audit, project doctor, toolkit config), not LLM output.

## Studio workflow

1. **Scan project** — detect missing docs, architecture preset, module count.
2. **Preview** — review each file; see diffs when a file already exists.
3. **Write** — save selected files with your chosen overwrite policy.

### Overwrite policies

| Policy | Behavior |
|--------|----------|
| **Skip existing** (default) | Only write files that do not exist yet |
| **Refresh toolkit-generated** | Overwrite files that contain the Docs Studio marker |
| **Overwrite all** | Replace all selected files |

If `README.md` has substantial custom content (>40 non-empty lines, no toolkit marker), it is skipped by default. Use **Overwrite all** to replace it.

## API routes

| Method | Path | Description |
|--------|------|-------------|
| GET | `/docs` | Docs Studio page |
| GET | `/api/docs/detect?path=` | Scan project and list missing docs |
| POST | `/api/docs/preview` | Preview generated files + diffs |
| POST | `/api/docs/write` | Write documentation to disk |

Preview/write body:

```json
{
  "path": "/path/to/flutter/app",
  "spec": {
    "include_readme": true,
    "include_architecture": true,
    "overwrite_policy": "skipExisting"
  }
}
```

## CLI

```bash
# Open Docs Studio in browser
dart run :project_docs --project .

# Preview (text)
dart run :project_docs --project . --preview

# Preview (JSON)
dart run :project_docs --project . --preview --format json

# Write missing docs only
dart run :project_docs --project . --write

# Refresh toolkit-generated docs
dart run :project_docs --project . --write --overwrite refreshGenerated

# Replace all selected files
dart run :project_docs --project . --write --overwrite overwriteAll
```

## Related studios

- **Setup Studio** — generate `release-toolkit.config.json` before writing configuration docs
- **CI Studio** — generates `doc/ci-setup.md` for GitHub Actions separately
- **QA Release Notes** — commit handoff docs for QA teams (not project reference docs)
