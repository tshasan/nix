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

      # The shared modules are tuned for the x86_64 NVIDIA desktop with
      # 32 GB of RAM, and Thunderbird's binary build is x86_64-only.
      # Firefox is the official Mozilla tarball in ~/.local/opt/firefox so its
      # own updater ships releases the day they land; Home Manager still owns
      # the profile (settings and extensions).
      programs = {
        firefox = {
          package = lib.mkForce null;
          profiles.default.settings = {
            "app.update.auto" = lib.mkForce true;
            "browser.cache.memory.capacity" = lib.mkForce (-1);
            "image.cache.size" = lib.mkForce 5242880;
            "browser.tabs.unloadOnLowMemory" = true;
          };
        };
        thunderbird.package = lib.mkForce pkgs.thunderbird;
        mpv.config.hwdec = lib.mkForce "auto-safe";

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
