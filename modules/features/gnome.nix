_: {
  flake.nixosModules.gnome =
    { pkgs, ... }:
    {
      services = {
        displayManager.gdm.enable = true;
        desktopManager.gnome.enable = true;

        gnome = {
          core-developer-tools.enable = false;
          games.enable = false;
          localsearch.enable = false;
        };
      };

      xdg.portal.config.gnome = {
        default = [ "gnome" ];
        "org.freedesktop.impl.portal.FileChooser" = [ "gtk" ];
      };

      environment.gnome.excludePackages = with pkgs; [
        gnome-tour
        gnome-user-docs

        nautilus
        gnome-console
        epiphany
        totem
      ];
    };
}
