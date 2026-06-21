#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

TOOLBOX_BIN="$HOME/.local/share/JetBrains/Toolbox/bin/jetbrains-toolbox"

if [[ -x "$TOOLBOX_BIN" ]]; then
  info "JetBrains Toolbox already installed — skipping."
  exit 0
fi

# Toolbox has no headless install mode on Linux — its first run self-installs
# and opens its window. Skip cleanly on boxes with no display (e.g. the
# Vagrant test VMs) instead of hanging or erroring out.
if [[ -z "${DISPLAY:-}" && -z "${WAYLAND_DISPLAY:-}" ]]; then
  warn "No GUI session detected — skipping JetBrains Toolbox (no headless install mode on Linux)."
  exit 0
fi

info "Downloading JetBrains Toolbox..."
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

curl -fsSL "https://data.services.jetbrains.com/products/download?platform=linux&code=TBA" \
  -o "$TMP_DIR/toolbox.tar.gz"
tar -xzf "$TMP_DIR/toolbox.tar.gz" -C "$TMP_DIR"

EXTRACTED_DIR="$(find "$TMP_DIR" -maxdepth 1 -type d -name 'jetbrains-toolbox-*' | head -n1)"
if [[ -z "$EXTRACTED_DIR" ]]; then
  error "Couldn't find extracted Toolbox directory — download may have failed."
  exit 1
fi

info "Launching Toolbox to complete self-install (creates ~/.local/share/JetBrains/Toolbox)..."
"$EXTRACTED_DIR/bin/jetbrains-toolbox" >/dev/null 2>&1 &
disown

success "JetBrains Toolbox installer launched."
