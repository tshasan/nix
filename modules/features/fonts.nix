_: {
  flake.nixosModules.fonts =
    { pkgs, ... }:
    {
      fonts.packages = with pkgs; [
        atkinson-hyperlegible
        atkinson-hyperlegible-mono
        atkinson-hyperlegible-next
        atkinson-monolegible
        nerd-fonts.atkynson-mono

        noto-fonts
        noto-fonts-color-emoji
        noto-fonts-cjk-sans
      ];
    };
}
