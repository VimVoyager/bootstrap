# boostrap

A distro-agnostic Linux setup script: install a package list, symlinks dotfiles via GNU Stow, sets up SSH, and runs any post install steps (AUR/flatpak packages, docker service + group).

```
bootstrap.sh              entry point for `curl | bash` on a brand new machine
install.sh                main flow, run directly if you've already got the repo
packages.yaml              the package list, one block per logical package
ssh/config.template        starter ssh config, copied to ~/.ssh/config if missing
dotfiles/                  git submodule — your actual dotfiles, stowed into $HOME
scripts/
  utils.sh                 info/warn/error/success/die + ensure_python3
  detect-pm.sh              detect_pm() -> pacman | apt | dnf | zypper | brew
  repos.sh                  setup_extra_repos() -> RPM Fusion / Packman, when needed
  install-pkgs.sh           parses packages.yaml, installs via the detected PM
  symlinks.sh                stows dotfiles/ into $HOME
  ssh-setup.sh                installs the ssh config template, fixes key perms
  post-install.sh            method-based packages (aur/flatpak/snap/script) + docker
```

## Flow

1. `bootstrap.sh` (only needed on a machine that doesn't have the repo yet): installs `git` if missing, clones this repo to `~/boostrap`, pulls in the `dotfiles` submodule, then hands off to install.sh`.

2. `install.sh` detects your package manager, enables any extra repos that PM nees (RPM Fusion/ Packman), install everything from `packages.yaml`, stows you dotfiles, sets up SSH,  then runs post-install steps - in that order, because dotfiles assume packaes are installed, and post-install (docker group, AUR extras) assumes packages are installed too.

## packages.yaml format

Most packages just list their name per package manager:

```yaml
 - name: htop
   pacman: htop
   apt: htop
   dnf: htop
   zypper: htop
   brew: htop
```

A package only gets installed on a PM if that PM's key is present and not empty. The `aur:` key is special: on Arch, if yay is available and the AUR value differs from the pacman value differs from the pacman value (e.g. a fuller `-git` build), the AUR build is used instead of the offical repo package - see `ffmpeg` and `x264` in the current file for examples. If `aur:` is just a duplicate of `pacman:`, it's ignored and the fast binary package wins.

For things that aren't in any distro's repo's at all (flatpak/snap apps, AUR-only packages, or a one-off install script), use `method:` instead - these are skipped by `install-pkgs.sh` and handled by `post-install.sh`:

```yaml
  - name: obsidian
    method: flatpak
    target: md.obsidian.Obisidian
```

## Testing

Don't run this directly against your daily-driver machine first.

### Full-fidelity: Vagrant + libvirt

This matches a ral machine closely (real systemmd, real sudo, real package manager state) and is the way to catch gotchas that only show up on an actual fresh install missing repos, partial-upgrade issues, etc.).

One-time host setup (on an Arch-based box like CachyOS)

```bash
sudo pacman -S --needed vagrant libvirt qemu-full virt-manager dnsmasq
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $USER      # log out/in after this
vagrant plugin install vagrant-libvirt
```

Then from the repo root:

```bash
vagrant up arch     # on debian / fedora / opensuse
vagrant ssh arch
  $ cd /vagrant
  $ bash install.sh
```

Repo changes on the host sync into `/vagrant` automatically (rsync), so you can edit a script, re-run `vagrant rsync arch`, and re-run `install.sh` without rebuilding the VM. `vagrant destroy -f arch` to reset and try again from a clean slate.


