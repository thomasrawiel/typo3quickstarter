#!/usr/bin/env bash
set -euo pipefail

# Installs typo3-ddev-setup.sh as a system-wide command, so instances can be
# created from any directory: the script always creates the project folder in
# the current working directory unless --path says otherwise.
#
#   curl -fsSL https://raw.githubusercontent.com/pagea-dev/typo3quickstarter/main/install.sh | bash
#   ./install.sh                 # from a checkout, installs the script next to it
#
# Removing it again is uninstall.sh's job, not this script's.
#
# See docs/installation.md.

REPO="pagea-dev/typo3quickstarter"
SCRIPT_NAME="typo3-ddev-setup.sh"
UNINSTALL_NAME="uninstall.sh"
RELEASE_URL="https://github.com/${REPO}/releases/latest/download/${SCRIPT_NAME}"
# uninstall.sh is not a release asset, but this project only moves main on a
# release, so raw main is the released state - see docs/CONTRIBUTING.md.
UNINSTALL_URL="https://raw.githubusercontent.com/${REPO}/main/${UNINSTALL_NAME}"

# The first name is the real file, the rest become symlinks to it. The script
# prints whichever name it was called under in its own usage/cleanup hints.
COMMAND_NAME="typo3quickstarter"
COMMAND_ALIASES=(t3quickstarter)
# Installed next to it so removing works without a checkout around.
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
Usage: install.sh [--prefix=DIR]

Installs typo3quickstarter as a command you can run from any directory.

  --prefix=DIR   Directory to install into (default: ${HOME}/.local/bin).
                 Use --prefix=/usr/local/bin for a machine-wide install; that
                 usually needs to be run with sudo.
  -h, --help     Show this help

Installed commands: ${COMMAND_NAME}, ${COMMAND_ALIASES[*]}
Also installs ${UNINSTALLER_NAME}, which removes all of them again.
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
TARGET="${PREFIX}/${COMMAND_NAME}"

# Only ever touch files that are ours: a same-named command from somewhere else
# must not be overwritten.
is_ours() {
  # The setup script is recognized by its version line (releases predating the
  # marker are installable too), the uninstaller by the marker in its header.
  [[ -f "$1" ]] && grep -qE '^SCRIPT_VERSION=|^# typo3quickstarter-managed' "$1"
}

# Reads SCRIPT_VERSION out of a copy of the setup script. Deliberately plain
# grep/cut rather than sourcing the file - that would run it.
read_version() {
  local v=""
  [[ -f "$1" ]] && v="$(grep -m1 '^SCRIPT_VERSION=' "$1" | cut -d'"' -f2)"
  echo "${v:-unknown}"
}

echo "${C_BOLD}${C_CYAN}typo3quickstarter${C_RESET} ${C_YELLOW}installer${C_RESET}"
echo "${C_CYAN}https://github.com/${REPO}${C_RESET} · ${C_CYAN}https://pagea.dev/${C_RESET}"
echo

