#!/usr/bin/env bash
#
# Flutter Project Setup Toolkit — classify semver bump from git
#
# Inspects the latest commit (or a given ref) and suggests major/minor/patch.
# Optionally writes Android/iOS version keys to env files.
#
# Run from: toolkit repo root OR your Flutter app root (with RTK_PROJECT set).
#
# Prerequisites:
#   - Dart SDK, Git
#   - Flutter project with release-toolkit.config.json (or --env-file)
#
# Usage:
#   ./scripts/classify-version-bump.sh [OPTIONS] [COMMIT]
#
# Examples:
#   ./scripts/classify-version-bump.sh --project /path/to/app --verbose
#   ./scripts/classify-version-bump.sh --project . --env prod --suggest --verbose
#   ./scripts/classify-version-bump.sh --project . --env prod --apply-env --dry-run
#   ./scripts/classify-version-bump.sh --project . --env prod --apply-env --yes
#   RTK_PROJECT=/path/to/app ./scripts/classify-version-bump.sh --env both --suggest
#
# Environment:
#   RTK_PROJECT     Flutter app root
#   SKIP_CONFIRM    Skip apply confirmation when set to true
#
# Common options:
#   --project, -p PATH   Flutter project root
#   --env NAME           dev | prod | both (from config)
#   --env-file PATH      Single env file (no config required)
#   --suggest            Print suggested next version numbers
#   --apply-env          Write version keys to env file(s)
#   --dry-run            Preview changes without writing
#   --verbose, -v        Show classification reasons
#   --json               Machine-readable output
#   --yes, -y            Skip confirmation prompts
#
# Help:
#   dart run :classify_version_bump --help
#
set -euo pipefail
TOOLKIT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARGS=("$@")
cd "$TOOLKIT_ROOT"
if ((${#ARGS[@]} > 0)); then
  exec dart run :classify_version_bump "${ARGS[@]}"
fi
exec dart run :classify_version_bump
