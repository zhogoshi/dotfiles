{ inputs, pkgs, ... }:

let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.system};
in
{
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];

  programs.spicetify = {
    enable = true;
    theme  = spicePkgs.themes.comfy;
    colorScheme = "Spotify";

    enabledExtensions = with spicePkgs.extensions; [
      adblock
      hidePodcasts
    ];
  };

  home.activation.spicetifyMatugenColors = {
    after  = [ "writeBoundary" ];
    before = [];
    data   = ''
      COLORS_JSON="$HOME/.cache/matugen/colors.json"
      SPICETIFY_DIR="$HOME/.config/spicetify"
      mkdir -p "$SPICETIFY_DIR"
      if [ -f "$COLORS_JSON" ]; then
        ${pkgs.jq}/bin/jq -r '
          .colors.dark |
          "text=" + (.on_surface | ltrimstr("#")),
          "subtext=" + (.outline | ltrimstr("#")),
          "sidebar-text=" + (.on_surface | ltrimstr("#")),
          "main=" + (.surface | ltrimstr("#")),
          "sidebar=" + (.surface_variant | ltrimstr("#")),
          "player=" + (.surface | ltrimstr("#")),
          "card=" + (.surface_variant | ltrimstr("#")),
          "shadow=" + (.surface | ltrimstr("#")),
          "selected-row=" + (.primary_container | ltrimstr("#")),
          "button=" + (.primary | ltrimstr("#")),
          "button-active=" + (.on_primary | ltrimstr("#")),
          "button-disabled=" + (.outline | ltrimstr("#")),
          "tab-active=" + (.secondary_container | ltrimstr("#")),
          "notification=" + (.tertiary | ltrimstr("#")),
          "notification-error=" + (.error | ltrimstr("#")),
          "misc=" + (.outline | ltrimstr("#"))
        ' "$COLORS_JSON" > "$SPICETIFY_DIR/matugen-colors.ini"
      fi
    '';
  };
}
