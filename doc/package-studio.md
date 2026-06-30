# Package Studio

Search pub.dev and install packages into your loaded Flutter project from Toolkit Studio.

## Open Package Studio

1. Run Toolkit Studio: `dart run :toolkit_studio`
2. Load a Flutter project on the hub (enter path → **Load project**)
3. Click **Add package** (or open `/packages`)

## Search

Type in the **Search pub.dev** field. Results appear after a short debounce and show package name, description, likes, and pub points. Click a result to open the detail panel.

## Paste a link or name

Use **Paste link or package name** for:

- pub.dev URLs: `https://pub.dev/packages/http`
- Version URLs: `https://pub.dev/packages/http/versions/1.2.0`
- Plain names: `flutter_bloc`
- Name with version: `dio:5.4.0`

Click **Resolve** to load package metadata.

## Install

In the detail panel:

1. Optionally pick a specific version (default: latest compatible constraint from pub)
2. Choose **Regular dependency** or **Dev dependency**
3. Click **Install package**

The studio runs the same command you would use locally:

```bash
flutter pub add provider          # Flutter app
flutter pub add --dev mockito     # dev dependency
dart pub add http                 # pure Dart package
```

Install output (command, stdout, stderr) appears in the log panel below.

## Install from GitHub / Git

Switch to the **GitHub / Git** tab (or paste a GitHub URL in the pub.dev resolve field).

1. Enter the **Git repository URL** (`https://github.com/org/my_package`)
2. Set **branch / tag** (default `main`) and optional **monorepo path** (`packages/foo`)
3. Enter the **dependency name** for your `pubspec.yaml` (auto-filled after validation when possible)
4. Click **Validate package** — the studio will:
   - Confirm the repo and ref are reachable (`git ls-remote`)
   - Shallow-clone the repo
   - Check `pubspec.yaml` parses and has a valid package name + SDK constraint
   - Check `lib/` exists with Dart source files
   - Run `dart pub get` or `flutter pub get` in the package to catch broken dependencies
5. When validation passes, click **Install from Git**

```bash
flutter pub add my_package \
  --git-url https://github.com/org/my_package.git \
  --git-ref main \
  --git-path packages/foo   # optional monorepo path
```

Install is blocked until validation succeeds (or the package is already in `pubspec.yaml`).

## Notes

- Requires a loaded project from the hub (same as Feature Studio and CI Studio).
- If the package is already listed in `pubspec.yaml`, install is skipped with a message.
- Search uses the pub.dev API via `pub_api_client`; network access is required for search and detail views.
- Git validation requires `git` on PATH and network access to clone the repository.

## Related

- [Setup wizard](setup-wizard.md) — adds API/state-management packages automatically during setup
- [Toolkit Studio](toolkit-studio.md) — hub overview
