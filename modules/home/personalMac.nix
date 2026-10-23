{ self, ... }:
{
  flake.homeModules.personalMac =
    {
      config,
      pkgs,
      ...
    }:
    {
      imports = [
        self.homeModules.darwinBase
        self.homeModules.zsh
      ];

      home = {
        packages = with pkgs; [
          neovim
          kitty
          bitwarden-desktop
          iina
          spotify
          vesktop
          fd
          ripgrep
          tree-sitter
          claude-code
          codex
          gh
          jujutsu
          jq
          lazygit
          eza
          nnn
          zoxide
          bun
          deno
          pnpm
          nodejs
          python3
          uv
          rustup
          cmake
          ninja
          pkg-config
        ];

        sessionVariables = {
          RUSTUP_HOME = "${config.home.homeDirectory}/.rustup";
          CARGO_HOME = "${config.home.homeDirectory}/.cargo";
          NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
        };

        sessionPath = [
          "${config.home.homeDirectory}/.cargo/bin"
          "${config.home.homeDirectory}/.npm-global/bin"
        ];
      };

      programs = {
        fzf.enable = true;
        bat.enable = true;

        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };

        nh = {
          enable = true;
          flake = "${config.home.homeDirectory}/nix";
          clean = {
            enable = true;
            extraArgs = "--keep-since 7d --keep 5";
          };
        };

        git = {
          enable = true;
          lfs.enable = true;
          settings.user = {
            name = self.lib.user.fullName;
            email = self.lib.user.email;
          };
        };
      };

      targets.darwin = {
        copyApps.enable = false;
        linkApps.enable = true;
      };
    };
}
