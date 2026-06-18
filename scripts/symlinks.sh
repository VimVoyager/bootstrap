#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DOTFILES_DIR="$ROOT_DIR/dotfiles"

source "$SCRIPT_DIR/utils.sh"

if [[ ! -d "$DOTFILES_DIR" ]]; then
  error "Dotfiles submodule not found at $DOTFILES_DIR"
  error "Run: git submodule update --init --recursive"
  exit 1
fi

if command -v stow &>/dev/null; then
  info "Symlinking dotfiles via stow..."
  stow --dir="$ROOT_DIR" --target="$HOME" dotfiles
  success "Dotfiles symlinked."
else
  info "stow not found — symlinking manually..."

  find "$DOTFILES_DIR" -maxdepth 1 -name ".*" | while read -r src; do
    filename="$(basename "$src")"
    dest="$HOME/$filename"

    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
      info "Already linked: $filename — skipping"
      continue
    fi

    if [[ -e "$dest" ]]; then
      warn "$dest already exists and is not a symlink to our dotfile."
      warn "Backing up to ${dest}.bak"
      mv "$dest" "${dest}.bak"
    fi

    ln -s "$src" "$dest"
    success "Linked: $filename"
  done
fi
