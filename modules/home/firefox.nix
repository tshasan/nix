{ inputs, ... }:
{
  flake.homeModules.firefox =
    { pkgs, ... }:
    let
      addons = (pkgs.extend inputs.firefox-addons.overlays.default).firefox-addons;
    in
    {
      programs.firefox = {
        enable = true;
        package = pkgs.firefox-bin;
        # Pin the pre-25.11 default: the live profile lives here, and letting
        # the new ~/.config/mozilla default take over would orphan it.
        configPath = ".mozilla/firefox";

        profiles."default" = {
          id = 0;
          isDefault = true;

          extensions.packages = with addons; [
            ublock-origin
            bitwarden
            sponsorblock
            return-youtube-dislikes
            istilldontcareaboutcookies
            violentmonkey
            dearrow
            improved-tube
          ];

          settings = {
            # Trust HM-installed extensions — don't sit disabled awaiting approval
            "extensions.autoDisableScopes" = 0;

            # Telemetry / data collection — off
            "toolkit.telemetry.enabled" = false;
            "toolkit.telemetry.archive.enabled" = false;
            "toolkit.telemetry.unified" = false;
            "toolkit.telemetry.server" = "";
            "app.shield.optoutstudies.enabled" = false;
            "app.normandy.enabled" = false;
            "app.normandy.api_url" = "";
            "datareporting.healthreport.uploadEnabled" = false;
            "datareporting.policy.dataSubmissionEnabled" = false;
            "browser.discovery.enabled" = false;
            "browser.newtabpage.activity-stream.feeds.telemetry" = false;
            "browser.newtabpage.activity-stream.telemetry" = false;
            "browser.ping-centre.telemetry" = false;

            # FxA Sync — bookmarks + history only
            "services.sync.engine.bookmarks" = true;
            "services.sync.engine.history" = true;
            "services.sync.engine.passwords" = false;
            "services.sync.engine.tabs" = false;
            "services.sync.engine.addons" = false;
            "services.sync.engine.prefs" = false;
            "services.sync.engine.addresses" = false;
            "services.sync.engine.creditcards" = false;

            # Passwords — Bitwarden owns these
            "signon.rememberSignons" = false;
            "signon.autofillForms" = false;
            "signon.firefoxRelay.feature" = "disabled";

            # Hardware video decode (NVIDIA-VAAPI is configured at system level).
            # GPU/DMABuf paths are enabled but not force-enabled, so Firefox can
            # fall back to software instead of crashing when the NVIDIA path fails.
            "media.ffmpeg.vaapi.enabled" = true;
            "media.rdd-ffmpeg.enabled" = true;
            "gfx.webrender.all" = true;
            "gfx.canvas.accelerated" = true;
            "gfx.webrender.compositor" = false;
            "gfx.webrender.compositor.force-enabled" = false;
            "widget.dmabuf.force-enabled" = false;

            # DRM (Netflix, Spotify web)
            "media.eme.enabled" = true;
            "media.gmp-widevinecdm.enabled" = true;

            # UX
            "browser.startup.page" = 1;
            "browser.warnOnQuit" = true;
            "browser.warnOnQuitShortcut" = true;
            "browser.aboutConfig.showWarning" = false;
            "browser.tabs.closeWindowWithLastTab" = false;
            "browser.urlbar.suggest.searches" = false;
            "browser.search.suggest.enabled" = false;
            "browser.contentblocking.category" = "strict";
            "extensions.pocket.enabled" = false;
            "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
            "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
            "browser.newtabpage.activity-stream.feeds.snippets" = false;

            # Bookmarks toolbar always visible (default is newtab-only)
            "browser.toolbars.bookmarks.visibility" = "always";

            # Quit → reopen lands on about:home, never on a restore card.
            # Session file still written so Ctrl+Shift+T and crash recovery work.
            "browser.startup.couldRestoreSession.count" = 0;
            "browser.sessionstore.resume_session_once" = false;

            # Perf — startup/RAM
            "accessibility.force_disabled" = 1;
            "browser.tabs.firefox-view" = false;
            "browser.tabs.firefox-view-next" = false;
            "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

            # Perf — background network noise
            "network.connectivity-service.enabled" = false;
            "network.captive-portal-service.enabled" = false;
            "app.update.auto" = false;
            "app.update.background.scheduling.enabled" = false;

            # Perf — HW decode (explicit; nix-owned NVIDIA-VAAPI stack)
            "media.av1.enabled" = true;
            "media.rdd-process.enabled" = true;
            "media.hardwaremediakeys.enabled" = true;

            # 180 Hz feel
            "general.smoothScroll.msdPhysics.enabled" = true;
            "apz.frame_delay.enabled" = false;
            "gfx.webrender.precache-shaders" = true;

            # HTTPS by default
            "dom.security.https_only_mode" = true;
            "dom.security.https_only_mode_ever_enabled" = true;

            # Wayland
            "widget.wayland.fractional-scale.enabled" = true;
            "apz.allow_zooming" = true;

            # System font integration
            "font.name.sans-serif.x-western" = "Atkinson Hyperlegible";
            "font.name.serif.x-western" = "Atkinson Hyperlegible";
            "font.name.monospace.x-western" = "AtkynsonMono Nerd Font Mono";

            # Match dark system theme
            "ui.systemUsesDarkTheme" = 1;

            # Bitwarden owns secrets — silence the rest of the password/autofill UI
            "signon.management.page.breach-alerts.enabled" = false;
            "dom.forms.autocomplete.formautofill" = true;

            # Cache: 1 GB memory, 512 MB image (32 GB RAM system)
            "browser.cache.memory.capacity" = 1048576; # KB
            "image.cache.size" = 536870912; # bytes

            # Session snapshot every 60s instead of 15s — less disk wear
            "browser.sessionstore.interval" = 60000;

            # Downloads go straight to ~/Downloads, no per-type prompts
            "browser.download.useDownloadDir" = true;
            "browser.download.always_ask_before_handling_new_types" = false;

            # Use XDG portal for file picker (Save As, upload dialogs) and
            # folder reveal (Downloads → Open Folder → Nemo via inode/directory)
            "widget.use-xdg-desktop-portal.file-picker" = 1;
            "widget.use-xdg-desktop-portal.open-uri" = 1;
          };
        };
      };

      xdg.mimeApps = {
        enable = true;
        defaultApplications = {
          "text/html" = "firefox.desktop";
          "x-scheme-handler/http" = "firefox.desktop";
          "x-scheme-handler/https" = "firefox.desktop";
          "x-scheme-handler/about" = "firefox.desktop";
          "x-scheme-handler/unknown" = "firefox.desktop";

          "x-scheme-handler/mailto" = "thunderbird.desktop";
          "message/rfc822" = "thunderbird.desktop";

          "image/jpeg" = "imv.desktop";
          "image/png" = "imv.desktop";
          "image/gif" = "imv.desktop";
          "image/webp" = "imv.desktop";
          "image/bmp" = "imv.desktop";
          "image/tiff" = "imv.desktop";
          "image/avif" = "imv.desktop";

          "video/mp4" = "mpv.desktop";
          "video/x-matroska" = "mpv.desktop";
          "video/webm" = "mpv.desktop";
          "video/avi" = "mpv.desktop";
          "video/quicktime" = "mpv.desktop";
          "video/x-msvideo" = "mpv.desktop";

          "audio/mpeg" = "mpv.desktop";
          "audio/ogg" = "mpv.desktop";
          "audio/flac" = "mpv.desktop";
          "audio/x-wav" = "mpv.desktop";
          "audio/opus" = "mpv.desktop";

          "application/pdf" = "org.pwmt.zathura.desktop";

          "application/x-bittorrent" = "org.qbittorrent.qBittorrent.desktop";
          "x-scheme-handler/magnet" = "org.qbittorrent.qBittorrent.desktop";

          "inode/directory" = "nemo.desktop";

          "text/plain" = "nvim.desktop";
          "text/english" = "nvim.desktop";
          "text/markdown" = "nvim.desktop";
          "text/x-makefile" = "nvim.desktop";
          "text/x-c" = "nvim.desktop";
          "text/x-c++" = "nvim.desktop";
          "text/x-csrc" = "nvim.desktop";
          "text/x-chdr" = "nvim.desktop";
          "text/x-c++src" = "nvim.desktop";
          "text/x-c++hdr" = "nvim.desktop";
          "text/x-java" = "nvim.desktop";
          "text/x-python" = "nvim.desktop";
          "text/x-script.python" = "nvim.desktop";
          "text/x-shellscript" = "nvim.desktop";
          "text/x-lua" = "nvim.desktop";
          "text/x-go" = "nvim.desktop";
          "text/x-rust" = "nvim.desktop";
          "text/x-tex" = "nvim.desktop";
          "text/x-sql" = "nvim.desktop";
          "text/css" = "nvim.desktop";
          "text/javascript" = "nvim.desktop";
          "text/xml" = "nvim.desktop";
          "text/csv" = "nvim.desktop";
          "text/tab-separated-values" = "nvim.desktop";
          "application/json" = "nvim.desktop";
          "application/toml" = "nvim.desktop";
          "application/yaml" = "nvim.desktop";
          "application/x-yaml" = "nvim.desktop";
          "application/xml" = "nvim.desktop";
          "application/javascript" = "nvim.desktop";
          "application/x-shellscript" = "nvim.desktop";
          "application/x-perl" = "nvim.desktop";

          "application/zip" = "org.gnome.FileRoller.desktop";
          "application/x-zip-compressed" = "org.gnome.FileRoller.desktop";
          "application/x-zip" = "org.gnome.FileRoller.desktop";
          "application/x-rar" = "org.gnome.FileRoller.desktop";
          "application/x-rar-compressed" = "org.gnome.FileRoller.desktop";
          "application/vnd.rar" = "org.gnome.FileRoller.desktop";
          "application/x-7z-compressed" = "org.gnome.FileRoller.desktop";
          "application/x-tar" = "org.gnome.FileRoller.desktop";
          "application/x-compressed-tar" = "org.gnome.FileRoller.desktop";
          "application/gzip" = "org.gnome.FileRoller.desktop";
          "application/x-bzip-compressed-tar" = "org.gnome.FileRoller.desktop";
          "application/x-xz-compressed-tar" = "org.gnome.FileRoller.desktop";
          "application/x-zstd-compressed-tar" = "org.gnome.FileRoller.desktop";
        };
      };
    };
}
