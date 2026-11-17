{ self, ... }:
{
  flake.homeModules.macbook =
    { lib, pkgs, ... }:
    let
      inherit (self.lib.user) username homeDirectory;
      firefox = "${homeDirectory}/.local/opt/firefox/firefox";
    in
    {
      imports = [
        self.homeModules.kitty
        self.homeModules.zsh
        self.homeModules.git
        self.homeModules.firefox
        self.homeModules.thunderbird
        self.homeModules.dev
        self.homeModules.mpv
        self.homeModules.desktop
        self.homeModules.gnome
        self.homeModules.theming
        self.homeModules.qbittorrent
        self.homeModules.nvim
      ];

      home = {
        inherit username homeDirectory;
        stateVersion = "26.11";

        packages = with pkgs; [
          google-chrome
          gnupg
          vesktop
          eza
          gnome-disk-utility
        ];
      };

      # Thunderbird and mpv use the shared defaults: the source-built
      # Thunderbird and software decoding with a safe hardware fallback.
      # Firefox is the official Mozilla tarball in ~/.local/opt/firefox so its
      # own updater ships releases the day they land; Home Manager still owns
      # the profile (settings and extensions).
      programs = {
        firefox = {
          package = null;
          profiles.default.settings."browser.tabs.unloadOnLowMemory" = true;
        };
        mpv.config.hwdec = "auto-safe";

        home-manager.enable = true;
      };

      xdg.desktopEntries.firefox = {
        name = "Firefox";
        genericName = "Web Browser";
        exec = "${firefox} %u";
        icon = "${homeDirectory}/.local/opt/firefox/browser/chrome/icons/default/default128.png";
        categories = [
          "Network"
          "WebBrowser"
        ];
        mimeType = [
          "text/html"
          "x-scheme-handler/http"
          "x-scheme-handler/https"
        ];
      };

      dconf.settings = {
        "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1".command =
          lib.mkForce firefox;

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
