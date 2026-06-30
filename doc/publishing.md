# Publishing

How to publish **flutter_project_setup_toolkit** to GitHub and pub.dev.

## GitHub repository

### 1. Create the repository

Create a new GitHub repository (e.g. `flutter-project-setup-toolkit` or `flutter-project-setup-toolkit`).

### 2. Repository URLs

Metadata points to [github.com/vishalsharma7nov/flutter-project-setup-toolkit](https://github.com/vishalsharma7nov/flutter-project-setup-toolkit) in:

- `pubspec.yaml` — `repository`, `homepage`, `issue_tracker`
- `README.md` — clone URLs and links
- `release-toolkit.config.example.json` — `$schema` URL

### 3. Push

Push this directory as the **repository root** (not nested inside another app):

```bash
git init
git add .
git commit -m "Initial release: Flutter Project Setup Toolkit"
git remote add origin git@github.com:vishalsharma7nov/flutter-project-setup-toolkit.git
git branch -M main
git push -u origin main
```

### 4. Tag releases

```bash
git tag v0.2.0
git push origin v0.2.0
```

Create a GitHub release from the tag (optional):

```bash
gh release create v0.2.0 --title "v0.2.0" --notes-file CHANGELOG.md
```

Consumers can depend via git:

```yaml
dev_dependencies:
  flutter_project_setup_toolkit:
    git:
      url: https://github.com/vishalsharma7nov/flutter-project-setup-toolkit.git
      ref: v0.2.0
```

### 5. GitHub project README

The root [README.md](../README.md) is the landing page. Link the **Documentation** section in your repo About/description:

> Dart toolkit for Flutter setup, architecture scaffolding, release builds, and version workflows. [Full docs](doc/README.md)

Recommended repo topics: `flutter`, `dart`, `cli`, `devtools`, `release-automation`, `clean-architecture`.

### 6. What to include / exclude

**Include:**

- `lib/`, `bin/`, `doc/`, `scripts/`, `templates/`, `studio_app/`
- `README.md`, `CHANGELOG.md`, `LICENSE`, `release-toolkit.config.example.json`
- `pubspec.yaml`, `analysis_options.yaml`

**Exclude** (via `.gitignore`):

- `.dart_tool/`, `build/`, local secrets, `.env` files with real keys
- Consumer app configs

---

## pub.dev

### Prerequisites

- [pub.dev account](https://pub.dev/)
- `dart pub login`
- Package passes `dart analyze` and `dart test`
- Valid `repository` and `homepage` URLs in `pubspec.yaml`

### Dry run

```bash
cd flutter-project-setup-toolkit
dart pub publish --dry-run
```

Review the file list. Do not publish secrets or build artifacts.

### Publish

```bash
dart pub publish
```

### Version bumps

1. Update `version:` in `pubspec.yaml` (semver)
2. Add entry to [CHANGELOG.md](../CHANGELOG.md)
3. Tag git: `git tag v0.2.0 && git push origin v0.2.0`

### Consumer install

After publish:

```bash
dart pub global activate flutter_project_setup_toolkit
toolkit_studio
```

Or as a dev dependency:

```yaml
dev_dependencies:
  flutter_project_setup_toolkit: ^0.2.0
```

## See also

- [Documentation index](README.md)
- [Multiple apps](multi-app-setup.md)
