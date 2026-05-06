{ pkgs, lib, setupMode, useZen, ... }: lib.mkIf (useZen && !setupMode) {
  home.activation.zenMatugenColors = {
    after  = [ "writeBoundary" ];
    before = [];
    data   = ''
      COLORS_JSON="$HOME/.cache/matugen/colors.json"
      ZEN_PROFILE=$(find "$HOME/.zen" -maxdepth 1 -name "*.default*" -type d 2>/dev/null | head -1)
      [ -z "$ZEN_PROFILE" ] && ZEN_PROFILE=$(find "$HOME/.zen" -maxdepth 1 -mindepth 1 -type d 2>/dev/null | head -1)

      if [ -n "$ZEN_PROFILE" ]; then
        mkdir -p "$ZEN_PROFILE/chrome"
        if [ -f "$COLORS_JSON" ]; then
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
          ' "$COLORS_JSON" > "$ZEN_PROFILE/chrome/matugen-vars.css"
        else
          printf ':root {\n  --matugen-background: #1e1e2e;\n  --matugen-surface: #313244;\n  --matugen-primary: #89b4fa;\n  --matugen-on-primary: #1e1e2e;\n  --matugen-secondary: #cba6f7;\n  --matugen-on-surface: #cdd6f4;\n  --matugen-outline: #6c7086;\n  --matugen-error: #f38ba8;\n}\n' \
            > "$ZEN_PROFILE/chrome/matugen-vars.css"
        fi

        if [ ! -f "$ZEN_PROFILE/chrome/userChrome.css" ]; then
          printf '@import "matugen-vars.css";\n' > "$ZEN_PROFILE/chrome/userChrome.css"
        elif ! grep -q 'matugen-vars' "$ZEN_PROFILE/chrome/userChrome.css" 2>/dev/null; then
          printf '@import "matugen-vars.css";\n' >> "$ZEN_PROFILE/chrome/userChrome.css"
        fi
      fi
    '';
  };
}
