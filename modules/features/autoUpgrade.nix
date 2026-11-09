{ self, ... }:
{
  flake.nixosModules.autoUpgrade =
    { config, pkgs, ... }:
    {
      system.autoUpgrade = {
        enable = true;
        flake = self.lib.user.flakeUrl;
        dates = "daily";
        randomizedDelaySec = "45min";
        allowReboot = false;
      };

      # The upgrade runs as root, so post the failure into the user's session.
      systemd.services = {
        nixos-upgrade.onFailure = [ "nixos-upgrade-failed.service" ];
        nixos-upgrade-failed = {
          serviceConfig.Type = "oneshot";
          script = ''
            ${config.systemd.package}/bin/systemd-run --machine=${self.lib.user.username}@ --user --quiet \
              ${pkgs.libnotify}/bin/notify-send --urgency=critical \
              'NixOS auto-upgrade failed' 'Check journalctl -u nixos-upgrade'
          '';
        };
      };
    };
}
