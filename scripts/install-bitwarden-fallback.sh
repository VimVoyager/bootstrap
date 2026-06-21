#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

if command -v bitwarden &>/dev/null; then
  info "bitwarden already installed — skipping flatpak fallback."
  exit 0
fi

if ! command -v flatpak &>/dev/null; then
  warn "flatpak not installed — can't install Bitwarden. Add a 'flatpak' entry to packages.yaml."
  exit 0
fi

info "Installing Bitwarden via flatpak..."
flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y --noninteractive --user flathub com.bitwarden.desktop
success "Bitwarden installed via flatpak."
