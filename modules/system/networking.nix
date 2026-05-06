{ ... }:
{
  networking = {
    hostName = "nixos";
    networkmanager.enable = true;
    firewall.checkReversePath = "loose";
  };
}
