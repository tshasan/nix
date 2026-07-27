_: {
  flake.homeModules.mpv =
    { pkgs, ... }:
    {
      programs.mpv = {
        enable = true;

        scripts = with pkgs.mpvScripts; [
          uosc # modern OSC with playlist, chapters, track picker
          thumbfast # seekbar thumbnail previews
          autoload # auto-add sibling files as playlist
        ];

        config = {
          vo = "gpu-next";
          gpu-api = "vulkan";
          hwdec = "nvdec";

          # Disable the built-in OSC since uosc replaces it
          osc = "no";
          osd-bar = "no";

          save-position-on-quit = "yes";
          keep-open = "yes";
          sub-auto = "fuzzy";
        };
      };
    };
}
