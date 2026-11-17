{ inputs, ... }:
{
  imports = [ inputs.home-manager.flakeModules.home-manager ];

  systems = [
    "aarch64-darwin"
    "aarch64-linux"
    "x86_64-linux"
  ];
}
