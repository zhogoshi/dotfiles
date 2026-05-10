{ useZen, ... }: {
  home.file.".config/hypr/autostart.conf".text = ''
    exec-once = ${if useZen then "zen" else "firefox"}
    exec-once = Throne
    exec-once = cursor
    exec-once = Telegram
    exec-once = vesktop
    exec-once = steam

    windowrule = workspace 1 silent, match:class ^(${if useZen then "zen-alpha|zen" else "firefox"})$
    windowrule = workspace 1 silent, match:class ^(throne|Throne)$
    windowrule = workspace 2 silent, match:class ^(cursor-url-handler|cursor|Cursor)$
    windowrule = workspace 3 silent, match:class ^(org.telegram.desktop)$
    windowrule = workspace 3 silent, match:class ^(vesktop|Vesktop)$
    windowrule = workspace 4 silent, match:class ^(steam|Steam)$
  '';
}