# Prefer the script sitting next to this installer (git checkout), fall back to
# the latest release asset (curl | bash, where there is no checkout at all).
# Piped through `curl ... | bash` there is no script file at all, and BASH_SOURCE
# is unset - which `set -u` turns into a hard error without the fallback.
SOURCE_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]:-$0}")" && pwd)"
TMP_FILES=()
cleanup_tmp() { [[ ${#TMP_FILES[@]} -gt 0 ]] && rm -f "${TMP_FILES[@]}"; return 0; }
trap cleanup_tmp EXIT

# $1 = file name in the checkout, $2 = URL to fall back to. Prints the path to use.
resolve_source() {
  local name="$1" url="$2" tmp
  if [[ -f "${SOURCE_DIR}/${name}" ]]; then
    echo "${SOURCE_DIR}/${name}"
    return 0
  fi
  command -v curl >/dev/null 2>&1 || { echo "${C_RED}Error: curl is needed to download ${name}, and it is not in PATH.${C_RESET}" >&2; return 1; }
  tmp="$(mktemp)"
  TMP_FILES+=("$tmp")
  curl -fsSL "$url" -o "$tmp" || { echo "${C_RED}Error: download from ${url} failed.${C_RESET}" >&2; return 1; }
  echo "$tmp"
}

if [[ -f "${SOURCE_DIR}/${SCRIPT_NAME}" ]]; then
  SOURCE_LABEL="${SOURCE_DIR} (local checkout)"
else
  SOURCE_LABEL="latest release on GitHub"
  echo "${C_CYAN}==> Downloading ${SCRIPT_NAME} and ${UNINSTALL_NAME}${C_RESET}"
fi

SOURCE="$(resolve_source "$SCRIPT_NAME" "$RELEASE_URL")"
UNINSTALL_SOURCE="$(resolve_source "$UNINSTALL_NAME" "$UNINSTALL_URL")"

NEW_VERSION="$(read_version "$SOURCE")"
# An existing install tells us whether this is a fresh one, an update or a
# reinstall - worth saying out loud, since "install.sh" is also the update path.
INSTALLED_VERSION=""
is_ours "$TARGET" && INSTALLED_VERSION="$(read_version "$TARGET")"

printf '%sSource:%s  %s\n' "$C_BOLD" "$C_RESET" "$SOURCE_LABEL"
printf '%sVersion:%s %s\n' "$C_BOLD" "$C_RESET" "$NEW_VERSION"
printf '%sTarget:%s  %s\n' "$C_BOLD" "$C_RESET" "$PREFIX"
if [[ -n "$INSTALLED_VERSION" ]] && [[ "$INSTALLED_VERSION" != "$NEW_VERSION" ]]; then
  printf '%sUpdate:%s  %s -> %s\n' "$C_BOLD" "$C_RESET" "$INSTALLED_VERSION" "$NEW_VERSION"
elif [[ -n "$INSTALLED_VERSION" ]]; then
  printf '%sUpdate:%s  reinstalling %s\n' "$C_BOLD" "$C_RESET" "$INSTALLED_VERSION"
fi
echo

# Bail out before writing anything if the target name is taken by something else.
if [[ -e "$TARGET" ]] && ! is_ours "$TARGET"; then
  echo "${C_RED}Error: ${TARGET} exists and was not installed by this script - not overwriting it.${C_RESET}" >&2
  exit 1
fi

UNINSTALLER_TARGET="${PREFIX}/${UNINSTALLER_NAME}"
if [[ -e "$UNINSTALLER_TARGET" ]] && ! is_ours "$UNINSTALLER_TARGET"; then
  echo "${C_RED}Error: ${UNINSTALLER_TARGET} exists and was not installed by this script - not overwriting it.${C_RESET}" >&2
  exit 1
fi

mkdir -p "$PREFIX"
install -m 755 "$SOURCE" "$TARGET"
install -m 755 "$UNINSTALL_SOURCE" "$UNINSTALLER_TARGET"

# What landed where, so it's obvious what a later uninstall will take away again.
echo "${C_GREEN}${C_BOLD}Installed into ${PREFIX}:${C_RESET}"
printf '  %s%-29s%s %s\n' "$C_GREEN" "$COMMAND_NAME" "$C_RESET" "the TYPO3 instance creator itself"
for name in "${COMMAND_ALIASES[@]}"; do
  link="${PREFIX}/${name}"
  if [[ -e "$link" ]] && [[ ! -L "$link" ]] && ! is_ours "$link"; then
    printf '  %s%-29s%s %s\n' "$C_YELLOW" "$name" "$C_RESET" "skipped - a different file of that name is already there"
    continue
  fi
  ln -sf "$TARGET" "$link"
  printf '  %s%-29s%s %s\n' "$C_GREEN" "$name" "$C_RESET" "short alias, symlink to ${COMMAND_NAME}"
done
printf '  %s%-29s%s %s\n' "$C_GREEN" "$UNINSTALLER_NAME" "$C_RESET" "removes all of the above again"

# Informational only - you can install this before ever installing DDEV, you just
# can't create an instance yet. Better to say so now than to fail on first use.
MISSING=""
command -v docker >/dev/null 2>&1 || MISSING="docker"
command -v ddev >/dev/null 2>&1 || MISSING="${MISSING:+${MISSING} and }ddev"
if [[ -n "$MISSING" ]]; then
  echo
  echo "${C_YELLOW}Note: ${MISSING} not found in PATH. You'll need it before creating an instance -${C_RESET}"
  echo "${C_YELLOW}see https://ddev.com/get-started/${C_RESET}"
fi

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
echo "    ${COMMAND_NAME} --release=13            # newest TYPO3 13, in the current directory"
echo "    ${COMMAND_ALIASES[0]} --release=12.4.20 --xdebug"
echo "    ${COMMAND_NAME} --help                  # every flag, with the docs it belongs to"
echo
UNINSTALL_HINT="${UNINSTALLER_NAME}"
# Only on PATH if PREFIX is - otherwise print something that actually runs.
case ":${PATH}:" in
  *":${PREFIX}:"*) ;;
  *) UNINSTALL_HINT="${UNINSTALLER_TARGET}" ;;
esac
echo "Uninstall again with: ${C_BOLD}${UNINSTALL_HINT}${C_RESET}"
