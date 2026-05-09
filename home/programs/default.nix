{ lib, useZen, ... }: {
  imports = [
    ./bash.nix
    ./apps
  ] ++ (if useZen then [ ./zen.nix ] else [ ./firefox.nix ]);
}
