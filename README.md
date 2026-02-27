# script-nest
Collection of bash scripts, to make life easier in terminal.

## 📝 Full Automated Workflow

Here is the complete sequence of commands you should run:

### Initial Setup (Once):

```bash
chmod +x mount_chroot.sh unmount_chroot.sh kernel_identifier.sh kernel_fixer.sh
```

### Mount and Identify:

```bash
sudo ./mount_chroot.sh

sudo ./kernel_identifier.sh
```

Check the output of the identifier script for the version and confirm it saved to kernel_version.txt.

### Fix Kernel/Boot:

```bash
sudo ./kernel_fixer.sh
```

### Final Cleanup and Reboot:

```bash
sudo ./unmount_chroot.sh

sudo poweroff
```

This automated process addresses all the failed steps we encountered: the manual mounting, the missing `/dev/pts` and `/tmp` bind-mounts, the unknown kernel package name, and the missing kernel modules (`/lib/modules`). This is your best chance for a successful USB boot!

## Raspberry Pi VPN Scripts
All VPN automation lives in `pi/vpn/`. These scripts assume you already have Surfshark's OpenVPN profile installed as `/etc/openvpn/surfshark.conf`, service credentials stored in `/etc/openvpn/auth.txt`, IPv6 disabled in `/etc/sysctl.conf`, and `openvpn@surfshark` enabled at boot.

| Script | Purpose |
| --- | --- |
| `check_vpn.sh` | Verifies `tun0` is up, compares local vs public IPs, and confirms there are no IPv6 or DNS leaks.
| `vpn_killswitch_simple.sh` | Appends `route-nopull` + default VPN route to the config, rebuilds UFW to only allow `tun0` + LAN, then restarts OpenVPN for a routing-based kill switch.
| `vpn_killswitch_RECOVERY.sh` | Provides `status`, `restore`, `disable`, and `reenable` actions so you can recover from outages without exposing your IP longer than necessary.
| `vpn_setup_guide.md` | Command reference that documents the manual setup (install OpenVPN, fix auth, enable auto-restart, disable IPv6, sync clock).

Follow the detailed usage workflow in `pi/vpn/README.md` before invoking the scripts so every step (kill switch, verification, recovery) happens in the right order.
