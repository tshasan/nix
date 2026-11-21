{ self, ... }:
{
  flake.nixosModules.desktopConfiguration =
    { ... }:
    {
      imports = [
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
      ];

      boot.loader = {
        systemd-boot = {
          enable = true;
          configurationLimit = 5;
          # Otherwise anyone at the boot menu can append init=/bin/sh.
          editor = false;
          edk2-uefi-shell.enable = true;
        };
        efi.canTouchEfiVariables = true;
        timeout = 1;
      };

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
