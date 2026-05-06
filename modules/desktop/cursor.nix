{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    bibata-cursors
  ];

  environment.sessionVariables = {
    XCURSOR_THEME = "Bibata-Modern-Classic";
    XCURSOR_SIZE  = "24";
  };
}
