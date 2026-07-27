{ self, ... }:
{
  flake.homeModules.git =
    { pkgs, ... }:
    let
      inherit (self.lib.user) fullName email;
    in
    {
      services.protonmail-bridge.enable = true;

      programs.delta = {
        enable = true;
        enableGitIntegration = true;
      };

      programs.git = {
        enable = true;
        package = pkgs.gitFull;
        lfs.enable = true;
        settings = {
          user = {
            name = fullName;
            inherit email;
            useConfigOnly = true;
          };
          core = {
            editor = "nvim";
            fsmonitor = true;
            untrackedCache = true;
          };
          color.ui = "auto";
          credential.helper = "cache --timeout=86400";
          sendemail = {
            smtpServer = "127.0.0.1";
            smtpServerPort = 1025;
            smtpEncryption = "tls";
            confirm = "auto";
          };
        };
      };
    };
}
