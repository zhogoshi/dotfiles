### NixOS install

Run this from a NixOS live ISO:

```bash
curl -fsSL https://raw.githubusercontent.com/zhogoshi/dotfiles/main/install.sh | bash
```

Do not prefix it with `sudo`. The installer calls `sudo` only for the steps that need root access, such as formatting disks, mounting, running `nixos-install`, and rebooting. If the live ISO already logs you in as `root`, the same command still works.