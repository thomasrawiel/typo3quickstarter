#!/usr/bin/env bash
# typo3quickstarter-managed: installed by install.sh
set -euo pipefail

# Removes the commands install.sh created. Deliberately standalone - same as the
# installer, it has to work when piped straight from curl with no checkout around,
# so the few shared helpers are duplicated rather than sourced from a common file.
#
#   ./uninstall.sh
#   ./uninstall.sh --prefix=/usr/local/bin
#   curl -fsSL https://raw.githubusercontent.com/pagea-dev/typo3quickstarter/main/uninstall.sh | bash
#
# See docs/installation.md.

COMMAND_NAME="typo3quickstarter"
COMMAND_ALIASES=(t3quickstarter)
# install.sh puts a copy of this script here too, so it goes as well - deleting
# the file while it runs is fine, bash keeps reading from the open descriptor.
UNINSTALLER_NAME="typo3quickstarter-uninstall"

PREFIX="${HOME}/.local/bin"

if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_CYAN=$'\033[36m'
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'
else
  C_RESET="" C_BOLD="" C_CYAN="" C_GREEN="" C_YELLOW="" C_RED=""
fi

usage() {
  cat <<EOF
Usage: uninstall.sh [--prefix=DIR]

Removes the commands install.sh created.

  --prefix=DIR   Directory to remove them from (default: ${HOME}/.local/bin).
                 Pass the same --prefix you installed with.
  -h, --help     Show this help

Removes: ${COMMAND_NAME}, ${COMMAND_ALIASES[*]}, ${UNINSTALLER_NAME}
EOF
}

for arg in "$@"; do
  case "$arg" in
    --prefix=*) PREFIX="${arg#*=}" ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "${C_RED}Unknown option: $arg${C_RESET}" >&2
      usage
      exit 1
      ;;
  esac
done

PREFIX="${PREFIX%/}"

echo "${C_BOLD}${C_CYAN}typo3quickstarter${C_RESET} ${C_YELLOW}uninstaller${C_RESET}"
echo "${C_BOLD}Prefix:${C_RESET} ${PREFIX}"
echo

# Only ever remove files that are ours - a same-named command from somewhere else
# stays untouched.
is_ours() {
  # The setup script is recognized by its version line (releases predating the
  # marker are installable too), the uninstaller by the marker in its header.
  [[ -f "$1" ]] && grep -qE '^SCRIPT_VERSION=|^# typo3quickstarter-managed' "$1"
}

removed=0
for name in "$COMMAND_NAME" "${COMMAND_ALIASES[@]}" "$UNINSTALLER_NAME"; do
  path="${PREFIX}/${name}"
  if [[ -L "$path" ]]; then
    rm -f "$path"
    echo "${C_CYAN}Removed symlink ${path}${C_RESET}"
    removed=1
  elif is_ours "$path"; then
    rm -f "$path"
    echo "${C_CYAN}Removed ${path}${C_RESET}"
    removed=1
  elif [[ -e "$path" ]]; then
    echo "${C_YELLOW}Left ${path} alone - it wasn't installed by install.sh.${C_RESET}"
  fi
done

if [[ "$removed" -eq 1 ]]; then
  echo "${C_GREEN}${C_BOLD}Uninstalled.${C_RESET}"
  echo "Instances you already created are untouched - remove those with the script's own --cleanup."
else
  echo "${C_YELLOW}Nothing to uninstall in ${PREFIX}.${C_RESET}"
fi
