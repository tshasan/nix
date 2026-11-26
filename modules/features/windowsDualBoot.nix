_: {
  # Windows on its own disk: a systemd-boot menu entry for it, plus
  # "Restart to BIOS" and "Restart to Windows" in the GNOME power menu.
  flake.nixosModules.windowsDualBoot =
    { pkgs, ... }:
    {
      # systemd-boot only lists Windows when its boot manager is on the same
      # ESP, and Lanzaboote has no custom entries. Find the Windows ESP and
      # mirror its boot manager here every boot, so Windows updates carry over.
      systemd.services.windows-bootmgr = {
        wantedBy = [ "multi-user.target" ];
        unitConfig.RequiresMountsFor = "/boot";
        path = [
          pkgs.util-linux
          pkgs.rsync
        ];
        serviceConfig = {
          Type = "oneshot";
          PrivateMounts = true;
          RuntimeDirectory = "windows-esp";
        };
        script = ''
          boot=$(findmnt -no SOURCE /boot)
          lsblk -lnpo PATH,PARTTYPE | while read -r dev type; do
            [ "$type" = c12a7328-f81f-11d2-ba4b-00a0c93ec93b ] && [ "$dev" != "$boot" ] || continue
            mount -o ro "$dev" /run/windows-esp || continue
            if [ -f /run/windows-esp/EFI/Microsoft/Boot/bootmgfw.efi ]; then
              rsync -r --times --modify-window=2 --delete /run/windows-esp/EFI/Microsoft/ /boot/EFI/Microsoft/
              exit 0
            fi
            umount /run/windows-esp
          done
        '';
      };

      home-manager.sharedModules = [
        {
          programs.gnome-shell.extensions = [
            {
              id = "restart-to@nix";
              package = pkgs.runCommand "gnome-shell-extension-restart-to" { } ''
                mkdir -p $out/share/gnome-shell/extensions
                cp -r ${../files/gnome/restart-to} $out/share/gnome-shell/extensions/restart-to@nix
              '';
            }
          ];
        }
      ];
    };
}
