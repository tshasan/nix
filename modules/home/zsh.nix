_: {
  flake.homeModules.zsh =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      home.file.".p10k.zsh".source = ../files/zsh/p10k.zsh;
      xdg.configFile."zsh/common.zsh".source = ../files/shared/zsh/common.zsh;

      programs.zsh = {
        enable = true;
        dotDir = config.home.homeDirectory;

        autosuggestion.enable = true;
        syntaxHighlighting.enable = true;
        historySubstringSearch.enable = true;

        plugins = [
          {
            name = "powerlevel10k";
            src = pkgs.zsh-powerlevel10k;
            file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
          }
        ];

        initContent = lib.mkMerge [
          (lib.mkBefore ''
            if [[ -r "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh" ]]; then
              source "''${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-''${(%):-%n}.zsh"
            fi
          '')
          ''
            source "${config.xdg.configHome}/zsh/common.zsh"
          ''
        ];
      };
    };
}
