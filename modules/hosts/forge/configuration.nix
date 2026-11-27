{ self, ... }:
{
  # A closed laptop in a cupboard: no GNOME, no desktop services, no fonts, no
  # viewers, no audio. Only what Forgejo, SearXNG, and sshd need.
  flake.nixosModules.forgeConfiguration = _: {
    imports = [
      self.nixosModules.forgeHardware
      self.nixosModules.nix
      self.nixosModules.locale
      self.nixosModules.basePackages
      self.nixosModules.users
      self.nixosModules.homeManager
      self.nixosModules.ssh
      self.nixosModules.server
    ];

    boot.loader = {
      systemd-boot = {
        enable = true;
        # The Asahi installer's ESP is small and every generation carries
        # its own full kernel and initrd.
        configurationLimit = 3;
        # Otherwise anyone at the boot menu can append init=/bin/sh.
        editor = false;
      };
      timeout = 1;
    };

    networking = {
      hostName = "forge";
      networkmanager = {
        enable = true;
        # wpa_supplicant cannot do WPA3 on the Broadcom chip.
        wifi.backend = "iwd";
      };
    };

    # The firewall blocks 22 by default, and ssh is the only way into a
    # headless box.
    services.openssh.openFirewall = true;

    # Nobody opens the lid. Make "never suspend" a system fact instead of a
    # desktop setting: a suspended server is a down server.
    services.logind.settings.Login.HandleLidSwitch = "ignore";
    systemd.sleep.settings.Sleep.AllowSuspend = "no";

    home-manager.users.${self.lib.user.username}.imports = [
      self.homeModules.forgeHome
    ];

    system.stateVersion = "26.11";
  };
}
