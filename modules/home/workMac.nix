{ self, ... }:
{
  flake.homeModules.workMac =
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
      ];

      home = {
        username = self.lib.user.darwinUsername;
        homeDirectory = self.lib.user.darwinHomeDirectory;
        stateVersion = "25.11";

        sessionVariables = {
          EDITOR = "nvim";
          VISUAL = "nvim";
        };

        file = {
          ".gitconfig".text = lib.generators.toGitINI {
            user.useConfigOnly = true;
            core = {
              editor = "nvim";
              untrackedCache = true;
            };
            credential.helper = "osxkeychain";
            color.ui = "auto";
            "filter \"lfs\"" = {
              clean = "git-lfs clean -- %f";
              smudge = "git-lfs smudge -- %f";
              process = "git-lfs filter-process";
              required = true;
            };
            include.path = "~/.config/git/work.conf";
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
          ".p10k.zsh".source = ../files/zsh/p10k.zsh;
          ".profile".source = ../files/macos/zsh/profile;
          ".zprofile".source = ../files/macos/zsh/zprofile;
          ".zshenv".source = ../files/macos/zsh/zshenv;
          ".zshrc".source = ../files/macos/zsh/zshrc;
        };
      };

      programs.home-manager.enable = true;

      launchd.agents.home-manager-auto-upgrade = {
        enable = true;
        config = {
          ProgramArguments = [
            "${config.programs.home-manager.package}/bin/home-manager"
            "switch"
            "--flake"
            "${self.lib.user.flakeUrl}#work-mac"
            "--refresh"
            "-b"
            "hm-backup"
          ];
          RunAtLoad = true;
          ProcessType = "Background";
          LowPriorityIO = true;
          EnvironmentVariables.PATH = "/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/home-manager-auto-upgrade.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/home-manager-auto-upgrade.log";
        };
      };

      manual.manpages.enable = false;
      programs.man.enable = false;

      xdg = {
        enable = true;

        configFile = {
          "btop/btop.conf".source = ../files/macos/btop/btop.conf;
          "gh/config.yml".source =
            config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/modules/files/macos/gh/config.yml";
          "git/ignore".source = ../files/macos/git/ignore;
          "nix/nix.conf".source = ../files/macos/nix/nix.conf;
          "zsh/common.zsh".source = ../files/shared/zsh/common.zsh;
          "zsh/local/gecko.zsh".source = ../files/macos/zsh/gecko.zsh;
        };
      };

      assertions = [
        {
          assertion = pkgs.stdenv.hostPlatform.isDarwin;
          message = "homeModules.workMac is only supported on macOS";
        }
      ];
    };
}
