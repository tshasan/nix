{ self, inputs, ... }:
{
  flake.homeConfigurations."work-mac" = inputs.home-manager.lib.homeManagerConfiguration {
    pkgs = inputs.nixpkgs.legacyPackages.aarch64-darwin;
    modules = [ self.homeModules.workMac ];
  };
}
