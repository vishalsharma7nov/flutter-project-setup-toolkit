# Resolves flutter-project-setup-toolkit install path.
#
# Usage (from another script):
#   source "$(dirname "$0")/rtk-locate.sh"   # if using app scripts/
#   # or:
#   source "$FLUTTER_PROJECT_SETUP_TOOLKIT/lib/sh/locate-toolkit.sh"
#   _rtk_locate_toolkit "$APP_ROOT" || exit 1
#
# Sets RTK_ROOT on success. Override search path:
#   export FLUTTER_PROJECT_SETUP_TOOLKIT=/path/to/flutter-project-setup-toolkit

_rtk_locate_toolkit() {
  local toolkit_root="${FLUTTER_PROJECT_SETUP_TOOLKIT:-${FLUTTER_RELEASE_TOOLKIT:-}}"
  if [[ -n "$toolkit_root" && -f "$toolkit_root/scripts/classify-version-bump.sh" ]]; then
    RTK_ROOT="$(cd "$toolkit_root" && pwd)"
    return 0
  fi

  local here="${1:-.}"
  local documents="${HOME}/Documents/flutter-project-setup-toolkit"
  local candidates=(
    "$documents"
    "$here/flutter-project-setup-toolkit"
    "$here/../flutter-project-setup-toolkit"
    "$here/../../flutter-project-setup-toolkit"
    "$here/flutter-release-toolkit"
    "$here/../flutter-release-toolkit"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -f "$candidate/scripts/classify-version-bump.sh" ]]; then
      RTK_ROOT="$(cd "$candidate" && pwd)"
      return 0
    fi
  done

  echo "flutter-project-setup-toolkit not found." >&2
  echo "Set FLUTTER_PROJECT_SETUP_TOOLKIT to the toolkit root, or clone it beside this app." >&2
  echo "Typical locations: ~/Documents/flutter-project-setup-toolkit, ../flutter-project-setup-toolkit" >&2
  return 1
}
