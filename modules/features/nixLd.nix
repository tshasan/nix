_: {
  # Runs the official Firefox and Tor Browser tarballs unpatched so their
  # built-in updaters apply signed updates the day they ship. The
  # libraries mirror nixpkgs' tor-browser runtime path, which covers both.
  flake.nixosModules.nixLd =
    { pkgs, ... }:
    {
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
    };
}
