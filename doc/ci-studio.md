# CI Studio

CI Studio generates GitHub Actions workflows from your `release-toolkit.config.json`, runs local smoke tests, and publishes to GitHub only after a green test.

## Quick start

```bash
# Open CI Studio in the browser
dart run :toolkit_studio --view ci --project /path/to/flutter/app

# Or use the dedicated CLI
dart run :ci_studio --project .
```

From the hub: load a Flutter project, then open **CI/CD** (`/ci`).

## DevOps minimal setup

What a DevOps engineer needs on their machine to work on CI for a Flutter project in this toolkit:

### Required (minimal)

| Tool | Purpose |
|------|---------|
| **Dart SDK** | Run CI Studio and toolkit commands |
| **Git** | Version control and publish branch |
| **Flutter SDK** | Native smoke test (`analyze`, `test`, optional builds) |
| **`release-toolkit.config.json`** | Env names, flavors, schemes for generated workflows |

With only these, DevOps can **configure → write workflow → native smoke test**.

### Required to publish

| Tool | Purpose |
|------|---------|
| **GitHub `origin` remote** | Target repo for the workflow PR |
| **`gh` CLI + `gh auth login`** | Open pull request after green test |

### Recommended (depends on jobs)

| Item | When |
|------|------|
| **`android/key.properties`** | Android AAB release builds |
| **macOS + Xcode** | Local iOS IPA test (GitHub `macos-latest` works in CI without local Xcode) |

### Optional (currently disabled)

act + Docker workflow testing is implemented but **hidden for now**. Use **native smoke test** as the local gate before publish. To re-enable later, set `ciActStudioEnabled = true` in `lib/src/ci/ci_features.dart`.

<!--
### act (on demand) — re-enable via ciActStudioEnabled

CI Studio downloads act automatically when you click **Run with act**, runs the ubuntu job, then removes the binary.

Requirements: Docker Desktop (macOS/Linux).
-->

### Bootstrap commands

```bash
git clone git@github.com:ORG/REPO.git && cd REPO
dart --version && flutter --version && flutter doctor
dart run :toolkit_studio --view ci --project .
gh auth login   # when ready to publish
dart run :ci_studio --project . --write --test
```

CI Studio **DevOps setup** panel in `/ci` shows Required / Publish / Recommended checks live for your project.

## Workflow

1. **Configure** — pick a preset (PR checks, release, full split, cost-conscious), toggle jobs, preview YAML.
2. **Write & test** — save `.github/workflows/*.yml` locally, then run a **native smoke test**.
3. **Publish** — after a passing test, commit and open a pull request via `gh pr create`.

Publish is **blocked** until the most recent local test reports `passed`.

## Presets

| Preset | Files | Best for |
|--------|-------|----------|
| **PR checks** | `flutter-release.yml` | Analyze, format, architecture audit on PRs |
| **Release** | `flutter-release.yml` | AAB + IPA on main / manual dispatch |
| **Full** | `flutter-ci.yml` + `flutter-release.yml` | Split CI (ubuntu) vs release (macOS) |
| **Cost-conscious weekly ship** | Split | PR checks + release builds without tag triggers |

## Local testing

### Native smoke test

Runs equivalent steps on your machine:

- `flutter pub get`, `dart analyze`, `dart test`
- `dart format --set-exit-if-changed .` (when enabled)
- `dart run :architecture_audit`
- Optional `flutter build appbundle` / `flutter build ipa` (iOS requires macOS + Xcode)

```bash
dart run :ci_studio --project . --write --test
```

### act (disabled — code retained)

act + Docker testing is **off by default** (`ciActStudioEnabled = false` in `ci_features.dart`). Native smoke test is the supported local gate. See git history / `ci_act_installer.dart` when re-enabling.

<!--
Previous act docs (re-enable with ciActStudioEnabled):

CI Studio downloads act automatically when you click **Run with act**…
Requirements: Docker Desktop (macOS/Linux).
-->

## GitHub secrets

After generating workflows, add repository secrets in **Settings → Secrets and variables → Actions**:

| Secret | Required | Purpose |
|--------|----------|---------|
| `ENV_FILE` | Yes (release builds) | Full env file contents for `--dart-define-from-file` |
| `ANDROID_KEYSTORE_BASE64` | Optional | Release signing |
| `MATCH_PASSWORD` | Optional | Fastlane Match for iOS |
| `APP_STORE_CONNECT_API_KEY` | Optional | TestFlight upload |

Never commit real secrets. CI Studio shows a checklist but does not write secrets to the repo.

## Publish requirements

- Git repo with GitHub `origin`
- `gh auth login` completed
- Local smoke test passed
- Workflow file written locally

Publish creates branch `rtk/ci-workflow` (when on main/master) and opens a PR with a secrets checklist.

## Setup Studio integration

Enable **Generate GitHub Actions CI workflow** during setup, or run CI Studio after setup completes.

Terminal wizard:

```bash
dart run :setup_project
# Prompt: "Generate GitHub Actions CI workflow?"
```

## Project Doctor

Doctor reports an info check when no `.github/workflows/` YAML exists, with a link to CI Studio.

## Headless CLI

```bash
dart run :ci_studio --project . --preset full --write
dart run :ci_studio --project . --test          # exit 0/1
dart run :ci_studio --project . --write --test --publish
```

## Generated artifacts

- `.github/workflows/flutter-ci.yml` — PR quality gates (split mode)
- `.github/workflows/flutter-release.yml` — release builds
- `CI_SETUP.md` — teammate onboarding (secrets + jobs)
- `.act.secrets.example` — act secrets template
- `fastlane/Fastfile` — stub upload lanes (when Android/iOS jobs enabled)

## Distribution lanes (optional)

Enable **Firebase App Distribution stub** in CI Studio to generate a Fastlane `firebase` lane and a workflow stub job. Configure `FIREBASE_SERVICE_ACCOUNT` in GitHub secrets before use.

Store upload (Play internal, TestFlight) uses the generated Fastlane stub — fill credentials before enabling upload steps.

## Shorebird OTA (future)

For over-the-air patches without a full store release, see [Shorebird](https://shorebird.dev/). CI Studio does not generate Shorebird jobs in v1 — add a custom workflow step after your release pipeline is stable.

## Hybrid CI strategy

Many teams run **GitHub Actions for PR checks** (ubuntu, fast) and use **Codemagic or other hosted macOS** for iOS release builds to save minutes. CI Studio defaults to GitHub Actions because it fits the `gh pr create` publish flow. Export your generated YAML and hand off iOS jobs to another provider when macOS cost is a concern.

## Troubleshooting

| Failure | Fix |
|---------|-----|
| Java version mismatch on Android | Template pins Java 17 via `actions/setup-java@v4` |
| iOS signing in CI | Configure `MATCH_PASSWORD` and export options; test locally first |
| Format check fails | Run `dart format .` locally before pushing |
| ENV_FILE secret missing | Copy prod env file contents to GitHub secret (never commit the file) |
