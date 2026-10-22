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

      # Linked to the checkout rather than copied into the store, so edits apply
      # without a switch and :LazyExtras / :Lazy update can write their files.
      xdg.configFile.nvim.source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/nix/modules/files/shared/nvim";
    };
}
