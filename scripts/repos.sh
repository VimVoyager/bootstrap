#!/usr/bin/env bash
# Some of the multimedia packages in packages.yaml (ffmpeg, vlc, x264, x265)
# aren't in Fedora's or openSUSE's default repos for licensing reasons —
# install-pkgs.sh would otherwise just fail on those two distros. This adds
# the standard community repos that provide them, idempotently, before
# install-pkgs.sh runs. No-op on pacman/apt/brew.

setup_extra_repos() {
  local pm="$1"

  case "$pm" in
    dnf)
      if dnf repolist 2>/dev/null | grep -qi rpmfusion; then
        info "RPM Fusion already enabled — skipping."
        return 0
      fi
      info "Enabling RPM Fusion (free + nonfree) for multimedia packages..."
      local rel
      rel="$(rpm -E %fedora)"
      sudo dnf install -y \
        "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-${rel}.noarch.rpm" \
        "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${rel}.noarch.rpm"
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
      : # pacman, apt and brew don't need anything extra for these packages
      ;;
  esac
}
