{ ... }: {
  home.file.".config/hypr/autostart.conf".text = ''
    exec-once = zen
    exec-once = Throne
    exec-once = cursor
    exec-once = Telegram
    exec-once = vesktop
    exec-once = steam

    windowrulev2 = workspace 1 silent, class:^(zen-alpha|zen)$
    windowrulev2 = workspace 1 silent, class:^(throne|Throne)$
    windowrulev2 = workspace 2 silent, class:^(cursor-url-handler|cursor|Cursor)$
    windowrulev2 = workspace 3 silent, class:^(org.telegram.desktop)$
    windowrulev2 = workspace 3 silent, class:^(vesktop|Vesktop)$
    windowrulev2 = workspace 4 silent, class:^(steam|Steam)$
  '';
}
