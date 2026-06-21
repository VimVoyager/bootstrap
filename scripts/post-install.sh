#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PACKAGES_FILE="$ROOT_DIR/packages.yaml"

source "$SCRIPT_DIR/utils.sh"

PM="${1:-}"
if [[ -z "$PM" ]]; then
  error "No package manager passed to post-install.sh"
  exit 1
fi

# Bootstraps yay from the AUR using makepkg. Only ever called on pacman.
install_yay() {
  info "yay not found — bootstrapping it from the AUR (needs base-devel + git)..."
  sudo pacman -S --needed --noconfirm base-devel git
  local tmp
  tmp="$(mktemp -d)"
  git clone https://aur.archlinux.org/yay.git "$tmp/yay"
  (cd "$tmp/yay" && makepkg -si --noconfirm)
  rm -rf "$tmp"
  success "yay installed."
}

info "Running post-install steps..."

# ---------------------------------------------------------------------------
# 1. packages.yaml entries can carry a `method:` key instead of (or alongside)
#    a per-package-manager name. install-pkgs.sh deliberately skips these —
#    they're handled here instead. Supported methods: aur, flatpak, snap,
#    script. Example entry:
#
#      - name: my-tool
#        method: flatpak
#        target: com.example.MyTool
# ---------------------------------------------------------------------------
mapfile -t METHOD_ENTRIES < <(python3 - "$PACKAGES_FILE" <<'EOF'
import sys, re

path = sys.argv[1]
with open(path) as f:
    content = f.read()

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
        target = fields.get('target', name)
        print(f"{fields['method']}|{target}")
EOF
)

if [[ ${#METHOD_ENTRIES[@]} -eq 0 ]]; then
  info "No method-based packages to install."
else
  for entry in "${METHOD_ENTRIES[@]}"; do
    method="${entry%%|*}"
    target="${entry#*|}"
    case "$method" in
      flatpak)
        if ! command -v flatpak &>/dev/null; then
          warn "flatpak not installed — skipping $target. Add a 'flatpak' entry to packages.yaml."
          continue
        fi
	flatpak remote-add --if-not-exists --user flathub https://flathub.org/repo/flathub.flatpakrepo
        info "Installing $target via flatpak..."
        flatpak install -y --user --noninteractive flathub "$target"
        ;;
      snap)
        if ! command -v snap &>/dev/null; then
          warn "snap not installed — skipping $target."
          continue
        fi
        info "Installing $target via snap..."
        sudo snap install "$target"
        ;;
      aur)
        if [[ "$PM" != "pacman" ]]; then
          warn "Skipping AUR package $target — not on Arch."
          continue
        fi
        if ! command -v yay &>/dev/null; then
          install_yay
        fi
        info "Installing $target from the AUR via yay..."
        yay -S --needed --noconfirm "$target"
        ;;
      script)
        warn "Running arbitrary install script for $target — only do this for entries you trust."
        bash -c "$target"
        ;;
      *)
        warn "Unknown install method '$method' for $target — skipping."
        ;;
    esac
  done
fi

# ---------------------------------------------------------------------------
# 2. Docker: installing the package doesn't make it usable. Enable the
#    service and add the current user to the docker group so `docker ps`
#    works without sudo after a re-login. Guarded for containers/chroots
#    that have no systemd at all (e.g. testing this in plain Docker).
# ---------------------------------------------------------------------------
if command -v docker &>/dev/null; then
  if command -v systemctl &>/dev/null; then
    if ! systemctl is-active --quiet docker 2>/dev/null; then
      info "Enabling and starting the docker service..."
      sudo systemctl enable --now docker
    fi
  else
    warn "No systemctl found — skipping docker service enable (are you in a container?)."
  fi

  if ! groups "$USER" | grep -qw docker; then
    info "Adding $USER to the docker group..."
    sudo usermod -aG docker "$USER"
    warn "Log out and back in (or run 'newgrp docker') for the group change to take effect."
  fi
else
  info "Docker not installed — skipping docker post-install."
fi

success "Post-install steps complete."
