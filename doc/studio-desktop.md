# Flutter Project Setup Toolkit — desktop app

The `studio_app/` package is a thin **desktop shell** (macOS and Windows) that loads the Flutter Project Setup Toolkit web UI in a native window.

## Prerequisites

- Flutter SDK with macOS and/or Windows desktop enabled
- Run commands from the **flutter-project-setup-toolkit** repository root (where `studio_app/` lives)

## Launch

```bash
cd flutter-project-setup-toolkit
./scripts/toolkit-studio.sh
```

On macOS the **desktop app** opens by default. The project picker appears first — no `--project` required.

Use `./scripts/toolkit-studio.sh --browser` to open in a web browser instead.

On Windows, run the Studio server in the browser until a Windows desktop shell is packaged for release:

```bash
dart run :toolkit_studio --browser
```

### macOS entry point

The macOS shell uses `lib/main_darwin.dart` (WebKit WebView init). CI and local release builds:

```bash
cd studio_app
flutter build macos --release -t lib/main_darwin.dart
```

Windows uses the default `lib/main.dart`.

## CI desktop builds

On every push to `main`, GitHub Actions builds **macOS** and **Windows** release artifacts from `studio_app/` (workflow: `.github/workflows/desktop-build.yml`). Download artifacts from the Actions tab for smoke testing.

## CI mobile builds

On every push to `main`, GitHub Actions also builds the **Quick Test companion** for **Android** (release APK) and **iOS** (unsigned release `.app`, workflow: `.github/workflows/mobile-build.yml`). Download artifacts from the Actions tab for smoke testing.

```bash
# Local equivalents
cd studio_app
flutter build apk --release
flutter build ios --release --no-codesign
```

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

## Mobile Quick Test companion

The same `studio_app/` package runs on **Android and iOS** as a native Quick Test client. Your Mac stays the build host.

```bash
# Mac (build host)
./scripts/toolkit-studio.sh --host lan

# Phone (same WiFi)
cd studio_app && flutter run
```

1. Enter the Mac LAN IP shown at startup
2. Paste a Git repo URL and tap **Build & install on this device**
3. Android downloads the APK over WiFi and opens the system installer
4. iOS shows TestFlight/USB guidance (WiFi sideload is not supported)

See [toolkit-studio.md](toolkit-studio.md#mobile-companion-android--ios) for API details.

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
