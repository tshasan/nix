_: {
  # Runs the official Firefox and Tor Browser tarballs unpatched so their
  # built-in updaters apply signed updates the day they ship. The
  # libraries mirror nixpkgs' tor-browser runtime path, plus the X11 ones
  # libxul and the gfxtest GPU probe link directly.
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
          libxcomposite
          libxcursor
          libxdamage
          libxext
          libxfixes
          libxi
          libxrandr
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
