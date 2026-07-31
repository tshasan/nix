# nixos

Personal configuration for two NixOS hosts and two Apple Silicon Macs.
The repository uses flake-parts, Home Manager, and a deliberately small
platform boundary:

| Target | Packages and applications | Dotfiles |
| --- | --- | --- |
| `desktop`, `vm` | NixOS and Home Manager | Home Manager |
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
- `personal-mac`: full nix-darwin system with Home Manager integrated as a
  darwin module.
- `work-mac`: standalone Home Manager dotfiles; no nix-darwin.
- Shared Zsh preferences, Neovim configuration, Kitty configuration, and
  Powerlevel10k settings.
- Formatting and pre-commit checks exposed through `nix flake check`.

Every Nix file under `modules/` is imported automatically by `import-tree`.
Personal account and Git identity, home-directory, and flake location values
live in `modules/user.nix`.

```text
modules/
  parts.nix          flake-parts systems and shared inputs
  checks.nix         formatter, checks, and development shell
  user.nix           personal identity, home paths, and flake location
  common/            shared NixOS modules
  features/          optional NixOS features
  hosts/             desktop, vm, personal-mac, and work-mac outputs
  home/              Home Manager modules
  files/             source-controlled dotfiles
```

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

Home Manager is integrated into each NixOS configuration, so there is no
separate home activation step.

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

After the first activation, rebuild with the same command used on the NixOS
hosts:

```console
nh os switch
```

`homebrew.onActivation.cleanup = "zap"` means Homebrew removes any cask or
formula not declared in this config on every switch — keep `Brewfile`-style
additions here instead of installing ad hoc with `brew install`.

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

6. Create the private, machine-wide work Git identity:

```console
mkdir -p ~/.config/git
nvim ~/.config/git/work.conf
chmod 600 ~/.config/git/work.conf
```

```gitconfig
[user]
    name = Your Name
    email = work@example.invalid
```

7. Build and activate the dotfiles. The explicit feature flag is needed only
   on first activation, before this profile installs `~/.config/nix/nix.conf`:

```console
cd ~/nix
nix --extra-experimental-features 'nix-command flakes' \
  build '.#homeConfigurations.work-mac.activationPackage'
./result/activate
```

Home Manager will not silently replace an existing dotfile. If the first
activation reports a collision, move that file aside, inspect it, and run the
activation again. This is the only migration step; the repository intentionally
has no bootstrap or switching scripts. Open a new terminal after activation.

After the first activation, normal updates are one command per owner:

```console
brew bundle --file ~/nix/Brewfile
home-manager switch --flake ~/nix#work-mac
```

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

### Git identities

Identity follows the machine:

- NixOS and `personal-mac` use the personal name and email declared in
  `modules/user.nix` directly.
- `work-mac` includes the private local file
  `~/.config/git/work.conf` for every repository.

Create the work profile once on a fresh work Mac. It is intentionally not
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
add a package to the Brewfile merely because the Firefox source tree uses it.

### Mutable and private files

Most managed files are immutable links into the Nix store. Two files are
deliberately linked back to this checkout because their applications update
them:

- `modules/files/macos/gh/config.yml`
- `modules/files/shared/nvim/lazy-lock.json`

Those updates appear directly in `git diff`.

Keep the work Git profile, work-specific Zsh fragments, SSH material, tokens, and
machine-specific secrets outside this repository and outside the Nix store.

## Forking

Edit the personal account and identity values in `modules/user.nix`, replace the
host hardware configuration, create the work Git profile described above, and
rebuild.

## License

MIT — see [LICENSE](LICENSE).
