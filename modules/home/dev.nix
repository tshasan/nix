_: {
  flake.homeModules.dev =
    { pkgs, config, ... }:
    {
      home = {
        packages = with pkgs; [
          claude-code
          gh
          jq
          lazygit
          yazi
          zoxide
          nodejs
          bun
          deno
          pnpm
          python3
          uv
          rustup
          gcc
          jdk
          clang-tools
          cmake
          ninja
          pkg-config
          meson
          gdb
          bear
        ];

        sessionVariables = {
          RUSTUP_HOME = "${config.home.homeDirectory}/.rustup";
          CARGO_HOME = "${config.home.homeDirectory}/.cargo";
        };

        sessionPath = [ "${config.home.homeDirectory}/.cargo/bin" ];
      };

      xdg.configFile = {
        "yazi/yazi.toml".source = ../files/shared/yazi/yazi.toml;
        "yazi/init.lua".source = ../files/shared/yazi/init.lua;
        "yazi/keymap.toml".source = ../files/shared/yazi/keymap.toml;
        "yazi/plugins/git.yazi".source = pkgs.yaziPlugins.git;
      };

      programs = {
        fzf.enable = true;
        bat.enable = true;

        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };

        nh = {
          enable = true;
          flake = "${config.home.homeDirectory}/nix";
          clean = {
            enable = true;
            extraArgs = "--keep-since 7d --keep 5";
          };
        };
      };
    };
}
