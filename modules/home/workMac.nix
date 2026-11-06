{ self, ... }:
{
  flake.homeModules.workMac =
    {
      config,
      lib,
      ...
    }:
    let
      gitMaintenance = schedule: StartCalendarInterval: {
        enable = true;
        config = {
          ProgramArguments = [
            "/opt/homebrew/bin/git"
            "for-each-repo"
            "--config=maintenance.repo"
            "maintenance"
            "run"
            "--schedule=${schedule}"
          ];
          inherit StartCalendarInterval;
          ProcessType = "Background";
          LowPriorityIO = true;
          EnvironmentVariables.PATH = "/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin";
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
              "/bin/sh"
              "-c"
              # Keep store paths out of this command: changing the plist during
              # a scheduled switch would reload the agent and kill its own run.
              ''
                ${lib.escapeShellArgs [
                  "${config.home.profileDirectory}/bin/home-manager"
                  "switch"
                  "--flake"
                  "${config.home.homeDirectory}/nix#work-mac"
                  "-b"
                  "hm-backup"
                ]}
                result=$?
                if [ "$result" -ne 0 ]; then
                  /opt/homebrew/bin/terminal-notifier \
                    -title 'Home Manager activation failed' \
                    -message 'Check ~/Library/Logs/home-manager-auto-upgrade.log' || true
                fi
                exit "$result"
              ''
            ];
            StartCalendarInterval = [
              {
                Hour = 3;
                Minute = 0;
              }
            ];
            ProcessType = "Background";
            LowPriorityIO = true;
            EnvironmentVariables.PATH = "/opt/homebrew/bin:/nix/var/nix/profiles/default/bin:/usr/bin:/bin:/usr/sbin:/sbin";
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
