{ self, inputs, ... }:
{
  flake.nixosModules.autoUpgrade =
    { config, pkgs, ... }:
    let
      # The upgrade runs as root, so post alerts into the user's session.
      notify = title: body: ''
        ${config.systemd.package}/bin/systemd-run --machine=${self.lib.user.username}@ --user --quiet \
          ${pkgs.libnotify}/bin/notify-send --urgency=critical ${title} ${body}
      '';
    in
    {
      system.autoUpgrade = {
        enable = true;
        flake = self.lib.user.flakeUrl;
        operation = "boot";
        dates = "daily";
        randomizedDelaySec = "45min";
        allowReboot = false;
      };

      # Read at runtime by the staleness check, so it reflects the system
      # that is actually active rather than the last one built.
      environment.etc."nixpkgs-last-modified".text = toString inputs.nixpkgs.lastModified;

      systemd = {
        services = {
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
            script = notify "'NixOS auto-upgrade failed'" "'Check journalctl -u nixos-upgrade'";
          };

          # Catches every way the pipeline can silently stall (CI down, a
          # wrong flake URL, a switch that exits 0 without activating).
          nixos-upgrade-stale = {
            serviceConfig.Type = "oneshot";
            script = ''
              age=$(( ($(date +%s) - $(cat /etc/nixpkgs-last-modified)) / 86400 ))
              if [ "$age" -gt 7 ]; then
                ${notify "'NixOS is out of date'" "\"The running system's nixpkgs is $age days old\""}
              fi
            '';
          };
        };

        # After boot-time catch-up runs and their retries have had a chance.
        timers.nixos-upgrade-stale = {
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "2h";
            OnUnitActiveSec = "1d";
          };
        };
      };
    };
}
