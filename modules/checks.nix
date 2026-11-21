{ inputs, ... }:
{
  imports = [
    inputs.treefmt-nix.flakeModule
    inputs.git-hooks-nix.flakeModule
  ];

  perSystem =
    { config, pkgs, ... }:
    {
      treefmt = {
        projectRootFile = "flake.nix";
        programs.nixfmt.enable = true;
      };

      pre-commit.settings.hooks = {
        treefmt.enable = true;
        deadnix.enable = true;
        statix.enable = true;
        actionlint.enable = true;
        commitizen.enable = true;
        gitleaks = {
          enable = true;
          name = "gitleaks";
          description = "Scan for secrets and PII";
          package = pkgs.gitleaks;
          # Second pass picks up untracked private rules (.gitleaks.local.toml)
          # when present, so NDA-sensitive patterns are enforced locally without
          # ever being committed.
          entry = builtins.toString (
            pkgs.writeShellScript "gitleaks-check" ''
              set -euo pipefail
              ${pkgs.gitleaks}/bin/gitleaks detect --no-git --redact --verbose
              if [ -f .gitleaks.local.toml ]; then
                ${pkgs.gitleaks}/bin/gitleaks detect --no-git --redact --verbose --config .gitleaks.local.toml
              fi
            ''
          );
          pass_filenames = false;
        };
      };

      devShells.default = pkgs.mkShell {
        inherit (config.pre-commit.devShell) shellHook;
      };
    };
}
