{ self, ... }:
{
  flake.homeModules.workMac =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      gitMaintenance = schedule: StartCalendarInterval: {
        enable = true;
        config = {
          ProgramArguments = [
            "${pkgs.gitFull}/bin/git"
            "for-each-repo"
            "--config=maintenance.repo"
            "maintenance"
            "run"
            "--schedule=${schedule}"
          ];
          inherit StartCalendarInterval;
          ProcessType = "Background";
          LowPriorityIO = true;
          StandardOutPath = "${config.home.homeDirectory}/Library/Logs/git-maintenance.log";
          StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/git-maintenance.log";
        };
      };
    in
    {
      imports = [ self.homeModules.darwinBase ];

      # programs.git stays disabled: Homebrew owns git here, so the shared
      # settings are rendered into ~/.gitconfig directly.
      programs.git.settings = {
        protocol.version = "2";
        maintenance = {
          repo = "${config.home.homeDirectory}/firefox";
          prefetch.enabled = false;
        };
        "filter \"lfs\"" = {
          clean = "git-lfs clean -- %f";
          smudge = "git-lfs smudge -- %f";
          process = "git-lfs filter-process";
          required = true;
        };
        include.path = "~/.config/git/work.conf";
      };

      home.file = {
        ".gitconfig".text = lib.generators.toGitINI config.programs.git.settings;
        ".p10k.zsh".source = ../files/zsh/p10k.zsh;
        ".profile".source = ../files/macos/zsh/profile;
        ".zprofile".source = ../files/macos/zsh/zprofile;
        ".zshenv".source = ../files/macos/zsh/zshenv;
        ".zshrc".source = ../files/macos/zsh/zshrc;
      };

      launchd.agents = {
        git-maintenance-hourly = gitMaintenance "hourly" (
          map (minute: { Minute = minute; }) [
            0
            15
            30
            45
          ]
        );

        git-maintenance-daily = gitMaintenance "daily" [
          {
            Hour = 3;
            Minute = 0;
          }
        ];

        home-manager-auto-upgrade = {
          enable = true;
          config = {
            ProgramArguments = [
              # A store path here would change the plist on every update, and
              # Home Manager reloads changed agents, killing this run mid-switch.
              "${config.home.profileDirectory}/bin/home-manager"
              "switch"
              "--flake"
              "${self.lib.user.flakeUrl}#work-mac"
              "--refresh"
              "-b"
              "hm-backup"
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
            StandardOutPath = "${config.home.homeDirectory}/Library/Logs/home-manager-auto-upgrade.log";
            StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/home-manager-auto-upgrade.log";
          };
        };
      };

      nix.gc = {
        automatic = true;
        options = "--delete-older-than 7d";
      };

      xdg.configFile = {
        "nix/nix.conf".source = ../files/macos/nix/nix.conf;
        "zsh/common.zsh".source = ../files/shared/zsh/common.zsh;
        "zsh/local/gecko.zsh".source = ../files/macos/zsh/gecko.zsh;
      };
    };
}
