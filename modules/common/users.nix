{ self, ... }:
{
  flake.nixosModules.users =
    { pkgs, ... }:
    let
      user = self.lib.user;
    in
    {
      programs.zsh.enable = true;

      # Memory-safe drop-in for sudo, which keeps shipping CVEs.
      security.sudo-rs.enable = true;

      users.users.${user.username} = {
        isNormalUser = true;
        extraGroups = [
          "networkmanager"
          "wheel"
          "video"
        ];
        shell = pkgs.zsh;
        openssh.authorizedKeys.keys = user.authorizedKeys;
      };
    };
}
