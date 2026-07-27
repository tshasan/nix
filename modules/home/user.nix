{ self, ... }:
{
  flake.homeModules.user =
    { pkgs, ... }:
    let
      inherit (self.lib.user) username homeDirectory;
    in
    {
      imports = [
        self.homeModules.kitty
        self.homeModules.zsh
        self.homeModules.git
        self.homeModules.firefox
        self.homeModules.thunderbird
        self.homeModules.dev
        self.homeModules.mpv
        self.homeModules.desktop
        self.homeModules.gnome
        self.homeModules.theming
        self.homeModules.qbittorrent
        self.homeModules.nvim
      ];

      home = {
        inherit username homeDirectory;
        stateVersion = "25.11";

        packages = with pkgs; [
          (vesktop.overrideAttrs (old: {
            postInstall = (old.postInstall or "") + ''
              for d in $out/share/icons/hicolor/*/apps; do
                cp -f ${discord}/share/icons/hicolor/256x256/apps/discord.png "$d/vesktop.png"
              done
            '';
            postFixup = (old.postFixup or "") + ''
              substituteInPlace $out/share/applications/vesktop.desktop \
                --replace-fail "Name=Vesktop" "Name=Discord"
            '';
          }))

          (prismlauncher.override {
            additionalPrograms = [ ffmpeg ];

            jdks = [
              graalvmPackages.graalvm-ce
              zulu8
              zulu17
              zulu
            ];
          })
          spotify
          google-chrome
          eza
          nnn
          protontricks
          dualsensectl
          gnome-disk-utility

        ];
      };

      programs.home-manager.enable = true;
    };
}
