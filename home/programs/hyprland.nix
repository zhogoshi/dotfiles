{ lib, setupMode, useZen, ... }:
{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      "$mod"      = "SUPER";
      "$terminal" = "kitty";
      exec-once   = [ "axctl" ];

      bind = [
        "$mod, Return, exec, $terminal"
        "$mod, Q, killactive"
      ] ++ lib.optionals setupMode [
        "$mod, F, exec, ${if useZen then "zen" else "firefox"}"
        "$mod, K, exec, throne"
      ];

      misc = {
        disable_hyprland_logo    = true;
        disable_splash_rendering = true;
      };

      general = {
        gaps_in   = 5;
        gaps_out  = 10;
        border_size = 2;
      };
    };
  };
}
