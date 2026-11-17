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
        self.homeModules.dev
      ];

      home = {
        packages = with pkgs; [
          neovim
          kitty
          bitwarden-desktop
          iina
          spotify
          spek
          vesktop
          obsidian
          fd
          flac
          ripgrep
          tree-sitter
          codex
          jujutsu
          btop
          fastfetch
          eza
        ];

        sessionVariables.NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
        sessionPath = [ "${config.home.homeDirectory}/.npm-global/bin" ];
      };

      programs = {
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
