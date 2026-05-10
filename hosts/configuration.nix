{ inputs, lib, setupMode, useZen, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../modules/system/default.nix
    ../modules/desktop/default.nix
    ../modules/programs/throne.nix
  ] ++ lib.optionals (!setupMode) [
    ../modules/system/normal.nix
    ../modules/desktop/normal.nix
    ../modules/programs/steam.nix
  ] ++ lib.optionals useZen [
    ../modules/programs/zen.nix
  ];

  # Fix for millennium flake issue: "undefined variable 'pkgsi686Linux'"
  nixpkgs.overlays = [
    (final: prev: {
      pkgsi686Linux = import inputs.nixpkgs {
        system = "i686-linux";
        config.allowUnfree = true;
      };
    })
    inputs.millennium.overlays.default
  ];

  nixpkgs.config.allowUnfree = true;

  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    warn-dirty            = false;
  };

  system.stateVersion = "24.11";
}
