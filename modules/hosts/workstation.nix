{ self, ... }:
{
  # What every NixOS GNOME machine (desktop, macbook) is made of; hosts add
  # their hardware and extras on top.
  flake.nixosModules.workstation = _: {
    imports = [
      self.nixosModules.nix
      self.nixosModules.locale
      self.nixosModules.basePackages
      self.nixosModules.users
      self.nixosModules.homeManager
      self.nixosModules.fonts
      self.nixosModules.viewers
      self.nixosModules.nemo
      self.nixosModules.bluetooth
      self.nixosModules.gnome
      self.nixosModules.nixLd
    ];
  };
}
