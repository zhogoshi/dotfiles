{ lib, setupMode, ... }: {
  imports = [
    ./programs/default.nix
  ] ++ lib.optionals (!setupMode) [
    ./programs/normal.nix
  ];

  home = {
    username      = "hogoshi";
    homeDirectory = "/home/hogoshi";
    stateVersion  = "24.11";
  };

  programs.home-manager.enable = true;
}
