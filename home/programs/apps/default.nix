{ pkgs, ... }: {
  home.packages = with pkgs; [
    htop
    git
    fastfetch
    kitty
  ];
}
