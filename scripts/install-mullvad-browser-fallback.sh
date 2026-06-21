#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/utils.sh"

# apt/dnf get this from Mullvad's own repo, Arch gets it from the AUR. This
# is the fallback for everything else (currently just openSUSE) — skip
# cleanly if a native install already put mullvad-browser on PATH.
if command -v mullvad-browser &>/dev/null; then
  info "mullvad-browser already installed — skipping flatpak fallback."
  exit 0
fi

if ! command -v flatpak &>/dev/null; then
  warn "flatpak not installed — can't install the Mullvad Browser fallback. Add a 'flatpak' entry to packages.yaml."
  exit 0
fi

info "No native Mullvad Browser package for this distro — installing via flatpak..."
flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y --noninteractive --user flathub net.mullvad.MullvadBrowser
success "Mullvad Browser installed via flatpak."
