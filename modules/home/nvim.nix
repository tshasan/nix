_: {
  flake.homeModules.nvim =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.packages = lib.optionals pkgs.stdenv.hostPlatform.isLinux [
        pkgs.neovim
        pkgs.fd
        pkgs.ripgrep
        pkgs.tree-sitter
        pkgs.wl-clipboard
      ];

      xdg.configFile = {
        "nvim/.neoconf.json".source = ../files/shared/nvim/.neoconf.json;
        "nvim/init.lua".source = ../files/shared/nvim/init.lua;
        "nvim/lazy-lock.json".source =
          config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/modules/files/shared/nvim/lazy-lock.json";
        "nvim/lazyvim.json".source = ../files/shared/nvim/lazyvim.json;
        "nvim/stylua.toml".source = ../files/shared/nvim/stylua.toml;
        "nvim/lua" = {
          source = ../files/shared/nvim/lua;
          recursive = true;
        };
      };
    };
}
