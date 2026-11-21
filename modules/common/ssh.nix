{ self, ... }:
{
  flake.nixosModules.ssh = _: {
    services.openssh = {
      enable = true;
      settings = {
        AllowUsers = [ self.lib.user.username ];
        PermitRootLogin = "no";
        PasswordAuthentication = false;
        KbdInteractiveAuthentication = false;
        PubkeyAuthentication = true;
        X11Forwarding = false;
      };
    };
  };
}
