### NixOS install

Run this from a NixOS live ISO:

```bash
curl -fL https://raw.githubusercontent.com/zhogoshi/dotfiles/main/install.sh | sudo bash
```

The installer runs as root because it writes to `/home`, `/mnt`, and `/etc/nixos`, formats disks, runs `nixos-install`, and reboots. If the live ISO already logs you in as `root`, `sudo bash` still works; running local `bash install.sh` as root also works.