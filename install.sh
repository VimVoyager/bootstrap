#!/usr/bin/env bash
set -euo pipefail

BOOTSTRAP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$BOOTSTRAP_DIR/scripts/detect-pm.sh"
source "$BOOTSTRAP_DIR/scripts/utils.sh"

PM=$(detect_pm)

if [[ "$PM" == "unknown" ]]; then
  echo "ERROR: Could not detect a supported package manager. Aborting."
  exit 1
fi

info "Detected package manager: $PM"
info "Starting bootstrap..."

bash "$BOOTSTRAP_DIR/scripts/install-pkgs.sh" "$PM"
bash "$BOOTSTRAP_DIR/scripts/symlinks.sh"
bash "$BOOTSTRAP_DIR/scripts/ssh-setup.sh"
bash "$BOOTSTRAP_DIR/scripts/post-install.sh" "$PM"

info "Bootstrap complete. Restart your shell or run: source ~/.bashrc"
