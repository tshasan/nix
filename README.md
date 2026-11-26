# nixos

[![check](https://github.com/tshasan/nix/actions/workflows/check.yml/badge.svg)](https://github.com/tshasan/nix/actions/workflows/check.yml)

Personal configuration for three NixOS hosts and two Apple Silicon Macs.
The repository uses flake-parts, Home Manager, and a small
platform boundary:

| Target | Packages and applications | Dotfiles |
| --- | --- | --- |
| `desktop`, `vm`, `forge` | NixOS and Home Manager | Home Manager |
| `personal-mac` | nix-darwin and Home Manager; Homebrew for GUI casks only | Home Manager |
| `work-mac` | Homebrew | Home Manager |

`work-mac` does not install development tools, shells, or applications through
Nix. Its only Nix-managed program is the Home Manager command used to apply
the dotfiles; Homebrew owns everything else. `personal-mac` is the opposite:
a full nix-darwin system where Nix owns packages, dev tools, and system
defaults, and Homebrew is limited to the casks declared in
`modules/hosts/personal-mac/default.nix`.

## What is here

- `desktop`: the main AMD/NVIDIA NixOS workstation.
- `vm`: a smaller NixOS configuration for testing.
- `forge`: the 13" M1 MacBook Pro running NixOS on Asahi Linux, kept shut and
  plugged in as a headless server for Forgejo and SearXNG.
- `personal-mac`: full nix-darwin system with Home Manager integrated as a
  darwin module.
- `work-mac`: standalone Home Manager dotfiles; no nix-darwin.
- Shared Zsh preferences, Neovim configuration, Kitty configuration, and
  Powerlevel10k settings.
- Formatting and pre-commit checks exposed through `nix flake check`.

Every Nix file under `modules/` is imported by `import-tree`.
Personal account and Git identity, home-directory, and flake location values
live in `modules/user.nix`.

```text
modules/
  parts.nix          flake-parts systems and shared inputs
  checks.nix         formatter, checks, and development shell
  user.nix           personal identity, home paths, and flake location
  common/            shared NixOS modules
  features/          optional NixOS features
  hosts/             desktop, vm, forge, personal-mac, and work-mac outputs
  home/              Home Manager modules
  files/             source-controlled dotfiles
```

## Continuous integration

- `check.yml` runs on every push and pull request: it evaluates all four
  host outputs (`desktop`, `vm`, `personal-mac`, `work-mac`) so a broken
  config fails CI without a full build, then runs the `treefmt` and
  `pre-commit` checks.
- `update-flake-lock.yml` processes flake inputs one at a time. For each changed
  input it opens or refreshes a pull request, waits for `check` and the merge to
  finish, then starts the next input from the updated `main` branch.
- Branch protection on `main` requires the `check` status check. That gates
  the auto-merge above, not direct pushes. Secret-scanning push protection is
  enabled repo-wide. Dependabot watches the Action versions used in both
  workflows.

## NixOS

Rebuild the current host:

```console
nh os switch
```

Common maintenance commands:

```console
nix fmt
nix flake check
nix flake update
```

Each NixOS configuration integrates Home Manager, so there is no
separate home activation step.

`desktop` runs `system.autoUpgrade` (`modules/features/autoUpgrade.nix`):
once a day it rebuilds and switches to the latest flake output unattended,
without rebooting. A failed run sends a desktop notification; details are in
`journalctl -u nixos-upgrade`. `vm` does not have this enabled.

## Asahi (forge)

`forge` is a 13" M1 MacBook Pro (MacBookPro17,1, 8 GB, 256 GB) running
NixOS on Asahi through
[nixos-apple-silicon](https://github.com/nix-community/nixos-apple-silicon).
It runs GNOME on a LUKS2-encrypted root with the same home modules as
`desktop`, plus Google Chrome.

Firefox and Tor Browser are the official Mozilla and Tor Project tarballs,
not Nix packages, so their built-in updaters apply signed updates as soon as
they ship (nixpkgs lags by a day or more). `programs.nix-ld` supplies the
libraries they expect. Home Manager still manages the Firefox profile
(settings and extensions) and its desktop entry. Install both once,
verifying each signature, and only continue past `gpg --verify` if it reports
a good signature from the expected key:

```console
mkdir -p ~/.local/opt && cd /tmp

# Firefox: download the latest linux-aarch64 en-US tarball, its .asc
# signature, and the release KEY from Mozilla's release archive into /tmp.
# Expected key: "Mozilla Software Releases",
# 14F2 6682 D091 6CDD 81E3  7B6D 61B7 B526 D98F 0353
gpg --import KEY
gpg --verify firefox-*.tar.xz.asc
tar -xJf firefox-*.tar.xz -C ~/.local/opt

# Tor Browser: "Tor Browser Developers",
# EF6E 286D DA85 EA2A 4BA7  DE68 4E2C 6E87 9329 8290
v=$(curl -s https://aus1.torproject.org/torbrowser/update_3/release/downloads.json | jq -r .version)
curl -LO "https://dist.torproject.org/torbrowser/$v/tor-browser-linux-aarch64-$v.tar.xz"
curl -LO "https://dist.torproject.org/torbrowser/$v/tor-browser-linux-aarch64-$v.tar.xz.asc"
gpg --auto-key-locate nodefault,wkd --locate-keys torbrowser@torproject.org
gpg --verify "tor-browser-linux-aarch64-$v.tar.xz.asc"
tar -xJf "tor-browser-linux-aarch64-$v.tar.xz" -C ~/.local/opt
~/.local/opt/tor-browser/start-tor-browser.desktop --register-app
```

Both check for updates while running and apply them on restart.

nixos-apple-silicon currently has no binary cache, so the Asahi kernel
builds locally (a few hours on this machine) whenever nixpkgs moves. For that
reason this host has no `system.autoUpgrade`.

### First setup

Follow the upstream
[installation guide](https://github.com/nix-community/nixos-apple-silicon/blob/main/docs/uefi-standalone.md)
to run the Asahi installer from macOS. Choose "UEFI environment only", name
the OS `NixOS`, and boot the installer ISO from the project's
[releases](https://github.com/nix-community/nixos-apple-silicon/releases).
Create the root partition in the free space as the guide describes, then
label, encrypt, and mount everything. The config finds every filesystem by these labels, so there are
no UUIDs to copy back into the repository:

```console
esp="/dev/disk/by-partuuid/$(tr -d '\0' < /proc/device-tree/chosen/asahi,efi-system-partition)"
fatlabel "$esp" NIXBOOT
cryptsetup luksFormat --type luks2 --label cryptnixos /dev/nvme0n1pN
cryptsetup open /dev/nvme0n1pN cryptroot
mkfs.ext4 -L nixos /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt
mkdir -p /mnt/boot && mount "$esp" /mnt/boot
```

The installer's `/tmp` is RAM, and the first install compiles the Asahi
kernel, which does not fit in 8 GB. Build on the target disk instead, with
the same 8 GiB swapfile the installed system will adopt:

```console
mkdir -p /mnt/var/lib /mnt/tmp
dd if=/dev/zero of=/mnt/var/lib/swapfile bs=1M count=8192 status=progress
chmod 600 /mnt/var/lib/swapfile && mkswap /mnt/var/lib/swapfile && swapon /mnt/var/lib/swapfile
TMPDIR=/mnt/tmp nixos-install --no-root-passwd --flake github:tshasan/nix#forge
nixos-enter --root /mnt -c 'passwd taimur'
```

The installer ISO has no `git`; `nixos-install` fetches the flake from
GitHub itself.

After reboot, clone the repository to `~/nix` and use `nh os switch`.

### Search

`/var/lib/searx.env` holds `SEARX_SECRET_KEY`. `searx-init` refuses to run
without it, because an empty `secret_key` is accepted by SearXNG and would
serve a broken instance.

The engine list is explicit in two halves: `use_default_settings.engines.keep_only`
is the complete inventory of what this instance serves, and the `engines` list
only overrides what differs from upstream (the `disabled` flag, and the Tor
proxy for the onion engines). Keep them in step when adding an engine.
SearXNG replaces `categories_as_tabs` wholesale instead of merging it, so the
tabs are re-listed with `onions` added.

Torrent indexers (1337x, The Pirate Bay, SolidTorrents, Kickass, Nyaa, BT4G)
run in the `files` tab over clearnet. Ahmia and Torch are `.onion` engines and
go through the local Tor client on `127.0.0.1:9050` with `socks5h`, so the
names resolve inside Tor. SearXNG refuses to start when that proxy does not
prove to be Tor, which is why `searx.service` is ordered after `tor.service`.
No torrents are downloaded or seeded here; it is an indexer front end only.

### State outside the config

These parts of the machine change on their own schedules, or have to be
created by hand before first boot. Nix does not track them:

- **The Cloudflare tunnel** is dashboard-managed. Create it, drop its
  credentials JSON at `/var/lib/cloudflared/<TUNNEL-ID>.json`, put the same
  UUID in `modules/features/server.nix`, and point both hostnames at it.
- **`/var/lib/searx.env`** must exist before `searx-init` runs:
  `sudo sh -c 'umask 077; echo SEARX_SECRET_KEY=$(openssl rand -hex 32) > /var/lib/searx.env'`.
- **The Forgejo admin user** is not declarative, and registration is off.
  Create it once with `forgejo admin user create --admin`; after that every
  other account is created from the admin panel.

- **m1n1, U-Boot and the device trees** are a single `m1n1/boot.bin` on the
  ESP, rewritten on every switch. Picking an older generation in the boot
  menu rolls back the kernel and initrd but not these. After a kernel
  upgrade, a rollback can boot an old kernel against new device trees.
- **Peripheral firmware** (`vendorfw/firmware.cpio` on the ESP) is extracted
  from macOS by the Asahi installer and only refreshed when you rerun it
  (see below). If the loader cannot find the ESP, it skips without failing,
  and the symptom is simply no Wi-Fi or webcam.
- **The Asahi kernel follows the repository's nixpkgs.** Every
  `nix flake update`, wherever you run it, means a multi-hour local kernel
  build on the next `nh os switch` here.
- **Firefox and Tor Browser** live in `~/.local/opt` and update themselves.
  NixOS rollbacks do not touch them, and a nixpkgs update can change the
  `nix-ld` libraries underneath them. If one stops starting after a switch,
  run it from a terminal and look for a missing library.
- **The battery limit** has two possible writers: the udev rule here, and
  GNOME's "Preserve Battery Health" switch. Leave the GNOME switch alone, or
  it will undo the 80% limit.

Wi-Fi, webcam, and ambient-light firmware is loaded from the ESP at boot.
To refresh it after a macOS update, run `curl https://alx.sh | sh` from macOS
and pick "Rebuild vendor firmware package". Apple system firmware updates
only arrive through macOS, so keep the macOS install updated.

## macOS (personal-mac, nix-darwin)

The `personal-mac` output is a full nix-darwin system for Apple Silicon. Nix
owns packages, dev tools, and system defaults; Homebrew only installs the
casks listed under `homebrew.casks` in
`modules/hosts/personal-mac/default.nix`.

### First setup

1. Install [Homebrew](https://brew.sh/) and [Nix](https://nixos.org/download/).
   Full Xcode is only needed if you plan to build the Firefox checkout below;
   the Xcode Command Line Tools are enough otherwise.
2. Clone this repository to its expected location:

```console
git clone https://github.com/tshasan/nix.git ~/nix
```

3. Confirm the macOS username and home path in `modules/user.nix`.
4. On a Mac that has never run nix-darwin, macOS's stock `/etc/zshrc` and
   `/etc/bashrc` will collide with the files nix-darwin wants to manage. Move
   them aside once, first:

```console
sudo mv /etc/bashrc /etc/bashrc.before-nix-darwin
sudo mv /etc/zshrc /etc/zshrc.before-nix-darwin
```

5. Bootstrap and activate. This first run needs `sudo` because system
   activation runs as root; it also installs `darwin-rebuild` and (via
   Home Manager) `nh` for every later switch:

```console
cd ~/nix
sudo nix --extra-experimental-features 'nix-command flakes' \
  run nix-darwin -- switch --flake .#personal-mac
```

6. Open a new terminal so the nix-darwin/Home Manager PATH changes take
   effect.

After the first activation, rebuild with:

```console
nh darwin switch
```

`homebrew.onActivation.cleanup = "zap"` means Homebrew removes any cask or
formula not declared in this config on every switch. Keep `Brewfile`-style
additions here instead of installing ad hoc with `brew install`.

A `launchd` daemon (`nix-darwin-auto-upgrade`, defined inline in
`modules/hosts/personal-mac/default.nix`) rebuilds and switches to the latest
flake output unattended every day at 3am. A failed run sends a desktop
notification. Logs go to `/var/log/nix-darwin-auto-upgrade.log`, which
`newsyslog` rotates at 1 MB, keeping five compressed copies.

### Audio plug-ins

Third-party Audio Units and VST3s live outside Nix, installed by vendor
packages rather than Home Manager, and several installers leave
`/Library/Audio/Plug-Ins` group- and world-writable. The `personal-mac`
activation script strips those write bits, and `system.defaults` disables
iZotope analytics and update checks.

macOS App Management protects `.app` bundles even from root, so keep the
activation script scoped to `/Library/Audio/Plug-Ins`; a stray installer copy
such as `Kilohearts Installer.app` cannot be repaired without granting the
terminal App Management, and is safe to leave or delete.

## macOS (work-mac, dotfiles only)

The `work-mac` output supports Apple Silicon and expects this repository at
`~/nix`. Homebrew owns everything executable listed in `Brewfile`, including
Zsh plugins. Home Manager only links configuration files.

### First setup

1. Install full Xcode, open it once, and finish its first-run setup.
2. Install [Homebrew](https://brew.sh/) and
   [Nix](https://nixos.org/download/).
3. Clone this repository to its expected location:

```console
git clone https://github.com/tshasan/nix.git ~/nix
```

4. Confirm the macOS username and home path in `modules/user.nix`.
5. Install the Brewfile:

```console
brew bundle --file ~/nix/Brewfile
```

6. Create the private, machine-wide work Git identity. See
   [Git identities](#git-identities) below.
7. Build and activate the dotfiles. You need the explicit feature flag only
   on first activation, before this profile installs `~/.config/nix/nix.conf`:

```console
cd ~/nix
nix --extra-experimental-features 'nix-command flakes' \
  build '.#homeConfigurations.work-mac.activationPackage'
./result/activate
```

Home Manager will not silently replace an existing dotfile. If the first
activation reports a collision, move that file aside, inspect it, and run the
activation again. This is the only migration step; the repository
has no bootstrap or switching scripts. Open a new terminal after activation.

After the first activation, normal updates are one command per owner:

```console
brew bundle --file ~/nix/Brewfile
home-manager switch --flake ~/nix#work-mac
```

A user `launchd` agent also applies `~/nix#work-mac` each day at 3am.
It uses the same local checkout and lockfile as the manual command; it does
not pull Git changes or update flake inputs. Add new files to Git before applying
them, because Git-backed flakes omit untracked files. Locked inputs that are
not cached still require network access. Failures send a desktop notification
through Homebrew's `terminal-notifier`; details go to
`~/Library/Logs/home-manager-auto-upgrade.log`.

Git maintenance runs through Homebrew Git every fifteen minutes and daily
at 3am for `~/firefox`, with prefetch disabled. Its log is
`~/Library/Logs/git-maintenance.log`.

`brew bundle` is additive. Review removals before asking Brew to clean them up:

```console
brew bundle cleanup --file ~/nix/Brewfile --dry-run
```

## macOS (shared notes)

These notes apply to both `personal-mac` and `work-mac`.

### Zsh

The shared interactive settings are in
`modules/files/shared/zsh/common.zsh`. Both platforms get the same history
behavior, aliases, editor, hooks, and keybindings.

- NixOS gets Zsh and its plugins from Nixpkgs through Home Manager.
- macOS uses the system Zsh and Homebrew plugin formulas.
- macOS-specific PATH setup stays in `modules/files/macos/zsh/`.
- Optional machine-only settings can go in
  `~/.config/zsh/local/*.zsh`; Home Manager leaves that directory alone.

The shared config checks for optional commands such as `eza`, `direnv`, and
`zoxide` before enabling their integrations, so a minimal VM remains usable.
Work-specific aliases and non-secret environment settings belong in a local
fragment such as `~/.config/zsh/local/work.zsh`.

### File manager

Yazi is available on all four hosts, with its default Vim-style keys and
previews. Nix supplies Yazi and its preview tools on NixOS and `personal-mac`;
the work Mac uses the packages in `Brewfile`. Hidden files are shown by default,
and the `git` plugin from nixpkgs marks each file's Git status on every host.
Shared settings live in `modules/files/shared/yazi/`.

Run `y` to browse files and leave your shell in the selected directory when
you quit with `q`. Run `yazi` to browse without changing the shell directory.
Use `h/j/k/l` to navigate, `<Enter>` to open a file, `<Space>` to select,
`.` to toggle hidden files, and `~` for help. Text files open in Neovim through
the shared `EDITOR` setting. Image previews work in Kitty and Ghostty.

### Git identities

Identity follows the machine:

- NixOS and `personal-mac` use the personal name and email declared in
  `modules/user.nix` directly.
- `work-mac` includes the private local file
  `~/.config/git/work.conf` for every repository.

Create the work profile once on a fresh work Mac. It is not
managed by Nix or committed to this repository. Skip this step if it was
already created during first setup:

```console
mkdir -p ~/.config/git
$EDITOR ~/.config/git/work.conf
chmod 600 ~/.config/git/work.conf
```

```gitconfig
[user]
    name = Your Name
    email = work@example.invalid
```

Signing keys and other work-only Git settings can live in the same file. Both
profiles set `user.useConfigOnly=true`, so Git refuses to guess an identity if
the expected configuration is missing. Check the active values with:

```console
git config --show-origin --get-regexp '^user\.'
```

### Firefox checkout

Keep the Firefox checkout at `~/firefox`. The dotfiles do not attach identity,
tool versions, or shell behavior to that directory. After cloning or moving the
checkout, select full Xcode and let Firefox own its project toolchain:

```console
sudo xcode-select --switch /Applications/Xcode.app
sudo xcodebuild -runFirstLaunch
sudo xcodebuild -license

cd ~/firefox
./mach bootstrap
./mach build
./mach run
```

Use `./mach npm` when Firefox documentation asks for an npm operation. Do not
add a package to the Brewfile because the Firefox source tree uses it.

For C++ editing alongside artifact builds, keep a separate full-build mozconfig
at `~/.mozbuild/mozconfig-tooling`:

```sh
ac_add_options --enable-optimize
ac_add_options --disable-debug
mk_add_options MOZ_OBJDIR=@TOPSRCDIR@/obj-tooling
```

Refresh the generated headers and compilation database from the checkout:

```console
MOZCONFIG="$HOME/.mozbuild/mozconfig-tooling" mach configure
MOZCONFIG="$HOME/.mozbuild/mozconfig-tooling" mach build analysis-prereqs
MOZCONFIG="$HOME/.mozbuild/mozconfig-tooling" mach build-backend -b Clangd
```

Point the checkout's `compile_commands.json` symlink at
`obj-tooling/clangd/compile_commands.json`. This leaves the default artifact
mozconfig unchanged. Refresh after source updates that change generated headers
or build configuration; restart clangd afterward.

In Neovim, `<leader>rp` (`:Phab list`) lists your in-flight Phabricator revisions;
`<leader>ro` (`:Phab current`) opens HEAD's revision. `:Phab open D123` opens a
revision directly. Selection opens the browser; these commands do not submit,
checkout, or modify reviews. The list uses the existing `moz-phab` authentication.

### Mutable and private files

Most managed files are immutable links into the Nix store. Two files link
back to this checkout because their applications update them:

- `modules/files/macos/gh/config.yml`
- `modules/files/shared/nvim/lazy-lock.json`

Those updates appear in `git diff`.

Keep the work Git profile, work-specific Zsh fragments, SSH material, tokens, and
machine-specific secrets outside this repository and outside the Nix store.

## Forking

Edit the personal account and identity values in `modules/user.nix`, replace the
host hardware configuration, create the work Git profile described above, and
rebuild.

## License

MIT. See [LICENSE](LICENSE).
