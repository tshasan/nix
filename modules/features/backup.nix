{ self, ... }:
{
  # Restic snapshots of home onto a removable ext4 drive labelled "backup".
  # Runs when the drive is plugged in and daily while it stays connected;
  # without the drive the timer skips cleanly instead of failing.
  #
  # One-time setup: `mkfs.ext4 -L backup /dev/sdX1`, then put the repository
  # password in /var/lib/restic/password (mode 600, root) and keep a copy in
  # Bitwarden; the snapshots are unrecoverable without it.
  flake.nixosModules.backup =
    { config, pkgs, ... }:
    let
      inherit (self.lib.user) username homeDirectory;
      drive = "dev-disk-by\\x2dlabel-backup.device";
    in
    {
      fileSystems."/mnt/backup" = {
        device = "/dev/disk/by-label/backup";
        fsType = "ext4";
        options = [
          "noauto"
          "nofail"
          "x-systemd.automount"
          "x-systemd.idle-timeout=10min"
          "x-systemd.device-timeout=5s"
        ];
      };

      services.restic.backups.home = {
        repository = "/mnt/backup/restic";
        passwordFile = "/var/lib/restic/password";
        initialize = true;
        paths = [ homeDirectory ];
        exclude = [
          "${homeDirectory}/.cache"
          "${homeDirectory}/.local/share/Trash"
          "${homeDirectory}/.local/share/Steam"
          "${homeDirectory}/.steam"
          "${homeDirectory}/.local/share/containers"
          "${homeDirectory}/.local/opt"
          "${homeDirectory}/.rustup"
          "${homeDirectory}/.cargo/registry"
          "node_modules"
          "target"
        ];
        pruneOpts = [
          "--keep-daily 7"
          "--keep-weekly 4"
          "--keep-monthly 6"
        ];
        timerConfig = {
          OnCalendar = "daily";
          Persistent = true;
        };
      };

      systemd.services = {
        restic-backups-home = {
          wantedBy = [ drive ];
          after = [ drive ];
          onFailure = [ "restic-backups-home-failed.service" ];
          unitConfig = {
            ConditionPathExists = "/dev/disk/by-label/backup";
            RequiresMountsFor = "/mnt/backup";
          };
        };
        restic-backups-home-failed = {
          serviceConfig.Type = "oneshot";
          script = ''
            ${config.systemd.package}/bin/systemd-run --machine=${username}@ --user --quiet \
              ${pkgs.libnotify}/bin/notify-send --urgency=critical \
              'Backup failed' 'Check journalctl -u restic-backups-home'
          '';
        };
      };
    };
}
