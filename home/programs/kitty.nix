{ pkgs, ... }:
{
  programs.kitty = {
    enable = true;
    settings = {
      font_family      = "monospace";
      font_size        = 14;
      window_padding_width = 8;
      confirm_os_window_close = 0;
      include = "~/.config/kitty/colors.conf";
      background_opacity = 0.4;
    };
  };

  home.activation.kittyMatugenColors = {
    after  = [ "writeBoundary" ];
    before = [];
    data   = ''
      COLORS_JSON="$HOME/.cache/matugen/colors.json"
      KITTY_COLORS="$HOME/.config/kitty/colors.conf"
      mkdir -p "$(dirname "$KITTY_COLORS")"
      if [ -f "$COLORS_JSON" ]; then
        ${pkgs.jq}/bin/jq -r '
          .colors.dark |
          "background           " + .surface,
          "foreground           " + .on_surface,
          "selection_background " + .primary,
          "selection_foreground " + .on_primary,
          "cursor               " + .primary,
          "cursor_text_color    " + .on_primary,
          "color0  " + .surface,
          "color1  " + .error,
          "color2  " + .tertiary,
          "color3  " + .secondary,
          "color4  " + .primary,
          "color5  " + .tertiary_container,
          "color6  " + .secondary_container,
          "color7  " + .on_surface,
          "color8  " + .outline,
          "color9  " + .error_container,
          "color10 " + .on_tertiary,
          "color11 " + .on_secondary,
          "color12 " + .on_primary,
          "color13 " + .on_tertiary_container,
          "color14 " + .on_secondary_container,
          "color15 " + .surface_variant
        ' "$COLORS_JSON" > "$KITTY_COLORS"
      else
        cat > "$KITTY_COLORS" << 'DEFAULTS'
background           #1e1e2e
foreground           #cdd6f4
cursor               #f5e0dc
color0  #45475a
color1  #f38ba8
color2  #a6e3a1
color3  #f9e2af
color4  #89b4fa
color5  #f5c2e7
color6  #94e2d5
color7  #bac2de
color8  #585b70
color9  #f38ba8
color10 #a6e3a1
color11 #f9e2af
color12 #89b4fa
color13 #f5c2e7
color14 #94e2d5
color15 #a6adc8
DEFAULTS
      fi
    '';
  };
}
