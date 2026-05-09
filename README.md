### NixOS install

Run this from a NixOS live ISO:

```bash
git clone https://github.com/zhogoshi/dotfiles.git
cd dotfiles
sudo bash install.sh
```

The installer runs as root because it writes to `/home`, `/mnt`, and `/etc/nixos`, formats disks, runs `nixos-install`, and reboots. 

### Post-installation

After the system reboots:
1. Log in with your new user and password.
2. Connect to your VPN using `Super + K` (throne). **An active VPN connection is strictly required** before proceeding (Ambxst installation, NixOS cache substituters, and other resources are blocked in some regions).
3. Run the post-install script:

```bash
bash ~/nixos/post-install.sh
```

**Note:** The post-install script will install Ambxst, apply the Ambxst theme by injecting its source line into `hyprland.conf`, reposition your user overrides (input/misc) below it, disable setup mode, and rebuild the full system.