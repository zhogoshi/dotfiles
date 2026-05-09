{ pkgs, ... }:
{
  users.users.hogoshi = {
    isNormalUser = true;
    description  = "hogoshi";
    extraGroups  = [ "networkmanager" "wheel" "video" "audio" ];
    shell        = pkgs.bash;
    initialPassword = "0378";
  };
}
