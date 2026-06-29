# Flutter Project Setup Toolkit — desktop app

The `studio_app/` package is a thin **macOS** shell that loads the Flutter Project Setup Toolkit web UI in a native window.

## Prerequisites

- Flutter SDK with macOS desktop enabled
- Run commands from the **flutter-project-setup-toolkit** repository root (where `studio_app/` lives)

## Launch

```bash
cd flutter-project-setup-toolkit
./scripts/toolkit-studio.sh
```

On macOS the **desktop app** opens by default. The project picker appears first — no `--project` required.

Use `./scripts/toolkit-studio.sh --browser` to open in a web browser instead.

On first launch the macOS app will:

1. **Open without a project** — you are always sent to the project picker first
2. **Check the device environment** — Dart, Flutter, and Xcode (for iOS builds)
3. **Let you pick, repair, or create a project**:
   - **Compatible** Flutter folder → continue to studio
   - **Incomplete structure** → repair with `flutter create` (requires Flutter on the machine)
   - **Not a Flutter project** → create a new one with `flutter create` (Flutter required)

### Deep links

```bash
./scripts/toolkit-studio.sh --desktop --view setup
./scripts/toolkit-studio.sh --desktop --view build
./scripts/toolkit-studio.sh --desktop --view feature
./scripts/toolkit-studio.sh --desktop --view version
./scripts/toolkit-studio.sh --desktop --view quick-test
```

See [toolkit-studio.md](toolkit-studio.md) for all studios and API routes.

### Browser mode (default)

```bash
./scripts/toolkit-studio.sh --project /path/to/your_flutter_app
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `Desktop app not found at studio_app/` | Run from toolkit repo root, not from your Flutter app |
| Blank window / "Waiting for studio server" | Ensure port 8765 is free; try `--port 8766` |
| `flutter` not found | Install Flutter and ensure it is on `PATH` |
| WebView sandbox errors | Rebuild after entitlements change: `cd studio_app && flutter clean && flutter run -d macos` |

See also [doc/troubleshooting.md](troubleshooting.md) for general toolkit issues.
