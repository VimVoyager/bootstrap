#!/usr/bin/env bash
# Some of the multimedia packages in packages.yaml (ffmpeg, vlc, x264, x265)
# aren't in Fedora's or openSUSE's default repos for licensing reasons —
# install-pkgs.sh would otherwise just fail on those two distros. This adds
# the standard community repos that provide them, idempotently, before
# install-pkgs.sh runs. No-op on pacman/apt/brew.

setup_extra_repos() {
  local pm="$1"

  case "$pm" in
    apt)
      if [[ -f /etc/apt/sources.list.d/docker.sources ]]; then
        info "Docker CE repo already configured — skipping."
        return 0
      fi
      info "Adding Docker CE repo..."
      sudo apt-get update -qq
      sudo apt-get install -y ca-certificates curl
      sudo install -m 0755 -d /etc/apt/keyrings

      source /etc/os-release
      local distro_id="$ID"  # "debian" or "ubuntu" — Docker splits its repo per distro
      local codename="${UBUNTU_CODENAME:-$VERSION_CODENAME}"

      sudo curl -fsSL "https://download.docker.com/linux/${distro_id}/gpg" -o /etc/apt/keyrings/docker.asc
      sudo chmod a+r /etc/apt/keyrings/docker.asc

      sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/${distro_id}
Suites: ${codename}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF
      sudo apt-get update -qq
      ;;
    dnf)
      if dnf repolist 2>/dev/null | grep -qi rpmfusion; then
        info "RPM Fusion already enabled — skipping."
      else
        info "Enabling RPM Fusion (free + nonfree) for multimedia packages..."
        local rel
        rel="$(rpm -E %fedora)"
        sudo dnf install -y \
          "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${rel}.noarch.rpm" \
          "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${rel}.noarch.rpm"
      fi

      if [[ -f /etc/yum.repos.d/docker-ce.repo ]]; then
        info "Docker CE repo already configured — skipping."
      else
        info "Adding Docker CE repo..."
        sudo dnf install -y dnf-plugins-core
        sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
      fi
      ;;	    
    zypper)
      if zypper lr 2>/dev/null | grep -qi packman; then
        info "Packman repo already enabled — skipping."
        return 0
      fi
      info "Enabling Packman repo for multimedia packages..."
      source /etc/os-release
      local repo_url
      if [[ "$NAME" == *Tumbleweed* ]]; then
        repo_url="https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/"
      else
        repo_url="https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Leap_${VERSION_ID}/"
      fi
      sudo zypper addrepo -cfp 90 "$repo_url" packman
      sudo zypper --gpg-auto-import-keys refresh
      ;;
    *)
      : # pacman and brew don't need anything extra for these packages
      ;;
  esac
}
