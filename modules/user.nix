_: {
  # The single point others edit for system account and home path values.
  flake.lib.user = {
    username = "taimur";
    homeDirectory = "/home/taimur";
    darwinUsername = "thasan";
    darwinHomeDirectory = "/Users/thasan";
    fullName = "Taimur Hasan";
    email = "me@tshasan.com";
    flakeUrl = "github:tshasan/nix";
    authorizedKeys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPtJSlUuiWm5fUaQNCZUuRhoqQ1O9z6qGTj+KPQqx9OM"
    ];
  };
}
