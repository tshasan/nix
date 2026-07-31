# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Personal configuration for one user across two NixOS hosts and two Apple
Silicon Macs:

- `desktop`: main workstation.
- `vm`: lightweight NixOS test target.
- `personal-mac`: full nix-darwin system, home-manager integrated as a
  darwin module (same pattern as the NixOS hosts). Nix owns packages,
  applications (via `homebrew.casks`), and system defaults.
- `work-mac`: standalone Home Manager dotfiles only, no nix-darwin. Homebrew
  owns packages and applications; do not add macOS packages to Home Manager.

All personal account, Git identity, home path, SSH, and flake location values
live in `modules/user.nix` as `flake.lib.user`. The work-Mac Git identity stays
in a private local profile. The repository intentionally has no bootstrap,
switching, migration, or parity scripts.

## Commands

- `nh os switch` — rebuild and activate the current host, NixOS or
  `personal-mac`. Do **not** invoke `nixos-rebuild` or `darwin-rebuild`
  directly.
- `home-manager switch --flake ~/nix#work-mac` — apply macOS dotfiles after initial activation.
- `brew bundle --file ~/nix/Brewfile` — install declared macOS packages and applications.
- `nix flake check` — runs `treefmt` + `pre-commit` checks; mirrors CI.
- `nix build .#checks.x86_64-linux.treefmt` / `.#checks.x86_64-linux.pre-commit` — run one check in isolation.
- `nix fmt` — format all Nix files (nixfmt via treefmt-nix).
- `nix flake update` — refresh `flake.lock` (also updated daily by the `update-flake-lock` workflow, auto-merged).
- `direnv allow` — `.envrc` runs `use flake` and installs pre-commit hooks via the dev shell.

## Architecture

This flake follows <https://flake.parts/> — every file under `modules/` is a **flake-parts module**, not a raw flake output. `flake.nix` is intentionally minimal:

```nix
outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);
```

`import-tree` auto-imports every `.nix` file under `modules/` — **there is no imports list to update when adding a file.** A new file is live the moment it's saved.

### flake-parts module shape

Each module is a function returning an attrset. Available args: `{ self, inputs, config, lib, ... }` — `self` is this flake (use it to reference outputs defined in _other_ files, e.g. `self.nixosModules.foo`); `inputs` is the flake inputs from `flake.nix`.

There are two scopes a module can write to:

- **Top-level** — flake-wide outputs and options. Common keys:
  - `flake.nixosModules.<name>` / `flake.homeModules.<name>` / `flake.nixosConfigurations.<name>` — populate flake outputs.
  - `imports` — pull in _other flake-parts modules_ (not NixOS modules). Used to wire up flake modules from inputs, e.g. `inputs.treefmt-nix.flakeModule`, `inputs.home-manager.flakeModules.home-manager`.
  - `systems` — list of systems `perSystem` is evaluated for. Set once in `parts.nix`.
- **`perSystem`** — outputs evaluated once per system in `systems`. Receives its own `{ pkgs, system, config, ... }`. Common keys: `perSystem.devShells.<name>`, `perSystem.packages.<name>`, `perSystem.checks.<name>`, plus options contributed by imported flake modules (`treefmt`, `pre-commit`).

Examples from this repo:

```nix
# nixos module — modules/common/*.nix, modules/features/*.nix
{ ... }: { flake.nixosModules.myModule = { pkgs, ... }: { ... }; }

# home module — modules/home/*.nix
{ ... }: { flake.homeModules.myModule = { pkgs, ... }: { ... }; }

# host config — modules/hosts/<host>/default.nix
{ self, inputs, ... }: {
  flake.nixosConfigurations.desktop = inputs.nixpkgs.lib.nixosSystem {
    modules = [ self.nixosModules.desktopConfiguration ];
  };
}

# perSystem output — modules/checks.nix
{ inputs, ... }: {
  imports = [ inputs.treefmt-nix.flakeModule ];
  perSystem = { pkgs, config, ... }: {
    treefmt.programs.nixfmt.enable = true;
    devShells.default = pkgs.mkShell { /* … */ };
  };
}
```

