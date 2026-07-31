{ self, ... }:
{
  flake.homeModules.personalMac =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        self.homeModules.kitty
        self.homeModules.nvim
        self.homeModules.zsh
      ];

      home = {
        username = self.lib.user.darwinUsername;
        homeDirectory = self.lib.user.darwinHomeDirectory;
        stateVersion = "25.11";

        packages = with pkgs; [
          neovim
          kitty
          fd
          ripgrep
          tree-sitter
          claude-code
          gh
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
          EDITOR = "nvim";
          VISUAL = "nvim";
          RUSTUP_HOME = "${config.home.homeDirectory}/.rustup";
          CARGO_HOME = "${config.home.homeDirectory}/.cargo";
        };

        sessionPath = [ "${config.home.homeDirectory}/.cargo/bin" ];
      };

      programs = {
        home-manager.enable = true;

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
          settings = {
            user = {
              name = self.lib.user.fullName;
              email = self.lib.user.email;
              useConfigOnly = true;
            };
            core = {
              editor = "nvim";
              untrackedCache = true;
            };
            credential.helper = "osxkeychain";
            color.ui = "auto";
            rebase.updateRefs = true;
            "credential \"https://github.com\"".helper = [
              ""
              "!gh auth git-credential"
            ];
            "credential \"https://gist.github.com\"".helper = [
              ""
              "!gh auth git-credential"
            ];
          };
        };
      };

      xdg = {
        enable = true;
        configFile = {
          "btop/btop.conf".source = ../files/macos/btop/btop.conf;
          "gh/config.yml".source =
            config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/modules/files/macos/gh/config.yml";
          "git/ignore".source = ../files/macos/git/ignore;
        };
      };

      manual.manpages.enable = false;
      programs.man.enable = false;

      assertions = [
        {
          assertion = pkgs.stdenv.hostPlatform.isDarwin;
          message = "homeModules.personalMac is only supported on macOS";
        }
      ];
    };
}
