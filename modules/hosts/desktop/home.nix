_: {
  # Home settings tied to this machine: its x86_64-only apps and binary
  # builds, the NVIDIA VA-API stack, 32 GB of RAM, and a 4K 165 Hz display.
  flake.homeModules.desktopHome =
    { pkgs, ... }:
    {
      home = {
        stateVersion = "25.11";

        packages = with pkgs; [
          (prismlauncher.override {
            additionalPrograms = [ ffmpeg ];

            jdks = [
              graalvmPackages.graalvm-ce
              (zulu8.override { gtkSupport = false; })
              zulu17
              zulu
            ];
          })
          spotify
          protontricks
          dualsensectl
          pwvucontrol
          qpwgraph
        ];
      };

      services.easyeffects = {
        enable = true;
        extraPresets = {
          Flat.output = {
            blocklist = [ ];
            plugins_order = [ ];
          };
          "HiFiMan Edition XS" = builtins.fromJSON (
            builtins.readFile ../../files/easyeffects/hifiman-edition-xs.json
          );
          "HiFiMan Edition XS (Kuulokenurkka)" = builtins.fromJSON (
            builtins.readFile ../../files/easyeffects/hifiman-edition-xs-kuulokenurkka.json
          );
          "HiFiMan Edition XS (Super Review)" = builtins.fromJSON (
            builtins.readFile ../../files/easyeffects/hifiman-edition-xs-super-review.json
          );
          "HiFiMan Edition XS (Rtings)" = builtins.fromJSON (
            builtins.readFile ../../files/easyeffects/hifiman-edition-xs-rtings.json
          );
        };
        # Outputs without an autoload file (BlackShark, HDMI) get Flat instead
        # of keeping whatever preset was loaded last. The mic is left alone;
        # Discord handles noise suppression.
        settings.Window = {
          processAllInputs = false;
          outputAutoloadingUsesFallback = true;
          outputAutoloadingFallbackPreset = "Flat";
        };
      };

      xdg.dataFile."easyeffects/autoload/output/alsa_output.usb-Apple__Inc._USB-C_to_3.5mm_Headphone_Jack_Adapter_DWH51640D162FN3A6-00.analog-stereo:Headphones.json".text =
        builtins.toJSON {
          device = "alsa_output.usb-Apple__Inc._USB-C_to_3.5mm_Headphone_Jack_Adapter_DWH51640D162FN3A6-00.analog-stereo";
          device-description = "USB-C to 3.5mm Headphone Jack Adapter Analog Stereo";
          device-profile = "Headphones";
          preset-name = "HiFiMan Edition XS";
        };

      # Shadows the package's vesktop.desktop instead of patching the package,
      # which would change its hash and rebuild it locally on every update.
      xdg.desktopEntries.vesktop = {
        name = "Discord";
        genericName = "Internet Messenger";
        comment = "Alternative Discord client with Vencord built-in";
        exec = "vesktop %U";
        icon = "${pkgs.runCommand "discord.png" { } ''
          cp ${pkgs.discord}/share/icons/hicolor/256x256/apps/discord.png $out
        ''}";
        categories = [
          "Network"
          "InstantMessaging"
          "Chat"
        ];
        mimeType = [ "x-scheme-handler/discord" ];
        settings = {
          Keywords = "discord;vencord;electron;chat";
          StartupWMClass = "Vesktop";
        };
      };

      programs = {
        firefox = {
          profiles."default".settings = {
            # Hardware video decode (NVIDIA-VAAPI is configured at system level).
            # Decode is force-enabled past the NVIDIA blocklist, and a failing
            # decoder still falls back to software. The compositor and DMABuf
            # paths are not forced, so Firefox can fall back instead of crashing
            # when the NVIDIA path fails.
            "media.hardware-video-decoding.force-enabled" = true;
            "gfx.webrender.all" = true;
            "gfx.canvas.accelerated" = true;
            "gfx.webrender.compositor" = false;
            "gfx.webrender.compositor.force-enabled" = false;
            "widget.dmabuf.force-enabled" = false;

            # 165 Hz feel
            "general.smoothScroll.msdPhysics.enabled" = true;
            "gfx.webrender.precache-shaders" = true;

            # Perf — background network noise (wired desktop, no captive portals)
            "network.connectivity-service.enabled" = false;
            "network.captive-portal-service.enabled" = false;

            # Cache: 1 GB memory, 512 MB image (32 GB RAM system)
            "browser.cache.memory.capacity" = 1048576; # KB
            "image.cache.size" = 536870912; # bytes
          };
        };

        thunderbird.package = pkgs.thunderbird-bin;

        mpv.config.hwdec = "nvdec";

        vesktop = {
          enable = true;
          mutableSettings = true;
          settings = {
            discordBranch = "stable";
            minimizeToTray = false;
            arRPC = false;
            splashColor = "rgb(220, 220, 223)";
            splashBackground = "rgb(0, 0, 0)";
            spellCheckLanguages = [
              "en-US"
              "en"
            ];
          };

          vencord = {
            # Vencord comes from nixpkgs, so it updates with flake.lock instead
            # of going stale in ~/.config/vesktop/sessionData/vencordFiles.
            useSystem = true;
            mutableSettings = true;
            settings = {
              useQuickCss = true;
              plugins = {
                AlwaysTrust.enabled = true;
                AnonymiseFileNames.enabled = true;
                BiggerStreamPreview.enabled = true;
                CallTimer.enabled = true;
                CharacterCounter.enabled = true;
                ClearURLs.enabled = true;
                ConsoleJanitor.enabled = true;
                CopyFileContents.enabled = true;
                CopyUserURLs.enabled = true;
                Dearrow.enabled = true;
                FixImagesQuality.enabled = true;
                FixSpotifyEmbeds.enabled = true;
                FixYoutubeEmbeds.enabled = true;
                FriendsSince.enabled = true;
                iLoveSpam.enabled = true;
                ImageFilename.enabled = true;
                ReadAllNotificationsButton.enabled = true;
                NoTrack.disableAnalytics = true;
                Settings.settingsLocation = "aboveNitro";
              };
            };
          };
        };
      };
    };
}
