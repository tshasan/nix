{ self, ... }:
{
  flake.homeModules.user =
    { pkgs, ... }:
    let
      inherit (self.lib.user) username homeDirectory;
    in
    {
      imports = [
        self.homeModules.kitty
        self.homeModules.zsh
        self.homeModules.git
        self.homeModules.firefox
        self.homeModules.thunderbird
        self.homeModules.dev
        self.homeModules.mpv
        self.homeModules.desktop
        self.homeModules.gnome
        self.homeModules.theming
        self.homeModules.qbittorrent
        self.homeModules.nvim
      ];

      # Shared by every NixOS GNOME machine. Host-only apps and each host's
      # stateVersion live in hosts/<host>/home.nix.
      home = {
        inherit username homeDirectory;

        packages = with pkgs; [
          google-chrome
          eza
          gnome-disk-utility
        ];
      };

      programs.home-manager.enable = true;
    };
}
