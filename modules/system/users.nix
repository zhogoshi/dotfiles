{ pkgs, ... }:
{
  users.users.hogoshi = {
    isNormalUser = true;
    description  = "hogoshi";
    extraGroups  = [ "networkmanager" "wheel" "video" "audio" ];
    shell        = pkgs.bash;
    # Set password after first boot with: passwd hogoshi
    initialPassword = "0378";
  };
}
