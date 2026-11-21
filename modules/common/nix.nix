{ self, ... }:
{
  flake.nixosModules.nix = _: {
    nix = {
      channel.enable = false;

      optimise.automatic = true;

      settings = {
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        trusted-users = [
          "root"
          self.lib.user.username
        ];
        max-jobs = "auto";
        cores = 0;
        extra-substituters = [
          "https://nix-community.cachix.org"
        ];
        extra-trusted-public-keys = [
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
    };

    # Replaces nix.gc: after a long time offline, --delete-older-than would
    # remove every rollback target, while --keep 5 always leaves some.
    programs.nh.clean = {
      enable = true;
      dates = "weekly";
      extraArgs = "--keep-since 14d --keep 5";
    };

    nixpkgs.config.allowUnfree = true;
  };
}
