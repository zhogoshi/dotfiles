{ pkgs, lib, setupMode, useZen, ... }: lib.mkIf (!useZen)
{
  programs.firefox = {
    enable = true;
    profiles.hogoshi = {
      isDefault = true;
      userChrome = lib.mkIf (!setupMode) (builtins.readFile ./firefox-userchrome-template.css);
    };
  };

  home.activation = lib.mkIf (!setupMode) {
    firefoxMatugenColors = {
      after  = [ "writeBoundary" ];
      before = [];
      data   = ''
        COLORS_JSON="$HOME/.cache/matugen/colors.json"
        PROFILE_DIR="$HOME/.mozilla/firefox/hogoshi"
        mkdir -p "$PROFILE_DIR/chrome"
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
          ' "$COLORS_JSON" > "$PROFILE_DIR/chrome/matugen-vars.css"
        else
          printf ':root {\n  --matugen-background: #1e1e2e;\n  --matugen-surface: #313244;\n  --matugen-primary: #89b4fa;\n  --matugen-on-primary: #1e1e2e;\n  --matugen-secondary: #cba6f7;\n  --matugen-on-surface: #cdd6f4;\n  --matugen-outline: #6c7086;\n  --matugen-error: #f38ba8;\n}\n' \
            > "$PROFILE_DIR/chrome/matugen-vars.css"
        fi
      '';
    };
  };
}
