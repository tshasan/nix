{ self, ... }:
{
  flake.nixosModules.vmConfiguration =
    { ... }:
    {
      imports = [
        self.nixosModules.vmHardware
        self.nixosModules.nix
        self.nixosModules.locale
        self.nixosModules.ssh
        self.nixosModules.basePackages
        self.nixosModules.users
        self.nixosModules.homeManager
        self.nixosModules.containers
      ];

      boot.loader.grub = {
        enable = true;
        device = "/dev/vda";
      };

      networking = {
        hostName = "vm";
        networkmanager.enable = true;
      };

      home-manager.users.${self.lib.user.username} = {
        home = {
          username = self.lib.user.username;
          homeDirectory = self.lib.user.homeDirectory;
          stateVersion = "25.11";
        };
        programs.home-manager.enable = true;
        imports = [
          self.homeModules.zsh
          self.homeModules.git
          self.homeModules.dev
          self.homeModules.nvim
        ];
      };

      system.stateVersion = "25.11";
    };
}
