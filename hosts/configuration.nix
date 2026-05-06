{ inputs, lib, setupMode, useZen, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../modules/system/default.nix
    ../modules/desktop/default.nix
    ../modules/programs/throne.nix
  ] ++ lib.optionals (!setupMode) [
    ../modules/system/normal.nix
    ../modules/desktop/normal.nix
  ] ++ lib.optionals useZen [
    ../modules/programs/zen.nix
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.overlays = [ inputs.millennium.overlays.default ];

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    warn-dirty            = false;
  };

  system.stateVersion = "24.11";
}
