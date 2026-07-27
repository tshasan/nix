_: {
  flake.homeModules.gnome =
    { pkgs, ... }:
    {
      dconf.settings = {
        "org/gnome/desktop/interface".color-scheme = "prefer-dark";
        "org/gnome/desktop/peripherals/mouse".accel-profile = "flat";

        "org/gnome/settings-daemon/plugins/media-keys".custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
        ];
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
          name = "Terminal";
          command = "kitty";
          binding = "<Super>t";
        };
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
          name = "Browser";
          command = "firefox";
          binding = "<Super>b";
        };

        "org/cinnamon/desktop/default-applications/terminal" = {
          exec = "kitty";
          exec-arg = "-e";
        };
      };

      programs.gnome-shell.extensions = [
        { package = pkgs.gnomeExtensions.appindicator; }
      ];
    };
}
