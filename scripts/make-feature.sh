#!/usr/bin/env bash
#
# Flutter Project Setup Toolkit — scaffold a feature module
#
# Creates folder structure for a new feature (architecture preset from
# release-toolkit.config.json in the target project).
#
# Run from: toolkit repo root OR your Flutter app root (with RTK_PROJECT set).
#
# Prerequisites:
#   - Dart SDK
#   - Flutter project at --project path (pubspec.yaml + lib/)
#
# Usage:
#   ./scripts/make-feature.sh [OPTIONS] [FEATURE_NAME]
#
# Examples:
#   cd /path/to/my_app && RTK_PROJECT=. ../flutter-project-setup-toolkit/scripts/make-feature.sh auth
#   ./scripts/make-feature.sh --project /path/to/my_app --feature ride_history
#   ./scripts/make-feature.sh --project . --feature settings --base-path lib/modules
#   ./scripts/make-feature.sh --project . --feature billing --dry-run
#
# Environment:
#   RTK_PROJECT   Flutter app root (default: current directory)
#
# Options (passed to make_feature):
#   --project, -p PATH      Flutter project root
#   --feature, -f NAME      Feature folder name
#   --base-path PATH        Override lib/features (default from config)
#   --state-management T    bloc | riverpod | provider | getx | none
#   --dry-run               Preview paths only
#   --yes, -y               Skip prompts (requires --feature)
#   --gui                   Open Feature Studio in Toolkit Studio
#
# Help:
#   dart run :make_feature --help
#
set -euo pipefail

TOOLKIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT="${RTK_PROJECT:-$(pwd)}"

cd "$TOOLKIT_ROOT"
exec dart run :make_feature --project "$PROJECT" "$@"
