{ self, ... }:
{
  flake.nixosModules.desktopConfiguration =
    { ... }:
    {
      imports = [
        self.nixosModules.desktopHardware
        self.nixosModules.cachyos
        self.nixosModules.nix
        self.nixosModules.locale
        self.nixosModules.ssh
        self.nixosModules.basePackages
        self.nixosModules.users
        self.nixosModules.homeManager
        self.nixosModules.audio
        self.nixosModules.fonts
        self.nixosModules.viewers
        self.nixosModules.nemo
        self.nixosModules.bluetooth
        self.nixosModules.containers
        self.nixosModules.screenTools
        self.nixosModules.desktopServices
        self.nixosModules.gaming
        self.nixosModules.gnome
        self.nixosModules.autoUpgrade
      ];

      boot.loader = {
        systemd-boot = {
          enable = true;
          configurationLimit = 5;
        };
        efi.canTouchEfiVariables = true;
        timeout = 1;
      };

      networking = {
        hostName = "desktop";
        networkmanager.enable = true;
      };

      home-manager.users.${self.lib.user.username}.imports = [ self.homeModules.user ];

      system.stateVersion = "25.11";
    };
}
