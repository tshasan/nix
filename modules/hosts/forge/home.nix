{ self, ... }:
{
  # Server home: no browser, no desktop, no media or chat apps. Only the shell
  # config, so an ssh session feels like everywhere else.
  flake.homeModules.forgeHome =
    { ... }:
    {
      imports = [ self.homeModules.zsh ];

      home = {
        inherit (self.lib.user) username homeDirectory;

        stateVersion = "26.11";
      };
    };
}
