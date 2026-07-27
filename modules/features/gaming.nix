_: {
  flake.nixosModules.gaming =
    { pkgs, ... }:
    {
      hardware.steam-hardware.enable = true;

      environment.systemPackages = [ pkgs.trigger-control ];

      programs.gamescope.capSysNice = true;

      programs = {
        steam = {
          enable = true;
          extraCompatPackages = [ pkgs.proton-ge-bin ];
          remotePlay.openFirewall = true;
          localNetworkGameTransfers.openFirewall = true;
        };
        gamemode.enable = true;
        gamescope.enable = true;
      };
    };
}
