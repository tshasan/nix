_: {
  flake.homeModules.theming =
    { pkgs, ... }:
    {
      gtk = {
        enable = true;
        gtk4.theme = null;
        theme = {
          name = "adw-gtk3-dark";
          package = pkgs.adw-gtk3;
        };
        iconTheme = {
          name = "Papirus-Dark";
          package = pkgs.papirus-icon-theme;
        };
      };

      home.pointerCursor = {
        enable = true;
        name = "Adwaita";
        size = 24;
        package = pkgs.adwaita-icon-theme;
        gtk.enable = true;
      };

      qt = {
        enable = true;
        platformTheme.name = "adwaita";
        style = {
          name = "adwaita-dark";
          package = pkgs.adwaita-qt;
        };
      };

      home.packages = [ pkgs.adwaita-qt6 ];
    };
}