**Do not** write raw flake outputs (`nixosConfigurations.* = …` at the top of `flake.nix`, etc.) — always go through the flake-parts module system so `import-tree` and the per-system machinery keep working.

### Layout

```
modules/
  parts.nix          flake-parts setup (systems list, imports home-manager flakeModule)
  checks.nix         imports treefmt-nix + git-hooks-nix flakeModules; perSystem devShell
  user.nix           flake.lib.user: personal identity, home, SSH, and flake location
  common/            flake.nixosModules.*: system-wide (locale, nix, ssh, users, base-packages)
  features/          flake.nixosModules.*: optional system features (audio, bluetooth, gaming, gnome, …)
  hosts/<host>/      NixOS host assembly, the personal-mac nix-darwin
                     assembly, and the standalone work-mac output
  home/              flake.homeModules.*: per-user config (zsh, git, firefox, nvim, …);
                     user.nix is the composition point listing every homeModules.* import
  files/             raw config files referenced by home modules
```

On NixOS, Home Manager runs as a system module.
`modules/features/homeManager.nix` declares `flake.nixosModules.homeManager`;
each NixOS host wires the appropriate home modules into its user.
`personal-mac` wires Home Manager the same way, but directly through
`inputs.home-manager.darwinModules.home-manager` in
`modules/hosts/personal-mac/default.nix` (nix-darwin has no equivalent of
`flake.nixosModules.homeManager` to reuse). Modern nix-darwin requires
`system.primaryUser` and an explicit `users.users.<name>.home` for
Home Manager's darwin integration to resolve `home.homeDirectory` — both are
set from `self.lib.user` in that file. The `work-mac` output instead uses
standalone Home Manager and must remain dotfiles-only. Its one Nix-managed
executable is the Home Manager driver used to apply those files.

Cross-platform interactive Zsh settings live in
`modules/files/shared/zsh/common.zsh`. NixOS plugin loading belongs in
`modules/home/zsh.nix`; macOS PATH and Homebrew plugin loading belong in
`modules/files/macos/zsh/`. Do not duplicate shared aliases, history settings,
hooks, or keybindings in the platform files.

### Account and Git identity

`modules/user.nix` sets `flake.lib.user`, including Linux and Darwin account
paths, SSH keys, and the flake location. Modules read those shared values from
`self.lib.user`.

NixOS reads the personal Git name and email from `flake.lib.user`. The
`work-mac` profile must not contain a work identity; it includes the untracked
`~/.config/git/work.conf` for every repository. Keep
`user.useConfigOnly=true` on both platforms so a missing identity cannot be
guessed.

### Adding a feature

- **System feature** — drop `modules/features/foo.nix` exporting `flake.nixosModules.foo = { ... }: { ... };`, then add `self.nixosModules.foo` to the module list in `modules/hosts/desktop/configuration.nix`.
- **Home module** — drop `modules/home/foo.nix` exporting `flake.homeModules.foo = { ... }: { ... };`, then add `self.homeModules.foo` to the imports list in `modules/home/user.nix`.
- **Common (system-wide, always-on)** — drop `modules/common/foo.nix` exporting `flake.nixosModules.foo`; wire it into the host the same way as a feature.
- **`personal-mac` home config** — edit `modules/home/personalMac.nix`
  (`flake.homeModules.personalMac`) directly; packages go in `home.packages`
  the same as a NixOS home module.
- **`work-mac` dotfile** — put its source under `modules/files/` and link it
  from `modules/home/workMac.nix`. Add the corresponding program to
  `Brewfile`, not `home.packages`.

`import-tree` picks the file up automatically; no `imports = [ … ];` update in `flake.nix`.

## Rules

- Group related config together. Do **not** split into tiny single-purpose files — if it belongs together, keep it together. Fragmentation for its own sake is worse than a larger file.
- No custom NixOS options (`lib.mkOption`) unless unavoidable. Direct assignment only.
- No `lib.mkIf`, `lib.mkMerge`, or `mkDefault` unless the logic genuinely requires it.
- No abstractions for hypothetical future users. The **one** sanctioned
  abstraction is `flake.lib.user` for system account and home path values.
  Don't invent further indirection beyond it.
