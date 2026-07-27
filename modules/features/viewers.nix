_: {
  flake.nixosModules.viewers =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        zathura
        imv
        libreoffice
      ];
    };
}
