_: {
  # Home settings tied to this machine's hardware: x86_64 binary builds,
  # the NVIDIA VA-API stack, 32 GB of RAM, and a 180 Hz display.
  flake.homeModules.desktopHome =
    { pkgs, ... }:
    {
      programs = {
        firefox = {
          package = pkgs.firefox-bin;

          profiles."default".settings = {
            # Nix owns updates of the binary package.
            "app.update.auto" = false;
            "app.update.background.scheduling.enabled" = false;

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
