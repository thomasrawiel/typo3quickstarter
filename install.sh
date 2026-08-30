#!/usr/bin/env bash
set -euo pipefail

# Installs typo3-ddev-setup.sh as a system-wide command, so instances can be
# created from any directory: the script always creates the project folder in
# the current working directory unless --path says otherwise.
#
#   curl -fsSL https://raw.githubusercontent.com/pagea-dev/typo3quickstarter/main/install.sh | bash
#   ./install.sh                 # from a checkout, installs the script next to it
#   ./install.sh --uninstall
#
# See docs/installation.md.

REPO="pagea-dev/typo3quickstarter"
SCRIPT_NAME="typo3-ddev-setup.sh"
RELEASE_URL="https://github.com/${REPO}/releases/latest/download/${SCRIPT_NAME}"

# The first name is the real file, the rest become symlinks to it. The script
# prints whichever name it was called under in its own usage/cleanup hints.
COMMAND_NAME="typo3quickstarter"
COMMAND_ALIASES=(t3quickstarter)

PREFIX="${HOME}/.local/bin"
UNINSTALL=0

if [[ -t 1 ]] && [[ -z "${NO_COLOR:-}" ]]; then
  C_RESET=$'\033[0m'; C_BOLD=$'\033[1m'; C_CYAN=$'\033[36m'
  C_GREEN=$'\033[32m'; C_YELLOW=$'\033[33m'; C_RED=$'\033[31m'
else
  C_RESET="" C_BOLD="" C_CYAN="" C_GREEN="" C_YELLOW="" C_RED=""
fi

usage() {
  cat <<EOF
Usage: install.sh [--prefix=DIR] [--uninstall]

Installs typo3quickstarter as a command you can run from any directory.

  --prefix=DIR   Directory to install into (default: ${HOME}/.local/bin).
                 Use --prefix=/usr/local/bin for a machine-wide install; that
                 usually needs to be run with sudo.
  --uninstall    Remove the command and its aliases from --prefix again.
  -h, --help     Show this help

Installed commands: ${COMMAND_NAME}, ${COMMAND_ALIASES[*]}
EOF
}

for arg in "$@"; do
  case "$arg" in
    --prefix=*) PREFIX="${arg#*=}" ;;
    --uninstall) UNINSTALL=1 ;;
    -h|--help) usage; exit 0 ;;
    *)
      echo "${C_RED}Unknown option: $arg${C_RESET}" >&2
      usage
      exit 1
      ;;
  esac
done

PREFIX="${PREFIX%/}"
TARGET="${PREFIX}/${COMMAND_NAME}"

# Only ever touch files that are ours: a same-named command from somewhere else
# must not be overwritten or, worse, removed by --uninstall.
is_ours() {
  [[ -f "$1" ]] && grep -q '^SCRIPT_VERSION=' "$1" && grep -q 'typo3quickstarter\|typo3-ddev-setup' "$1"
}

if [[ "$UNINSTALL" -eq 1 ]]; then
  removed=0
  for name in "$COMMAND_NAME" "${COMMAND_ALIASES[@]}"; do
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
      echo "${C_YELLOW}Left ${path} alone - it wasn't installed by this script.${C_RESET}"
    fi
  done
  [[ "$removed" -eq 1 ]] && echo "${C_GREEN}Uninstalled.${C_RESET}" || echo "${C_YELLOW}Nothing to uninstall in ${PREFIX}.${C_RESET}"
  exit 0
fi

# Prefer the script sitting next to this installer (git checkout), fall back to
# the latest release asset (curl | bash, where there is no checkout at all).
# Piped through `curl ... | bash` there is no script file at all, and BASH_SOURCE
# is unset - which `set -u` turns into a hard error without the fallback.
SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
CLEANUP_TMP=""
if [[ -f "${SOURCE_DIR}/${SCRIPT_NAME}" ]]; then
  SOURCE="${SOURCE_DIR}/${SCRIPT_NAME}"
  echo "${C_CYAN}==> Installing ${SCRIPT_NAME} from ${SOURCE_DIR}${C_RESET}"
else
  command -v curl >/dev/null 2>&1 || { echo "${C_RED}Error: curl is needed to download ${SCRIPT_NAME}, and it is not in PATH.${C_RESET}" >&2; exit 1; }
  echo "${C_CYAN}==> Downloading the latest release of ${SCRIPT_NAME}${C_RESET}"
  CLEANUP_TMP="$(mktemp)"
  trap 'rm -f "$CLEANUP_TMP"' EXIT
  curl -fsSL "$RELEASE_URL" -o "$CLEANUP_TMP" || { echo "${C_RED}Error: download from ${RELEASE_URL} failed.${C_RESET}" >&2; exit 1; }
  SOURCE="$CLEANUP_TMP"
fi

# Bail out before writing anything if the target name is taken by something else.
if [[ -e "$TARGET" ]] && ! is_ours "$TARGET"; then
  echo "${C_RED}Error: ${TARGET} exists and was not installed by this script - not overwriting it.${C_RESET}" >&2
  exit 1
fi

mkdir -p "$PREFIX"
install -m 755 "$SOURCE" "$TARGET"
echo "${C_GREEN}Installed ${TARGET}${C_RESET}"

for name in "${COMMAND_ALIASES[@]}"; do
  link="${PREFIX}/${name}"
  if [[ -e "$link" ]] && [[ ! -L "$link" ]] && ! is_ours "$link"; then
    echo "${C_YELLOW}Skipping alias ${name}: ${link} exists and isn't ours.${C_RESET}"
    continue
  fi
  ln -sf "$TARGET" "$link"
  echo "${C_GREEN}Installed ${link} -> ${COMMAND_NAME}${C_RESET}"
done

echo
case ":${PATH}:" in
  *":${PREFIX}:"*)
    echo "${C_BOLD}Ready.${C_RESET} Run it from whichever directory you want the instance created in:"
    ;;
  *)
    echo "${C_YELLOW}${PREFIX} is not in your PATH yet. Add it, e.g.:${C_RESET}"
    echo "    echo 'export PATH=\"${PREFIX}:\$PATH\"' >> ~/.bashrc && source ~/.bashrc"
    echo
    echo "${C_BOLD}After that:${C_RESET}"
    ;;
esac
echo "    ${COMMAND_NAME} --release=13"
echo "    ${COMMAND_ALIASES[0]} --release=13 --xdebug"
echo
UNINSTALL_HINT="$0 --uninstall"
[[ "$PREFIX" != "${HOME}/.local/bin" ]] && UNINSTALL_HINT="${UNINSTALL_HINT} --prefix=${PREFIX}"
echo "Uninstall again with: ${C_BOLD}${UNINSTALL_HINT}${C_RESET}"
