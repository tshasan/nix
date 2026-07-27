_: {
  flake.homeModules.desktop = _: {
    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      setSessionVariables = false;
    };
  };
}
