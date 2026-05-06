{ ... }: {
  imports = [
    ./boot.nix
    ./networking.nix
    ./locale.nix
    ./users.nix
    ./zram.nix
    ./cachix.nix
  ];
}
