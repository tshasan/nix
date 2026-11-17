_: {
  # Configuration only: Linux and personal-mac install yazi through
  # homeModules.dev, and work-mac gets it from Homebrew.
  flake.homeModules.yazi =
    { pkgs, ... }:
    {
      xdg.configFile = {
        "yazi/yazi.toml".source = ../files/shared/yazi/yazi.toml;
        "yazi/init.lua".source = ../files/shared/yazi/init.lua;
        "yazi/keymap.toml".source = ../files/shared/yazi/keymap.toml;
        "yazi/plugins/git.yazi".source = pkgs.yaziPlugins.git;
      };
    };
}
