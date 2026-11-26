{ self, inputs, ... }:
{
  # "forge": the M1 MacBook that stopped being a laptop. It lives shut and
  # plugged in, serving Forgejo and SearXNG, and is reached over ssh.
  flake.nixosConfigurations.forge = inputs.nixpkgs.lib.nixosSystem {
    modules = [
      self.nixosModules.forgeConfiguration
    ];
  };
}
