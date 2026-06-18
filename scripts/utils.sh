#!/usr/bin/env bash
# Shared helpers sourced by every script in this repo.

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'
  C_BLUE=$'\033[1;34m'
  C_GREEN=$'\033[1;32m'
  C_YELLOW=$'\033[1;33m'
  C_RED=$'\033[1;31m'
else
  C_RESET='' C_BLUE='' C_GREEN='' C_YELLOW='' C_RED=''
fi

info()    { printf '%s[INFO]%s  %s\n'  "$C_BLUE"   "$C_RESET" "$*"; }
success() { printf '%s[ OK ]%s  %s\n'  "$C_GREEN"  "$C_RESET" "$*"; }
warn()    { printf '%s[WARN]%s  %s\n'  "$C_YELLOW" "$C_RESET" "$*" >&2; }
error()   { printf '%s[FAIL]%s  %s\n'  "$C_RED"    "$C_RESET" "$*" >&2; }

# Print an error and exit non-zero in one call.
die() {
  error "$*"
  exit 1
}

# install-pkgs.sh shells out to python3 to parse packages.yaml (a real
# YAML lib would be a chicken-and-egg dependency on a fresh box), so
# make sure it exists before anything tries to use it.
ensure_python3() {
  local pm="$1"

  if command -v python3 &>/dev/null; then
    return 0
  fi

  warn "python3 not found — installing it directly so the package parser can run."
  case "$pm" in
    pacman) sudo pacman -Sy --needed --noconfirm python ;;
    apt)    sudo apt-get update -qq && sudo apt-get install -y python3 ;;
    dnf)    sudo dnf install -y python3 ;;
    zypper) sudo zypper --non-interactive install python3 ;;
    brew)   brew install python3 ;;
    *)      die "Don't know how to install python3 for package manager '$pm'" ;;
  esac
}
