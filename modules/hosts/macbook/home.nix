_: {
  flake.homeModules.macbookHome =
    { pkgs, ... }:
    {
      home = {
        stateVersion = "26.11";

        packages = with pkgs; [
          gnupg
          vesktop
        ];
      };

      # Thunderbird and mpv use the shared defaults: the source-built
      # Thunderbird and software decoding with a safe hardware fallback.
      programs = {
        firefox.profiles.default.settings."browser.tabs.unloadOnLowMemory" = true;
        mpv.config.hwdec = "auto-safe";
      };

      dconf.settings = {
        "org/gnome/desktop/peripherals/touchpad" = {
          tap-to-click = true;
          natural-scroll = true;
          disable-while-typing = true;
        };

        "org/gnome/mutter".experimental-features = [
          "scale-monitor-framebuffer"
          "xwayland-native-scaling"
        ];
      };
    };
}
