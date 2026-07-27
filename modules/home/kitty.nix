_: {
  flake.homeModules.kitty =
    { lib, pkgs, ... }:
    {
      home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [ pkgs.kitty ];

      xdg.configFile.kitty = {
        source = ../files/shared/kitty;
        recursive = true;
      };
    };
}
