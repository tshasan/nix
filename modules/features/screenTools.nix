_: {
  flake.nixosModules.screenTools =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        wf-recorder
        obs-studio
        swappy
        satty
        grim
        slurp
      ];
    };
}
