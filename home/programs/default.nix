{ lib, useZen, ... }: {
  imports = [
    ./bash.nix
    ./autostart.nix
    ./apps
  ] ++ (if useZen then [ ./zen.nix ] else [ ./firefox.nix ]);
}
