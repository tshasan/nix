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

        # Live symlinks to the checkout so pi settings and patches survive
        # `pi update` without needing a home-manager switch.
        file =
          let
            piFiles = "${config.home.homeDirectory}/${self.lib.user.flakeCheckout}/modules/files/macos/pi";
          in
          lib.genAttrs
            [
              "settings.json"
              "models.json"
              "mcp.json"
              "mcp-adapter.json"
              "model-router.json"
              "patches"
            ]
            (name: {
              source = config.lib.file.mkOutOfStoreSymlink "${piFiles}/${name}";
            });
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
