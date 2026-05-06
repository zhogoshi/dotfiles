{ lib, useZen, ... }: {
  imports = [
    ./bash.nix
    ./apps
    ./hyprland.nix
  ] ++ (if useZen then [ ./zen.nix ] else [ ./firefox.nix ]);
}
