#!/usr/bin/env bash
#
# Flutter Project Setup Toolkit — release Android APK or AAB
#
# Runs flutter build apk/appbundle with --dart-define-from-file from your env.
#
# Run from: toolkit repo root OR your Flutter app root (with RTK_PROJECT set).
#
# Prerequisites:
#   - Flutter SDK (or FVM on PATH)
#   - Android SDK, signing configured in the Flutter project
#
# Usage:
#   ./scripts/build-android.sh [OPTIONS]
#
# Examples:
#   ./scripts/build-android.sh --project /path/to/app --env prod
#   ./scripts/build-android.sh --project . --env-file .env/production.env
#   ./scripts/build-android.sh --project . --env prod --aab
#   ./scripts/build-android.sh --project . --env staging --flavor staging
#   SKIP_CONFIRM=true ./scripts/build-android.sh --project . --env prod
#
# Environment:
#   RTK_PROJECT      Flutter app root
#   ENV_FILE         Explicit env file path
#   SKIP_CONFIRM     Skip build confirmation (true in CI)
#   BUILD_FORMAT     apk | aab
#   ANDROID_FLAVOR   Product flavor
#   FLUTTER_CMD      e.g. "fvm flutter"
#
# Common options:
#   --project, -p PATH   Flutter project root
#   --env NAME           Named environment from release-toolkit.config.json
#   --env-file PATH      Explicit dart-define env file
#   --aab                Build App Bundle (Google Play) instead of APK
#   --flavor NAME        Android product flavor
#
# Help:
#   dart run :build_android --help
#
set -euo pipefail
TOOLKIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARGS=("$@")
cd "$TOOLKIT_ROOT"
if ((${#ARGS[@]} > 0)); then
  exec dart run :build_android "${ARGS[@]}"
fi
exec dart run :build_android
