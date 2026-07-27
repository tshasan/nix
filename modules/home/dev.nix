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
