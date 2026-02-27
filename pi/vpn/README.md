# Raspberry Pi VPN Scripts

These helpers lock a Surfshark-backed OpenVPN connection to the Pi itself so containers inherit the tunnel, tracker traffic stops timing out, and traffic dies automatically if the VPN disappears.

## Before You Run Them
- OpenVPN service `openvpn@surfshark` is already installed `sudo apt install openvpn`, enabled at boot, and points to `/etc/openvpn/surfshark.conf` with `auth-user-pass /etc/openvpn/auth.txt`.
- Surfshark service credentials live in `/etc/openvpn/auth.txt` (two lines, UNIX line endings, chmod 600).
- IPv6 is disabled system-wide via `/etc/sysctl.conf` so `curl -6 ifconfig.me` returns nothing.
- Clock is synced (e.g., `timedatectl set-ntp true`) to avoid TLS authentication errors.
- You have sudo access; every script must be run with `sudo`.

## Scripts at a Glance
| Script | Run as | What it does |
| --- | --- | --- |
| `check_vpn.sh` | `sudo ./check_vpn.sh` | Prints tunnel state, local vs public IPs, IPv6 leak status, and DNS resolvers.
| `vpn_killswitch_simple.sh` | `sudo ./vpn_killswitch_simple.sh` | Appends `route-nopull` + default VPN route to `surfshark.conf`, rebuilds UFW to only allow `tun0` + LAN, then restarts OpenVPN.
| `vpn_killswitch_RECOVERY.sh` | `sudo ./vpn_killswitch_RECOVERY.sh [status|restore|disable|reenable]` | Restarts the VPN, temporarily relaxes or re-applies the firewall, and reports connectivity so you can recover from outages.
| `vpn_setup_guide.md` | — | Full command reference for installing OpenVPN, fixing auth issues, syncing the clock, and disabling IPv6.

## Typical Flow
1. **Bootstrap kill switch**: `sudo ./vpn_killswitch_simple.sh` enforces routing-based protection, so if the tunnel drops there is simply no route to the internet.
2. **Verify protection**: `sudo ./check_vpn.sh` confirms `tun0`, shows your Surfshark IP, and ensures IPv6 stays blocked.
3. **Recover fast**: If the internet stops, run `sudo ./vpn_killswitch_RECOVERY.sh restore`. Use `disable` only when you intentionally need plaintext access, then `reenable` once the VPN is fixed.

## Tips & Troubleshooting
- Trackers timing out again usually means the OpenVPN service stopped. Check `sudo systemctl status openvpn@surfshark` or view logs with `journalctl -u openvpn@surfshark -n 50`.
- If Surfshark rotation changes the endpoint IP, nothing in UFW needs updating because traffic is routed exclusively through `tun0` (`route-nopull` + `route 0.0.0.0 0.0.0.0 vpn_gateway`).
- Seeing your real IPv4 or any IPv6 from `check_vpn.sh` means the kill switch is bypassed—rerun the simple kill-switch script and confirm IPv6 remains disabled.

