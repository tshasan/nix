{ self, ... }:
{
  flake.nixosModules.autoUpgrade = _: {
    system.autoUpgrade = {
      enable = true;
      flake = self.lib.user.flakeUrl;
      dates = "daily";
      randomizedDelaySec = "45min";
      allowReboot = false;
    };
  };
}
