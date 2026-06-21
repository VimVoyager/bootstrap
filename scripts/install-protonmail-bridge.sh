#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/detect-pm.sh"

PM="$(detect_pm)"

# Arch gets this from the official repos (a plain pacman entry in
# packages.yaml). Proton doesn't provide an apt/dnf/zypper repo at all —
# just versioned .deb/.rpm files — so we resolve the current version from
# their own update-check JSON instead of hardcoding one.
VERSION_JSON_URL="https://protonmail.com/download/bridge/version_linux.json"

case "$PM" in
  apt) EXT="deb" ;;
  dnf|zypper) EXT="rpm" ;;
  *)
    info "No Proton Mail Bridge handling needed for $PM — skipping."
    exit 0
    ;;
esac

if command -v protonmail-bridge &>/dev/null; then
  info "protonmail-bridge already installed — skipping."
  exit 0
fi

info "Looking up the current Proton Mail Bridge release..."
INSTALLER_URL="$(curl -fsSL "$VERSION_JSON_URL" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for url in data['stable']['Installers']:
    if url.endswith('.$EXT'):
        print(url)
        break
")"

if [[ -z "$INSTALLER_URL" ]]; then
  error "Couldn't find a .$EXT installer in Proton's version JSON."
  exit 1
fi

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT
FILE="$TMP_DIR/$(basename "$INSTALLER_URL")"

info "Downloading $(basename "$INSTALLER_URL")..."
curl -fsSL "$INSTALLER_URL" -o "$FILE"

case "$PM" in
  apt)    sudo apt-get install -y "$FILE" ;;
  dnf)    sudo dnf install -y "$FILE" ;;
  zypper) sudo zypper --non-interactive install "$FILE" ;;
esac

success "Proton Mail Bridge installed."
