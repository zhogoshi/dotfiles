{ pkgs, ... }: {
  services.getty.autologinUser = "hogoshi";

  programs.hyprland = {
    enable          = true;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable       = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
  };
  services.pulseaudio.enable = false;

  environment.systemPackages = with pkgs; [
    wl-clipboard
    grim
    slurp
  ];
}
