{ self, ... }:
{
  flake.nixosModules.macbookConfiguration = _: {
    imports = [
      self.nixosModules.macbookHardware
      self.nixosModules.workstation
    ];

    boot.loader = {
      systemd-boot = {
        enable = true;
        # The Asahi installer's ESP is small and every generation carries
        # its own full kernel and initrd.
        configurationLimit = 3;
      };
      timeout = 1;
    };

    networking = {
      hostName = "macbook";
      networkmanager = {
        enable = true;
        # wpa_supplicant cannot do WPA3 on the Broadcom chip.
        wifi.backend = "iwd";
      };
    };

    home-manager.users.${self.lib.user.username}.imports = [
      self.homeModules.user
      self.homeModules.macbookHome
    ];

    system.stateVersion = "26.11";
  };
}
