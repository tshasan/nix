{ self, ... }:
{
  flake.homeModules.darwinBase =
    {
      config,
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
      };

      programs = {
        home-manager.enable = true;
        man.enable = false;

        # Shared by both Macs; personalMac enables programs.git, workMac renders
        # these into ~/.gitconfig itself.
        git.settings = {
          user.useConfigOnly = true;
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

      assertions = [
        {
          assertion = pkgs.stdenv.hostPlatform.isDarwin;
          message = "homeModules.darwinBase is only supported on macOS";
        }
      ];
    };
}
