# Raspberry Pi VPN Setup — Command Reference

## 1. Install OpenVPN & Prepare Config

```bash
sudo apt update && sudo apt install openvpn -y

# Download your Surfshark .ovpn config from:
# surfshark.com → Account → VPN → Manual setup → OpenVPN

# Copy config to OpenVPN directory (must be .conf extension)
sudo cp ~/at-vie.prod.surfshark.com_udp.ovpn /etc/openvpn/surfshark.conf
```

---

## 2. Set Up Credentials

> ⚠️ Use your **Surfshark service credentials**, not your regular login.
> Find them at: surfshark.com → Account → VPN → Manual setup

```bash
# Create credentials file
sudo nano /etc/openvpn/auth.txt
```

File must contain exactly two lines:
```
your_service_username
your_service_password
```

```bash
# Secure the file
sudo chmod 600 /etc/openvpn/auth.txt
sudo chown root:root /etc/openvpn/auth.txt

# Check for Windows line endings (fix if you see ^M$)
sudo cat -A /etc/openvpn/auth.txt
sudo sed -i 's/\r//' /etc/openvpn/auth.txt
```

Then reference the file in your config:
```bash
sudo nano /etc/openvpn/surfshark.conf
# Make sure this line exists and is NOT commented out:
# auth-user-pass /etc/openvpn/auth.txt
```

---

## 3. Enable Auto-Connect on Boot

```bash
# Enable service (auto-start on boot)
sudo systemctl enable openvpn@surfshark

# Start now
sudo systemctl start openvpn@surfshark

# Check status
sudo systemctl status openvpn@surfshark
```

---

## 4. Auto-Reconnect on VPN Drop

```bash
sudo mkdir -p /etc/systemd/system/openvpn@surfshark.service.d/
sudo nano /etc/systemd/system/openvpn@surfshark.service.d/override.conf
```

Add:
```ini
[Service]
Restart=always
RestartSec=10
```

```bash
sudo systemctl daemon-reload
sudo systemctl restart openvpn@surfshark
```

---

## 5. Sync Clock (fixes TLS errors)

```bash
sudo timedatectl set-ntp true
sudo systemctl restart systemd-timesyncd
timedatectl status
# Confirm: "System clock synchronized: yes"
```

---

## 6. Verify VPN is Working

```bash
# Check tun0 interface is up
ip addr show tun0

# Check your public IP has changed
curl -4 ifconfig.me

# Check for IPv6 leaks (should return nothing)
curl -6 --max-time 5 ifconfig.me

# Watch live logs
sudo journalctl -u openvpn@surfshark -f
```

---

## 7. Disable IPV6 IP Address

### Fix — disable IPv6 completely on your Pi:
```bash
bash# Disable immediately (takes effect now)
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.eth0.disable_ipv6=1
Then make it permanent so it survives reboots:
bashsudo nano /etc/sysctl.conf
```

Add these lines at the bottom:
```bash
net.ipv6.conf.all.disable_ipv6=1
net.ipv6.conf.default.disable_ipv6=1
net.ipv6.conf.eth0.disable_ipv6=1
bash# Apply changes
sudo sysctl -p
Verify the leak is gone:
bashcurl -6 --max-time 5 ifconfig.me
```
# Should now return nothing or "curl: (28) Operation timed out"

----

## 8. Setup Kill Switch (block traffic if VPN drops)

Add these lines to your /etc/openvpn/surfshark.conf:

```bash
sudo nano /etc/openvpn/surfshark.conf
```

Add:
```bash
route-nopull
route 0.0.0.0 0.0.0.0 vpn_gateway
```
Then:
```bash
sudo ufw --force reset
```

### Run ufw setup script
```bash
chmod +x vpn_killswitch_simple.sh vpn_killswitch_RECOVERY.sh

# Run once to set everything up
sudo ./vpn_killswitch_simple.sh
```

---

## 9. Emergency Recovery (if internet breaks)

```bash
# Try restarting VPN first (safest, kill switch stays on)
sudo ./vpn_killswitch_RECOVERY.sh restore

# Check what's wrong
sudo ./vpn_killswitch_RECOVERY.sh status

# Temporarily disable kill switch to fix VPN (⚠️ unprotected)
sudo ./vpn_killswitch_RECOVERY.sh disable

# After fixing VPN, re-enable kill switch
sudo ./vpn_killswitch_RECOVERY.sh reenable
```

---

## 9. Common Commands Reference

| Task | Command |
|------|---------|
| Start VPN | `sudo systemctl start openvpn@surfshark` |
| Stop VPN | `sudo systemctl stop openvpn@surfshark` |
| Restart VPN | `sudo systemctl restart openvpn@surfshark` |
| Check VPN status | `sudo systemctl status openvpn@surfshark` |
| Live logs | `sudo journalctl -u openvpn@surfshark -f` |
| Check public IP | `curl -4 ifconfig.me` |
| Check tun0 is up | `ip addr show tun0` |
| Check UFW rules | `sudo ufw status verbose` |
| Disable IPv6 leak | `sudo sysctl -w net.ipv6.conf.eth0.disable_ipv6=1` |
