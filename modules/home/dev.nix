{ self, inputs, ... }:
{
  flake.homeModules.dev =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [ self.homeModules.yazi ];

      home = {
        packages =
          with pkgs;
          [
            claude-code
            inputs.pi.packages.${pkgs.stdenv.hostPlatform.system}.default
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
            cmake
            ninja
            pkg-config
          ]
          ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
            gcc
            jdk
            clang-tools
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
