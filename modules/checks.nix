{ inputs, self, ... }:
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
              elif [ -z "''${NIX_BUILD_TOP:-}" ]; then
                # CI and nix flake check run in a sandbox without the private
                # file. Anywhere else, a missing file means the real patterns
                # are not being checked, so fail instead of passing silently.
                echo "gitleaks: .gitleaks.local.toml is missing; private patterns were not checked." >&2
                echo "Add the file, or commit with SKIP=gitleaks to bypass once." >&2
                exit 1
              fi
            ''
          );
          pass_filenames = false;
        };
        # gitleaks --no-git scans files, not commit metadata. This checks the
        # identity the commit will be recorded under.
        git-identity = {
          enable = true;
          name = "git-identity";
          description = "Commit author and committer must be the personal identity";
          entry = builtins.toString (
            pkgs.writeShellScript "git-identity-check" ''
              set -euo pipefail
              # The check sandbox uses a placeholder identity and never commits.
              [ -z "''${NIX_BUILD_TOP:-}" ] || exit 0
              # No identity configured (user.useConfigOnly with no email): git
              # refuses the commit itself.
              for var in GIT_AUTHOR_IDENT GIT_COMMITTER_IDENT; do
                ident=$(git var "$var" 2>/dev/null) || exit 0
                email=''${ident#*<}
                email=''${email%%>*}
                case "$email" in
                  ${self.lib.user.email} | *@users.noreply.github.com) ;;
                  *)
                    echo "git-identity: $var uses $email, not the personal identity." >&2
                    exit 1
                    ;;
                esac
              done
            ''
          );
          pass_filenames = false;
          always_run = true;
        };
      };

      devShells.default = pkgs.mkShell {
        inherit (config.pre-commit.devShell) shellHook;
      };
    };
}
