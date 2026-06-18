#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
SSH_DIR="$HOME/.ssh"
TEMPLATE="$ROOT_DIR/ssh/config.template"

source "$SCRIPT_DIR/utils.sh"

info "Setting up SSH..."

mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Copy config template if no config exists yet
if [[ ! -f "$SSH_DIR/config" ]]; then
  if [[ -f "$TEMPLATE" ]]; then
    cp "$TEMPLATE" "$SSH_DIR/config"
    chmod 600 "$SSH_DIR/config"
    success "SSH config installed from template."
  else
    warn "No SSH config template found at $TEMPLATE — skipping."
  fi
else
  info "SSH config already exists — skipping template copy."
fi

# Warn about any keys referenced in config that are missing
if [[ -f "$SSH_DIR/config" ]]; then
  while IFS= read -r line; do
    if [[ "$line" =~ IdentityFile[[:space:]]+(.*) ]]; then
      key_path="${BASH_REMATCH[1]/#\~/$HOME}"
      if [[ ! -f "$key_path" ]]; then
        warn "Missing key referenced in SSH config: $key_path"
      else
        chmod 600 "$key_path"
        success "Key found and permissions set: $key_path"
      fi
    fi
  done < "$SSH_DIR/config"
fi

# Set correct permissions on any keys that do exist
find "$SSH_DIR" -name "id_*" ! -name "*.pub" -exec chmod 600 {} \;
find "$SSH_DIR" -name "*.pub" -exec chmod 644 {} \;

success "SSH setup complete."