- No comments explaining what standard Nix or NixOS options do.
- Prefer `pkgs.*` over writing derivations. Don't package things already in nixpkgs.
- System packages go in `common/` or `features/`. User packages go in `home/dev.nix` or `home/user.nix`.
- The work-mac Home Manager profile is dotfiles-only. Homebrew owns its shell,
  plugins, CLI tools, runtimes, and applications.
- `personal-mac` is a full nix-darwin system: Nix owns packages, dev tools,
  and system defaults; Homebrew is limited to GUI casks not packaged (well)
  in nixpkgs (`homebrew.casks` in `modules/hosts/personal-mac/default.nix`).
- Do not add repository helper scripts. Keep activation and maintenance as
  standard `nix`, `home-manager`, and `brew` commands.
- **Work identity is local-only.** Work Git names, emails, signing keys,
  domains, internal hostnames, project codenames, and anything tied to work
  tooling must never appear in committed files, commit metadata, or
  sample/snippet output. The committed `.gitleaks.toml` documents the mechanism
  with placeholder patterns; real blocked patterns live in the untracked
  `.gitleaks.local.toml`. If unsure, leave it out.
- **Keep symbols statically resolvable.** No `with pkgs;` / `with lib;` (or similar dynamic-scope tricks) at module top-level or around `let` / option bodies — use explicit `pkgs.foo` / `lib.foo` references. The one exception is nixpkgs-style `with pkgs; [ ... ]` (or `with pkgs; { ... }`) **immediately surrounding a list/attrset literal of package names** — the `with` scope dies at the closing bracket, statix accepts it, and the rest of nixpkgs writes package lists this way. Anywhere else, spell it out. When a custom option is genuinely unavoidable (see above), it must use `lib.mkOption` with an explicit `type =` (a concrete `lib.types.*`); no untyped options, no `freeformType` escape hatches. `nix flake check` is the source of truth — don't silence its output to make CI green.
- **`nixfmt` is the only Nix formatter.** Don't reach for `nixpkgs-fmt`, `alejandra`, or hand-formatting. Run `nix fmt` (treefmt-nix wraps `nixfmt`).

## MCP servers

This project ships its own MCP config at `.mcp.json` (project scope). It's intentionally isolated — **do not** rely on user-scope (`~/.claude.json`) servers; everything this repo needs is declared in `.mcp.json` and travels with the repo.

Wired up:

- **nixos** (`uvx mcp-nixos`) — searches nixpkgs packages, NixOS options, and home-manager options. Reach for this first when adding/changing a package or option instead of guessing attribute paths or option names; it's the cheapest way to confirm an option exists, its type, and its default before editing a module.
- **context7** (`npx -y @upstash/context7-mcp`) — fetches up-to-date docs for libraries. Use when you need the current behavior of a flake input or upstream project (e.g. home-manager or niri) and want to avoid stale knowledge.
- **github** (HTTPS, `https://api.githubcopilot.com/mcp/`) — PR/issue/Actions access. Use for anything the local `gh` CLI doesn't already cover cleanly (e.g. cross-referencing PR review threads, checking workflow run details for `update-flake-lock`).

If a server shows disconnected in `/mcp`, authenticate it there (github uses OAuth on first use).

## Commits

Subject-only Conventional Commits (e.g. `feat(home): add foo`, `fix(home): disable X`). **No body. No `Co-Authored-By` trailer.** Match the style in `git log`.

**One commit per concern.** Each commit covers a single logical change — don't fold unrelated edits into one commit just because they happened in the same session. If a working tree has accumulated mixed changes, stage and commit them separately. Squash follow-up fixups into the commit they belong to (interactive rebase or `git commit --fixup` + `git rebase --autosquash`) so the final history reads as one clean change per commit.

## Style

IMPORTANT: Try to preserve the original code and the logic of the original code as much as possible
