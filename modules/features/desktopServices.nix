_: {
  flake.nixosModules.desktopServices =
    { pkgs, ... }:
    {
      programs.dconf.enable = true;

      services = {
        dbus.implementation = "broker";
        udisks2.enable = true;
        fwupd.enable = true;
        ratbagd.enable = true;
      };

      environment.systemPackages = [ pkgs.piper ];
    };
}
