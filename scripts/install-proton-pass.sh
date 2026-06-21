#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"
source "$SCRIPT_DIR/detect-pm.sh"

PM="$(detect_pm)"
VERSION_JSON_URL="https://proton.me/download/PassDesktop/linux/x64/version.json"

case "$PM" in
  apt) EXT="deb" ;;
  dnf) EXT="rpm" ;;
  *)
    info "No Proton Pass handling needed for $PM — skipping."
    exit 0
    ;;
esac

if command -v proton-pass &>/dev/null; then
  info "proton-pass already installed — skipping."
  exit 0
fi

info "Looking up the current Proton Pass release..."
INSTALLER_URL="$(curl -fsSL "$VERSION_JSON_URL" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for f in data['Releases'][0]['File']:
    if f['Url'].endswith('.$EXT'):
        print(f['Url'])
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
  apt) sudo apt-get install -y "$FILE" ;;
  dnf) sudo dnf install -y "$FILE" ;;
esac

success "Proton Pass installed."
