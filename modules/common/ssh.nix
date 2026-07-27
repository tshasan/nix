_: {
  flake.nixosModules.ssh = _: {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = false;
        PubkeyAuthentication = true;
        X11Forwarding = false;
      };
    };
  };
}
