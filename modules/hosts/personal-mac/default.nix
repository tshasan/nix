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

            applicationFirewall = {
              enable = true;
              enableStealthMode = true;
              allowSigned = true;
              allowSignedApp = false;
            };
          };

          nix = {
            settings = {
              experimental-features = [
                "nix-command"
                "flakes"
              ];
              trusted-users = [
                "@admin"
                self.lib.user.darwinUsername
              ];
            };

            # Home Manager's nh clean only covers user profiles; system
            # generations from the daily auto-upgrade need a root GC.
            gc = {
              automatic = true;
              interval = [
                {
                  Weekday = 0;
                  Hour = 4;
                  Minute = 0;
                }
              ];
              options = "--delete-older-than 14d";
            };

            optimise.automatic = true;
          };

          nixpkgs.config = {
            allowUnfree = true;
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

              CustomUserPreferences = {
                "com.apple.AdLib".allowApplePersonalizedAdvertising = false;
                "com.izotope".EnableAnalytics = 0;
                "com.izotope.RX11".CheckForUpdates = false;
                "com.izotope.rx11".CheckForUpdates = false;
              };
            };

            activationScripts.postActivation.text = ''
              /bin/chmod -R go-w "/Library/Audio/Plug-Ins"
            '';

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
            casks = [
              "rekordbox"
              "sol"
            ];
          };

          environment = {
            systemPackages = [ pkgs.nh ];

            etc."newsyslog.d/nix-darwin-auto-upgrade.conf".text = ''
              # logfilename                         mode count size(KB) when flags
              /var/log/nix-darwin-auto-upgrade.log  644  5     1024     *    NJ
            '';
          };

          launchd.daemons.nix-darwin-auto-upgrade = {
            serviceConfig = {
              ProgramArguments = [
                "/bin/sh"
                "-c"
                # Keep store paths out of this command: changing the plist during
                # a scheduled switch would reload the daemon and kill its own run.
                # The system profile lives on the Nix volume, so wait4path still
                # holds the boot-time run until /nix is mounted.
                ''
                  nh=/nix/var/nix/profiles/system/sw/bin/nh
                  /bin/wait4path "$nh" || exit 1
                  "$nh" darwin switch ${self.lib.user.flakeUrl}#personal-mac --refresh --no-nom --elevation-strategy /usr/bin/sudo --bypass-root-check
                  result=$?
                  if [ "$result" -ne 0 ]; then
                    /bin/launchctl asuser "$(/usr/bin/id -u ${self.lib.user.darwinUsername})" \
                      /usr/bin/sudo -u ${self.lib.user.darwinUsername} /usr/bin/osascript \
                      -e 'display notification "Check /var/log/nix-darwin-auto-upgrade.log" with title "nix-darwin auto-upgrade failed"' || true
                  fi
                  exit "$result"
                ''
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
              # nix-darwin's nix, so builds match the daemon's version.
              EnvironmentVariables.PATH = "/run/current-system/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin";
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
