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
2. Connect to your VPN using `Super + K` (throne).
3. Run the post-install script to finalize the configuration (disables setupMode, enables monitor settings, etc.):

```bash
bash ~/nixos/post-install.sh
```