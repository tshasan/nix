{ self, inputs, ... }:
{
  flake.nixosModules.desktopConfiguration =
    { lib, pkgs, ... }:
    {
      imports = [
        inputs.lanzaboote.nixosModules.lanzaboote
        self.nixosModules.desktopHardware
        self.nixosModules.cachyos
        self.nixosModules.workstation
        self.nixosModules.ssh
        self.nixosModules.audio
        self.nixosModules.containers
        self.nixosModules.screenTools
        self.nixosModules.desktopServices
        self.nixosModules.gaming
        self.nixosModules.autoUpgrade
        self.nixosModules.windowsDualBoot
      ];

      boot.loader = {
        # Lanzaboote installs a signed systemd-boot and reads these settings.
        systemd-boot = {
          enable = lib.mkForce false;
          configurationLimit = 5;
          # Otherwise anyone at the boot menu can append init=/bin/sh.
          editor = false;
          consoleMode = "max";
        };
        efi.canTouchEfiVariables = true;
        timeout = 1;
      };

      boot.lanzaboote = {
        enable = true;
        pkiBundle = "/var/lib/sbctl";
      };
      environment.systemPackages = [
        pkgs.sbctl
        pkgs.efibootmgr
        pkgs.ddcutil
        pkgs.nvme-cli
        pkgs.i2c-tools
      ];

      hardware.i2c.enable = true;
      services.smartd.enable = true;

      # The AW3226Q's EDID marks 4K@60 as preferred, so without this the GDM
      # greeter runs at 60 Hz and 1.0 scale instead of the session's mode.
      systemd.tmpfiles.rules = [
        "d /var/lib/gdm/seat0/config - gdm gdm -"
        "L+ /var/lib/gdm/seat0/config/monitors.xml - - - - ${../../files/gnome/monitors-desktop.xml}"
      ];

      networking = {
        hostName = "desktop";
        networkmanager.enable = true;
      };

      programs.librepods.enable = true;
      programs.coolercontrol.enable = true;
      users.users.${self.lib.user.username}.extraGroups = [ "librepods" ];

      home-manager.users.${self.lib.user.username}.imports = [
        self.homeModules.user
        self.homeModules.desktopHome
      ];

      system.stateVersion = "25.11";
    };
}
