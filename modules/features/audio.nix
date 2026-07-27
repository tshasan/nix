_: {
  flake.nixosModules.audio = _: {
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;

    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;

      extraConfig.pipewire."10-rates" = {
        "context.properties" = {
          "default.clock.rate" = 48000;
          "default.clock.allowed-rates" = [
            44100
            48000
            88200
            96000
            176400
            192000
          ];
          "default.clock.quantum" = 512;
          "default.clock.min-quantum" = 32;
          "default.clock.max-quantum" = 8192;
          "resample.quality" = 14;
        };
      };

      wireplumber.extraConfig."10-alsa-sink" = {
        "monitor.alsa.rules" = [
          {
            matches = [ { "node.name" = "~alsa_output.*"; } ];
            actions.update-props = {
              "resample.quality" = 14;
            };
          }
          {
            matches = [ { "node.name" = "~alsa_output.usb-Apple*"; } ];
            actions.update-props = {
              "audio.allowed-rates" = [ 48000 ];
              "audio.format" = "S24LE";
            };
          }
        ];
      };
    };
  };
}
