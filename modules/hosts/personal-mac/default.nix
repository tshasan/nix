{ self, inputs, ... }:
{
  flake.darwinConfigurations."personal-mac" = inputs.nix-darwin.lib.darwinSystem {
    modules = [
      inputs.home-manager.darwinModules.home-manager
      {
        nixpkgs.hostPlatform = "aarch64-darwin";

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

        security.pam.services.sudo_local = {
          enable = true;
          touchIdAuth = true;
        };

        system.defaults = {
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

        programs.zsh.enable = true;

        homebrew = {
          enable = true;
          onActivation = {
            cleanup = "zap";
            autoUpdate = true;
            upgrade = true;
          };
          casks = [ "bitwarden" ];
        };

        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          backupFileExtension = "hm-backup";
          users.${self.lib.user.darwinUsername}.imports = [ self.homeModules.personalMac ];
        };

        system.stateVersion = 5;
      }
    ];
  };
}
