# Changelog

All notable changes to **flutter_project_setup_toolkit**.

## Unreleased

### Added

- **Native folder picker** — `/api/pick-folder` on macOS, Windows, and Linux (zenity/kdialog); hub and Quick Test **Browse…**
- **Quick Test local folder** — build from a project on disk without cloning Git
- **Multi-provider CI** — GitLab CI, Codemagic, CircleCI, Azure Pipelines, Bitbucket Pipelines templates in CI Studio

## 0.2.0 — 2026-06-30

### Added

- **CI Studio** — `/ci` GUI and `ci_studio` CLI: GitHub Actions workflow generation, local act tests, PR publish
- **QA Release Notes Studio** — `/qa` GUI and `qa_release_notes` CLI; `codebase_understand` for heuristic scans
- **Package Studio** — `/packages` GUI: pub.dev search, Git URL validation, `flutter pub add`
- **Project Docs Studio** — `/docs` GUI and `project_docs` CLI: generate README and `doc/` guides
- **Project Doctor** — `/doctor` GUI: config, env, signing, and architecture health checks
- **Phase 7 — Architecture backlog**
  - Core module stubs (`errors`, `logging`, `theme`, `connectivity`) under `lib/core/`
  - Flavor entrypoints (`main_<env>.dart`) from setup environments
  - Test mirror — `test/` stubs when scaffolding features
  - `architecture_audit` CLI and Studio APIs (`/api/setup/architecture/detect`, `/audit`)
  - Architecture layout detection and preset drift reporting
  - Setup Studio toggles for core modules, flavor mains, test mirror
- **Tier 2–3 architecture presets** — `mvvm`, `mvc`, `mvi`, `redux`, `hexagonal`, `bloc_centric`, `riverpod_first`, `getx_module`, `stacked`
- **Tier 4 architecture** — `micro_feature` (melos monorepo), `custom` JSON templates
- **Quick Test Studio** — `/quick-test` GUI: Git clone → build APK/IPA → install on connected devices (`adb` / `flutter install`)
- **Version Studio** — `/version` UI, classify preview/apply APIs
- **Distribution Studio** — Android AAB, cancel build, secure env overlay, Git remote builds
- **Feature Studio** — external SDK fields, save config API
- **Toolkit Studio hub** — unified project picker and studio navigation
- **macOS desktop app** — native shell for Toolkit Studio
- Documentation: [doc/ci-studio.md](doc/ci-studio.md), [doc/qa-release-notes.md](doc/qa-release-notes.md), [doc/package-studio.md](doc/package-studio.md), [doc/project-docs.md](doc/project-docs.md), [doc/architecture.md](doc/architecture.md), [doc/toolkit-studio.md](doc/toolkit-studio.md), [doc/architecture-audit.md](doc/architecture-audit.md), and more

### Changed

- Package renamed to `flutter_project_setup_toolkit`
- **Dart-only** runtime
- Setup Studio supports all architecture tiers and compatibility warnings

### Removed

- `RTK_RUNTIME` environment variable

## 0.1.0 — 2026-06-29

### Added

- `setup_project` wizard — environments, env files, config, scripts
- `default_environment` in `release-toolkit.config.json`
- Dart package with executables: `classify_version_bump`, `build_android`, `build_ios_ipa`, `make_feature`
- `make-feature.sh` scaffold for clean-architecture features
- `dart test` suite
- Initial documentation and [doc/publishing.md](doc/publishing.md)
