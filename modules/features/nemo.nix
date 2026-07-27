_: {
  flake.nixosModules.nemo =
    { pkgs, ... }:
    {
      services.tumbler.enable = true;
      services.gvfs.enable = true;

      environment.systemPackages = with pkgs; [
        (nemo-with-extensions.override {
          extensions = [
            nemo-fileroller
            nemo-emblems
          ];
        })
        file-roller
        p7zip
        zip
        unzip
        unar
        unrar
      ];
    };
}
