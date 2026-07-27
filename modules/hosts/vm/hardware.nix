_: {
  flake.nixosModules.vmHardware =
    { modulesPath, ... }:
    {
      imports = [
        (modulesPath + "/profiles/qemu-guest.nix")
      ];

      fileSystems."/" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
      };

      nixpkgs.hostPlatform = "x86_64-linux";
    };
}
