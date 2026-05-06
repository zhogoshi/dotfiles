{ pkgs, ... }: {
  home.packages = with pkgs; [
    code-cursor
    telegram-desktop
    vesktop
    spotify
    pkgs.millennium-steam
  ];
}
