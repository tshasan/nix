_: {
  flake.nixosModules.basePackages =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        neovim
        gitFull
        lf
        btop
        ripgrep
        fd
        curl
        wget
        lm_sensors
        unzip
        fastfetch
        iotop
        stress-ng
        hyperfine
      ];
    };
}
