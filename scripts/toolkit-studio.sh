#!/usr/bin/env bash
#
# Flutter Project Setup Toolkit — Studio hub (GUI)
#
# Opens the local Toolkit Studio dashboard: setup, builds, Quick Test,
# feature scaffolding, packages, CI, QA, docs, and version bumps.
#
# Run from: toolkit repo root (this file lives in scripts/).
#
# Prerequisites:
#   - Dart SDK (dart pub get in toolkit root)
#   - Flutter SDK optional (needed for build / Quick Test studios)
#
# Usage:
#   ./scripts/toolkit-studio.sh [OPTIONS]
#
# Examples:
#   ./scripts/toolkit-studio.sh
#   ./scripts/toolkit-studio.sh --browser
#   ./scripts/toolkit-studio.sh --project /path/to/flutter_app
#   ./scripts/toolkit-studio.sh --host lan --view quick-test
#   ./scripts/toolkit-studio.sh --view setup --port 8767
#
# Options (passed to dart run :toolkit_studio):
#   --project, -p PATH   Pre-fill Flutter project in the UI
#   --view VIEW          setup | build | feature | version | quick-test | ci | qa | docs | packages | doctor
#   --browser            Web UI instead of macOS desktop app
#   --desktop            Force macOS desktop app
#   --host HOST          loopback (default) or lan (mobile companion)
#   --port PORT          HTTP port (default: 8765)
#   --no-browser         Start server without opening a window/tab
#
# macOS: desktop app is the default. Use --browser for a web tab.
#
# Help:
#   dart run :toolkit_studio --help
#
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
exec dart run :toolkit_studio "$@"
