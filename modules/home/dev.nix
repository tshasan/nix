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
      imports = [
        self.homeModules.yazi
        inputs.nix-index-database.homeModules.nix-index
      ];

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

        # `, foo` runs any nixpkgs program without installing it, and unknown
        # commands suggest the package that provides them.
        nix-index.enable = true;
        nix-index-database.comma.enable = true;

        nh = {
          enable = true;
          flake = "${config.home.homeDirectory}/nix";
        };
      };
    };
}
