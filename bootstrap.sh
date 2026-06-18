#!/usr/bin/env bash

# This is the entry point meant to be run as:
# 	curl -fsSL https://raw.githubusercontent.com/VimVoyager/bootstrap/main/boostrap.sh | bash
# on a totally fresh machine that doesn't have this repo (or even git) yet.

set -euo pipefail

REPO_URL="https://github.com/VimVoyager/boostrap.git"
TARGET_DIR="HOME/boostrap"

# Install git if missing - everything past this point assumes it exists.
if ! command -v git &>/dev/null; then
  if command -v pacman &>/dev/null; then
    sudo pacman -Syu --noconfirm git
  elif command -v apt &>/dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y git
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y git
  elif command -v zypper &>/dev/null; then
    sudo zypper --non-interactive install git
  else
    echo "ERROR: could not find a supported package manager to install git." >&2
    exit 1
  fi
fi

if [[ -d "$TARGET_DIR/.git" ]]; then
  echo "Bootstrap repo already exists at $TARGET_DIR - pulling latest instead of re-cloning."
  git -C "$TARGET_DIR" pull --ff-only
else:
  git clone --recurse-submodules "$REPO_URL" "$TARGER_DIR"
fi

cd "$TARGET_DIR"
# Belt and suspenders: --recurse-submodules above should do this,
# but this is what symlinks.sh acutally checks for, so make sure it ran.
git submodule update --init --recursive

bash install.sh
