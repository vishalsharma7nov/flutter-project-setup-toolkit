# QA release notes

**QA Release Notes Studio** compares the latest git commit with the previous one (or since the last tag) and generates a handoff document for your QA team.

Open it from Toolkit Studio:

```bash
dart run :toolkit_studio
# Hub → QA release notes  (/qa)
```

## What it compares

| Mode | Range | When to use |
|------|-------|-------------|
| **HEAD~1 → HEAD** (default) | Previous commit vs latest | Daily smoke / per-commit QA |
| **Last tag → HEAD** | Since last git tag | Release-candidate handoff |

Requires a local `.git` directory with **at least two commits**.

## Studio features

- **Preview** — Markdown handoff in the browser
- **Copy** — clipboard for Slack/Teams
- **Download** — Markdown, CSV, JSON, HTML, XLSX, Confluence wiki, Jira comment, TestRail/Tuskr CSV, regression matrix, email `.eml`
- **Summary cards** — time estimate, risk, platforms, Go/No-Go hint
- **Quick Test link** — jump to `/quick-test` for the same commit
- **Audience modes** — QA (full), PM summary, Executive one-pager

### API routes

| Method | Path | Description |
|--------|------|-------------|
| GET | `/qa` | QA Release Notes Studio page |
| POST | `/api/qa/preview` | Generate handoff JSON + Markdown |
| GET | `/api/qa/download` | Download export (`format=md\|csv\|json\|html\|xlsx\|…`) |
| GET | `/api/qa/compare-options` | Available compare ranges for project |

Preview body: `{ "project": "/path", "base_mode": "head~1", "audience": "qa" }`

## CLI (CI artifact)

```bash
dart run :qa_release_notes --project . --format json --output qa-handoff.json
dart run :qa_release_notes --project . --format md
dart run :qa_release_notes --project . --base-mode last_tag --format xlsx --output qa-handoff.xlsx
```

### GitHub Actions example

```yaml
- name: QA handoff artifact
  run: dart run flutter_project_setup_toolkit:qa_release_notes --project . --format json --output qa-handoff.json
- uses: actions/upload-artifact@v4
  with:
    name: qa-handoff
    path: qa-handoff.json
```

## Document sections

The QA template includes:

1. Compare header (shas, author, date, optional GitHub compare / PR links)
2. At-a-glance — time estimate, risk, Go/No-Go, platforms
3. Summary and semver impact (reuses version classification)
4. Suggested checklist and manual verification table
5. Screenshot checklist for UI file changes
6. Ticket traceability (`PROJ-123` in commit message)
7. Files changed grouped by area (Features, Platform, Config, …)
8. Sign-off block

## Compare modes

| Mode | When |
|------|------|
| **HEAD~1 → HEAD** | Normal per-commit QA when git history exists |
| **Last tag → HEAD** | Release-candidate handoff |
| **Codebase scan** | No git, single commit, or unknown history — infers purpose from code layout |

When git compare is unavailable, Toolkit **automatically falls back** to a codebase scan.

## Code understanding CLI

Scan a project without generating a full QA doc:

```bash
dart run :codebase_understand --project .
dart run :codebase_understand --project . --format json
```

This reports inferred modules, screens, routes, dependencies, and platforms.

Force codebase-only QA handoff:

```bash
dart run :qa_release_notes --project . --base-mode codebase --format md
```

## Limitations

- Local git only for commit compare — remote-only projects use **codebase scan**
- Code understanding is heuristic (folder names, pubspec, README) — not AI analysis
- PR links require `gh` CLI and network (optional)
- HTML export is print-friendly; use browser **Print → PDF** instead of a native PDF library
- Version context appears when `release-toolkit.config.json` exists

## See also

- [Toolkit Studio](toolkit-studio.md)
- [Version classification](versioning.md)
