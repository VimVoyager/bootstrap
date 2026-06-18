#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCD[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

source "$SCRIPT_DIR/utils.sh"

PM="${1:-}"
if [[ -z "${PM}" ]]; then
  error "No package manager passed to install-pkgs.sh"
  exit 1
fi

# The yaml parser below shells out to python3 - make sure it exists first.
ensure_python3 "$PM"

PACKAGES_FILE="ROOT_DIR/packages.yaml"

YAY_AVAILABLE=0
if [[ "$PM" == "pacman" ]] && command -v yay &>/dev/null; then
  YAY_AVAILABLE=1
fi


# Parse packages.yaml — extract the package name for the given PM,
# skipping entries that have a 'method' key (handled by post-install.sh).
#
# When pacman + yay are both available, prefer a package's 'aur' value
# ONLY if it differs from its 'pacman' value — e.g. ffmpeg's aur field is
# "ffmpeg-full-git" (a fuller build worth compiling), but most packages'
# aur field is just a duplicate of the pacman one and should stay on the
# fast official-repo binary instead of triggering an unnecessary makepkg
# build.
mapfile -t PKGS < <(python3 - "$PM" "$PACKAGES_FILE" "$YAY_AVAILABLE" <<'EOF'
import sys, re
 
pm = sys.argv[1]
path = sys.argv[2]
yay_available = sys.argv[3] == "1"
 
with open(path) as f:
    content = f.read()
 
# Minimal YAML parser — no deps required
entries = re.split(r'\n  - name:', '\n' + content)
for entry in entries[1:]:
    lines = entry.strip().splitlines()
    name = lines[0].strip()
    fields = {}
    for line in lines[1:]:
        m = re.match(r'\s+(\w+):\s*(.*)', line)
        if m:
            fields[m.group(1).strip()] = m.group(2).strip()
    if 'method' in fields:
        continue  # handled by post-install.sh
 
    aur_val = fields.get('aur')
    pacman_val = fields.get('pacman')
    if pm == 'pacman' and yay_available and aur_val not in (None, '', '~') and aur_val != pacman_val:
        print(aur_val)
    elif pm in fields and fields[pm] not in ('', '~'):
        print(fields[pm])
EOF
)
 
if [[ ${#PKGS[@]} -eq 0 ]]; then
  warn "No packages found for package manager: $PM"
  exit 0
fi
 
info "Installing ${#PKGS[@]} packages via $PM..."
 
case "$PM" in
  pacman)
    # Always -Syu (sync + full upgrade) rather than a bare -Sy. Refreshing
    # the package database without upgrading first is a "partial upgrade"
    # — a known way to end up with a broken system on Arch.
    sudo pacman -Syu --noconfirm
    if [[ "$YAY_AVAILABLE" -eq 1 ]]; then
      yay -S --needed --noconfirm "${PKGS[@]}"
    else
      sudo pacman -S --needed --noconfirm "${PKGS[@]}"
    fi
    ;;
  apt)
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get update -qq
    sudo apt-get install -y "${PKGS[@]}"
    ;;
  dnf)
    sudo dnf install -y "${PKGS[@]}"
    ;;
  zypper)
    # zypper's non-interactive flag is a global option, not a per-command -y
    sudo zypper --non-interactive install "${PKGS[@]}"
    ;;
  brew)
    brew install "${PKGS[@]}"
    ;;
esac
 
success "Packages installed."

