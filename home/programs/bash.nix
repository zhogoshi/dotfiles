{ pkgs, lib, useZen, setupMode, ... }:
{
  programs.bash = {
    enable = true;
    profileExtra = ''
      if [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
        exec start-hyprland
      fi
    '';
    shellAliases = {
      rr    = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";
      clear = "clear && fastfetch";
    };
    initExtra = ''
      ${lib.optionalString setupMode ''
        printf '\n  Setup keybindings:\n'
        printf '  Super+Enter  —  kitty\n'
        printf '  Super+F      —  ${if useZen then "zen" else "firefox"}\n'
        printf '  Super+K      —  throne\n\n'
      ''}
      fastfetch
      PS1='\[\e[38;5;117m\]\u:\[\e[0m\]\w\[\e[38;5;117m\]$ \[\e[0m\]'

      ww() {
        local json="$HOME/.cache/matugen/colors.json"
        if [ ! -f "$json" ]; then
          echo "ww: no matugen colors found at $json"
          return 1
        fi

        local kitty_colors="$HOME/.config/kitty/colors.conf"
        mkdir -p "$(dirname "$kitty_colors")"
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
        ' "$json" > "$kitty_colors"

        if [ -n "$KITTY_PID" ]; then
          kitty @ set-colors --all --configured "$kitty_colors" 2>/dev/null || true
        fi

        ${lib.optionalString useZen ''
        local zen_profile
        zen_profile=$(find "$HOME/.zen" -maxdepth 1 -name "*.default*" -type d 2>/dev/null | head -1)
        [ -z "$zen_profile" ] && zen_profile=$(find "$HOME/.zen" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)
        if [ -n "$zen_profile" ]; then
          mkdir -p "$zen_profile/chrome"
          ${pkgs.jq}/bin/jq -r '
            .colors.dark |
            ":root {",
            "  --matugen-background: " + .surface + ";",
            "  --matugen-surface: " + .surface_variant + ";",
            "  --matugen-primary: " + .primary + ";",
            "  --matugen-on-primary: " + .on_primary + ";",
            "  --matugen-secondary: " + .secondary + ";",
            "  --matugen-on-surface: " + .on_surface + ";",
            "  --matugen-outline: " + .outline + ";",
            "  --matugen-error: " + .error + ";",
            "}"
          ' "$json" > "$zen_profile/chrome/matugen-vars.css"
        fi
        ''}
        ${lib.optionalString (!useZen) ''
        local ff_dir="$HOME/.mozilla/firefox/$USER/chrome"
        mkdir -p "$ff_dir"
        ${pkgs.jq}/bin/jq -r '
          .colors.dark |
          ":root {",
          "  --matugen-background: " + .surface + ";",
          "  --matugen-surface: " + .surface_variant + ";",
          "  --matugen-primary: " + .primary + ";",
          "  --matugen-on-primary: " + .on_primary + ";",
          "  --matugen-secondary: " + .secondary + ";",
          "  --matugen-on-surface: " + .on_surface + ";",
          "  --matugen-outline: " + .outline + ";",
          "  --matugen-error: " + .error + ";",
          "}"
        ' "$json" > "$ff_dir/matugen-vars.css"
        ''}

        local gtk_dir="$HOME/.config/gtk-3.0"
        mkdir -p "$gtk_dir"
        ${pkgs.jq}/bin/jq -r '
          .colors.dark |
          "@define-color accent_color " + .primary + ";",
          "@define-color accent_bg_color " + (.primary_container // .primary) + ";",
          "@define-color accent_fg_color " + .on_primary + ";",
          "@define-color destructive_color " + .error + ";",
          "@define-color window_bg_color " + .surface + ";",
          "@define-color window_fg_color " + .on_surface + ";",
          "@define-color view_bg_color " + .surface_variant + ";",
          "@define-color view_fg_color " + .on_surface + ";",
          "@define-color headerbar_bg_color " + .surface + ";",
          "@define-color headerbar_fg_color " + .on_surface + ";"
        ' "$json" > "$gtk_dir/gtk.css"

        echo "ww: colors synced from matugen"
      }
    '';
  };
}
