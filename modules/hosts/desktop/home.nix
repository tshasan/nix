_: {
  # Home settings tied to this machine: its x86_64-only apps and binary
  # builds, the NVIDIA VA-API stack, 32 GB of RAM, and a 180 Hz display.
  flake.homeModules.desktopHome =
    { pkgs, ... }:
    {
      home = {
        stateVersion = "25.11";

        packages = with pkgs; [
          (vesktop.overrideAttrs (old: {
            postInstall = (old.postInstall or "") + ''
              for d in $out/share/icons/hicolor/*/apps; do
                cp -f ${discord}/share/icons/hicolor/256x256/apps/discord.png "$d/vesktop.png"
              done
            '';
            postFixup = (old.postFixup or "") + ''
              substituteInPlace $out/share/applications/vesktop.desktop \
                --replace-fail "Name=Vesktop" "Name=Discord"
            '';
          }))

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

      services.easyeffects.enable = true;

      programs = {
        firefox = {
          profiles."default".settings = {
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

            # Perf — HW decode (explicit; nix-owned NVIDIA-VAAPI stack)
            "media.av1.enabled" = true;
            "media.rdd-process.enabled" = true;
            "media.hardwaremediakeys.enabled" = true;

            # 180 Hz feel
            "general.smoothScroll.msdPhysics.enabled" = true;
            "apz.frame_delay.enabled" = false;
            "gfx.webrender.precache-shaders" = true;

            # Cache: 1 GB memory, 512 MB image (32 GB RAM system)
            "browser.cache.memory.capacity" = 1048576; # KB
            "image.cache.size" = 536870912; # bytes
          };
        };

        thunderbird.package = pkgs.thunderbird-bin;

        mpv.config.hwdec = "nvdec";
      };
    };
}
