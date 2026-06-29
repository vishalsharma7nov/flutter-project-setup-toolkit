#!/usr/bin/env bash
#
# Flutter Project Setup Toolkit — release iOS IPA
#
# Runs flutter build ipa with --dart-define-from-file from your env.
#
# Run from: toolkit repo root OR your Flutter app root (macOS only).
#
# Prerequisites:
#   - macOS, Xcode, CocoaPods
#   - Flutter SDK (or FVM on PATH)
#   - Valid signing & provisioning in Xcode
#
# Usage:
#   ./scripts/build-ios-ipa.sh [OPTIONS]
#
# Examples:
#   ./scripts/build-ios-ipa.sh --project /path/to/app --env prod
#   ./scripts/build-ios-ipa.sh --project . --env-file .env/production.env
#   ./scripts/build-ios-ipa.sh --project . --env prod --scheme Runner
#   ./scripts/build-ios-ipa.sh --project . --env prod --flavor production
#   ./scripts/build-ios-ipa.sh --project . --env prod --no-organizer
#
# Environment:
#   RTK_PROJECT      Flutter app root
#   ENV_FILE         Explicit env file path
#   SKIP_CONFIRM     Skip build confirmation
#   IOS_SCHEME       Xcode scheme (default: Runner)
#   IOS_FLAVOR       Flutter iOS flavor
#   OPEN_ORGANIZER   true | false (open .xcarchive after build)
#
# Common options:
#   --project, -p PATH   Flutter project root
#   --env NAME           Named environment from config
#   --env-file PATH      Explicit dart-define env file
#   --scheme NAME        Xcode scheme
#   --flavor NAME        iOS flavor
#   --no-organizer       Do not open Xcode Organizer after build
#
# Help:
#   dart run :build_ios_ipa --help
#
set -euo pipefail
TOOLKIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARGS=("$@")
cd "$TOOLKIT_ROOT"
if ((${#ARGS[@]} > 0)); then
  exec dart run :build_ios_ipa "${ARGS[@]}"
fi
exec dart run :build_ios_ipa
