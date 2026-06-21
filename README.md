# boostrap

A distro-agnostic Linux setup script: install a package list, symlinks your dotfiles into $HOME, sets up SSH, and runs any post install steps each package needs (AUR/flatpak/snap packages, one-off install scripts, docker service + group).

```
bootstrap.sh                   entry point for `curl | bash` on a brand new machine
install.sh                     main flow, run directly if you've already got the repo
packages.yaml                  the package list, one block per logical package
ssh/config.template            starter ssh config, copied to ~/.ssh/config if missing
dotfiles/                      git submodule — your actual dotfiles, stowed into $HOME
scripts/
  utils.sh                     info/warn/error/success/die + ensure_python3
  detect-pm.sh                 detect_pm() -> pacman | apt | dnf | zypper | brew
  repos.sh                     setup_extra_repos() -> RPM Fusion / Packman, when needed
  install-pkgs.sh              parses packages.yaml, installs via the detected PM
  symlinks.sh                  stows dotfiles/ into $HOME
  ssh-setup.sh                 installs the ssh config template, fixes key perms
  post-install.sh              method-based packages (aur/flatpak/snap/script) + docker
  install-jetbrains-toolbox.sh example `method: script` install (download + launches Toolbxo)
```

## Flow

1. **`bootstrap.sh`** (only needed on a machine that doesn't have the repo yet): installs `git` if missing, clones this repo to `~/boostrap`, pulls in the `dotfiles` submodule, then hands off to install.sh`.

2. **`install.sh`** runs everything else, in this order:
    1. Detects your package manager.
    2. Enables any extra repos that PM needs (RPM Fusion/Docker CE on dnf, Packman on zypper) - packages that depend on these would otherwise fail to install.
    3. Installs everything from `packages.yaml`.
    4. Symlinks your dotfiles into `$HOME` (backing up anything already there to `*.bak`)
    5. Sets up your SSH config and key permissions.
    6. Runs post-install steps - AUR/flatpak/snap/script-based packages, plus docker service enable + group membership.

    The order matters: dotfiles assume packages are installed, and post-install (docker group, AUR/flatpak extras) assumes packages are installed too.

## Installing on a fresh install

```bash
curl -fsSL https://raw.githubusercontent.com/VimVoyager/bootstrap/main/bootstrap.sh | bash
```

This is safe to re-run - if `~/bootstrap` already exists, it pulls the latest changes instead of re-cloning, and every step further down the chain (package installs, dotfile symlinks, repo setup) is idempotent.

If you've already got the repo cloned somewhere (e.g. you're iterating on it), skip `bootstrap.sh` entirely and just run:

```bash
cd bootstrap
bash install.sh
```

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

A package only gets installed on a given PM if that PM's key is present and non-empty — omit a key entirely if a package isn't available (or isn't needed) there.
 
**`aur:`** is special: on Arch, if `yay` is available *and* the AUR value differs from the `pacman` value (e.g. a fuller `-git` build), the AUR build is used instead of the official repo package — see `ffmpeg` and `x264` for examples. If `aur:` just duplicates `pacman:`, it's ignored and the fast official binary wins.
 
**One field = one package name.** If something needs several packages installed together on the same PM (e.g. Docker's `docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin`), split it into separate entries — see `docker`, `docker-cli`, `containerd.io`, `docker-buildx`, and `docker-compose` in the current file.
 
For things that aren't in any distro's repos at all (flatpak/snap apps, AUR-only packages, or a one-off install script), use `method:` instead — these are skipped by `install-pkgs.sh` and handled by `post-install.sh`:
 
```yaml
  - name: obsidian
    method: flatpak
    target: md.obsidian.Obsidian
 
  - name: jetbrains-toolbox
    method: script
    target: scripts/install-jetbrains-toolbox.sh
```
 
Supported methods: `flatpak` (the Flathub remote is added automatically if it's missing), `snap`, `aur` (Arch only — bootstraps `yay` automatically if it's missing), and `script` (runs the file at `target`; make sure it's executable and that bit is committed to git, since a local `chmod` alone won't survive a fresh clone).

## Testing

Don't run this directly against your daily-driver machine first.

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


