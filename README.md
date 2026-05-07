### NixOS install

Run this from a NixOS live ISO:

```bash
sudo bash -c "$(curl -fL https://raw.githubusercontent.com/zhogoshi/dotfiles/main/install.sh)"
```

The installer runs as root because it writes to `/home`, `/mnt`, and `/etc/nixos`, formats disks, runs `nixos-install`, and reboots. Do not pipe it into `bash`: the installer is interactive, and piping makes prompts read from the script stream instead of the keyboard. If the live ISO already logs you in as `root`, `bash -c "$(curl -fL https://raw.githubusercontent.com/zhogoshi/dotfiles/main/install.sh)"` also works.