{ self, inputs, ... }:
{
  flake.darwinConfigurations."personal-mac" = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      inputs.home-manager.darwinModules.home-manager
      (
        { pkgs, ... }:
        {
          nixpkgs.hostPlatform = "aarch64-darwin";

          users.users.${self.lib.user.darwinUsername}.home = self.lib.user.darwinHomeDirectory;

          networking = {
            hostName = "personal-mac";
            computerName = "personal-mac";
          };

          nix.settings = {
            experimental-features = [
              "nix-command"
              "flakes"
            ];
            trusted-users = [
              "@admin"
              self.lib.user.darwinUsername
            ];
          };

          nixpkgs.config = {
            allowUnfree = true;
            permittedInsecurePackages = [ "electron-39.8.10" ];
          };

          security.pam.services.sudo_local = {
            enable = true;
            touchIdAuth = true;
          };

          system = {
            primaryUser = self.lib.user.darwinUsername;

            defaults = {
              NSGlobalDomain = {
                InitialKeyRepeat = 15;
                KeyRepeat = 2;
                ApplePressAndHoldEnabled = false;
                AppleInterfaceStyle = "Dark";
                NSAutomaticSpellingCorrectionEnabled = false;
                NSAutomaticCapitalizationEnabled = false;
                NSAutomaticQuoteSubstitutionEnabled = false;
                NSAutomaticDashSubstitutionEnabled = false;
                NSAutomaticPeriodSubstitutionEnabled = false;
                NSDocumentSaveNewDocumentsToCloud = false;
              };

              dock = {
                autohide = true;
                show-recents = false;
                mru-spaces = false;
                tilesize = 48;
                minimize-to-application = true;
                showhidden = true;
              };

              finder = {
                AppleShowAllExtensions = true;
                FXPreferredViewStyle = "clmv";
                FXDefaultSearchScope = "SCcf";
                ShowPathbar = true;
                ShowStatusBar = true;
                _FXSortFoldersFirst = true;
                FXEnableExtensionChangeWarning = false;
              };
            };

            stateVersion = 5;
          };

          programs.zsh.enable = true;

          homebrew = {
            enable = true;
            onActivation = {
              cleanup = "zap";
              autoUpdate = true;
              upgrade = true;
            };
            casks = [ ];
          };

          launchd.daemons.nix-darwin-auto-upgrade = {
            serviceConfig = {
              ProgramArguments = [
                "${pkgs.nh}/bin/nh"
                "darwin"
                "switch"
                "${self.lib.user.flakeUrl}#personal-mac"
                "--refresh"
                "--elevation-strategy"
                "/usr/bin/sudo"
                "--bypass-root-check"
              ];
              RunAtLoad = true;
              StartCalendarInterval = [
                {
                  Hour = 3;
                  Minute = 0;
                }
              ];
              ProcessType = "Background";
              LowPriorityIO = true;
              EnvironmentVariables.PATH = "/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
              StandardOutPath = "/var/log/nix-darwin-auto-upgrade.log";
              StandardErrorPath = "/var/log/nix-darwin-auto-upgrade.log";
            };
          };

          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "hm-backup";
            users.${self.lib.user.darwinUsername}.imports = [ self.homeModules.personalMac ];
          };
        }
      )
    ];
  };
}
