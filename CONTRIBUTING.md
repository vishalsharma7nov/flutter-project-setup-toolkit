# Contributing

Thanks for helping improve **Flutter Project Setup Toolkit**.

## Development setup

```bash
git clone https://github.com/vishalsharma7nov/flutter-project-setup-toolkit.git
cd flutter-project-setup-toolkit
dart pub get
```

## Running checks locally

```bash
dart analyze --fatal-infos
dart test
dart pub publish --dry-run
```

## Toolkit Studio

```bash
dart run :toolkit_studio
# or on macOS:
./scripts/toolkit-studio.sh
```

Restart Studio after editing HTML under `lib/src/studio/`.

## Documentation

- User docs live in [`doc/`](doc/README.md).
- Update the relevant guide when you add CLI flags, config keys, or Studio routes.
- Add a short note to [`CHANGELOG.md`](CHANGELOG.md) under **Unreleased**.

## Pull requests

1. Branch from `main`.
2. Keep changes focused; match existing code style.
3. Add or update tests for behavior changes.
4. Ensure CI passes (`dart analyze`, `dart test`, `dart pub publish --dry-run`).

## Reporting issues

Use the GitHub issue templates for bugs and feature requests.
