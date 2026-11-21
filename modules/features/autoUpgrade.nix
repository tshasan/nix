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
        # Retry transient failures (no network yet at boot) instead of
        # waiting a day; notify only once the retries are used up.
        nixos-upgrade = {
          onFailure = [ "nixos-upgrade-failed.service" ];
          startLimitBurst = 3;
          startLimitIntervalSec = 3 * 60 * 60;
          serviceConfig = {
            Restart = "on-failure";
            RestartSec = "30min";
          };
        };
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
