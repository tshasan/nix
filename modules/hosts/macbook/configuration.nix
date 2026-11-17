{ self, ... }:
{
  flake.nixosModules.macbookConfiguration =
    { pkgs, ... }:
    {
      imports = [
        self.nixosModules.macbookHardware
        self.nixosModules.nix
        self.nixosModules.locale
        self.nixosModules.basePackages
        self.nixosModules.users
        self.nixosModules.homeManager
        self.nixosModules.fonts
        self.nixosModules.viewers
        self.nixosModules.nemo
        self.nixosModules.bluetooth
        self.nixosModules.gnome
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

      # Runs the official Firefox and Tor Browser tarballs unpatched so their
      # built-in updaters apply signed updates the day they ship. The
      # libraries mirror nixpkgs' tor-browser runtime path, which covers both.
      programs.nix-ld = {
        enable = true;
        libraries = with pkgs; [
          alsa-lib
          atk
          cairo
          dbus
          dbus-glib
          fontconfig
          freetype
          gdk-pixbuf
          glib
          gtk3
          libxcb
          libx11
          libxext
          libxrender
          libxt
          libxtst
          libgbm
          pango
          pciutils
          stdenv.cc.cc
          zlib
          libnotify
          libxkbcommon
          libdrm
          libGL
          pipewire
          libpulseaudio
          libva
          ffmpeg_8
        ];
      };

      home-manager.users.${self.lib.user.username}.imports = [ self.homeModules.macbook ];

      system.stateVersion = "26.11";
    };
}
