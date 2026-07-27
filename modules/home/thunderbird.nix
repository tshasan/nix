_: {
  flake.homeModules.thunderbird =
    { pkgs, ... }:
    {
      programs.thunderbird = {
        enable = true;
        package = pkgs.thunderbird-bin;

        profiles."default" = {
          isDefault = true;

          settings = {
            # Trust HM-installed extensions
            "extensions.autoDisableScopes" = 0;

            # Telemetry / data collection — off
            "toolkit.telemetry.enabled" = false;
            "toolkit.telemetry.unified" = false;
            "toolkit.telemetry.archive.enabled" = false;
            "toolkit.telemetry.server" = "";
            "datareporting.healthreport.uploadEnabled" = false;
            "datareporting.policy.dataSubmissionEnabled" = false;
            "app.shield.optoutstudies.enabled" = false;
            "app.normandy.enabled" = false;
            "app.normandy.api_url" = "";

            # Nix owns updates
            "app.update.enabled" = false;
            "app.update.auto" = false;
            "app.update.background.scheduling.enabled" = false;

            # Don't pester about being default — xdg.mimeApps handles that
            "mail.shell.checkDefaultClient" = false;

            # Skip the start page (release notes etc)
            "mailnews.start_page.enabled" = false;

            # Security — never auto-load remote images (tracking pixels)
            "mailnews.message_display.disable_remote_image" = true;
            "mail.phishing.detection.enabled" = true;

            # Threaded view by default
            "mailnews.default_view_flags" = 1;

            # HTTPS-only for embedded web fetches
            "dom.security.https_only_mode" = true;

            # Match dark system theme
            "ui.systemUsesDarkTheme" = 1;

            # System font integration (mirrors firefox.nix)
            "font.name.sans-serif.x-western" = "Atkinson Hyperlegible";
            "font.name.serif.x-western" = "Atkinson Hyperlegible";
            "font.name.monospace.x-western" = "AtkynsonMono Nerd Font Mono";

            # UX
            "browser.aboutConfig.showWarning" = false;
            "extensions.pocket.enabled" = false;

            # XDG portal for attach/save dialogs (Wayland)
            "widget.use-xdg-desktop-portal.file-picker" = 1;

            # Wayland
            "widget.wayland.fractional-scale.enabled" = true;
          };
        };
      };
    };
}
