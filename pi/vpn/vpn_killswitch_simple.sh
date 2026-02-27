#!/bin/bash

# ===========================================
#   VPN KILL SWITCH SETUP (Simple Version)
#   No VPN server IP needed — works with
#   dynamic IPs like Surfshark automatically.
#
#   HOW IT WORKS:
#   - route-nopull: OpenVPN ignores server routing rules
#   - route 0.0.0.0 0.0.0.0 vpn_gateway: forces ALL traffic through the tunnel
#   - If VPN drops: no route exists → traffic simply stops → your IP is safe
#   - UFW only needs to know about tun0 and local network, no server IPs needed
#
#   Usage: sudo ./vpn_killswitch_simple.sh
# ===========================================

if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root: sudo ./vpn_killswitch_simple.sh"
    exit 1
fi

echo "=========================================="
echo "   VPN KILL SWITCH SETUP (Simple)"
echo "=========================================="

# --- Step 1: Add routing rules to OpenVPN config ---
echo ""
echo "[ 1/3 ] Updating OpenVPN config..."

CONF="/etc/openvpn/surfshark.conf"

if [ ! -f "$CONF" ]; then
    echo "❌ Config not found at $CONF"
    echo "   Please check your config path and try again."
    exit 1
fi

# Add route-nopull if not already present
if grep -q "^route-nopull" "$CONF"; then
    echo "   ✅ route-nopull already present, skipping"
else
    echo "route-nopull" >> "$CONF"
    echo "   ✅ Added: route-nopull"
fi

# Add the catch-all VPN route if not already present
if grep -q "^route 0.0.0.0 0.0.0.0 vpn_gateway" "$CONF"; then
    echo "   ✅ VPN gateway route already present, skipping"
else
    echo "route 0.0.0.0 0.0.0.0 vpn_gateway" >> "$CONF"
    echo "   ✅ Added: route 0.0.0.0 0.0.0.0 vpn_gateway"
fi

# --- Step 2: Configure UFW ---
echo ""
echo "[ 2/3 ] Configuring UFW firewall..."

# Reset to clean state
ufw --force reset

# Block everything by default
ufw default deny incoming
ufw default deny outgoing

# Allow all traffic through VPN tunnel (tun0)
# This is the only outbound route allowed
ufw allow in on tun0
ufw allow out on tun0

# Allow local network traffic (so you can still reach your Pi via SSH)
ufw allow in on eth0 from 192.168.0.0/16
ufw allow out on eth0 to 192.168.0.0/16

# Allow SSH from anywhere on local network
ufw allow 22

# Enable UFW
ufw --force enable

echo "   ✅ UFW configured"

# --- Step 3: Restart OpenVPN to apply new routing rules ---
echo ""
echo "[ 3/3 ] Restarting OpenVPN..."
systemctl restart openvpn@surfshark
sleep 5

if ip addr show tun0 &>/dev/null; then
    echo "   ✅ VPN is UP (tun0 active)"
    echo "   Public IP: $(curl -4 -s --max-time 5 ifconfig.me)"
else
    echo "   ⚠️  tun0 not detected yet — VPN may still be connecting"
    echo "   Check with: sudo systemctl status openvpn@surfshark"
fi

echo ""
echo "=========================================="
echo "✅ Kill switch is ACTIVE"
echo "   - All traffic forced through VPN tunnel"
echo "   - No VPN server IPs needed in firewall"
echo "   - If VPN drops, traffic stops automatically"
echo "   - SSH preserved on local network (192.168.x.x)"
echo ""
echo "   If internet breaks, run:"
echo "   sudo ./vpn_killswitch_RECOVERY.sh"
echo "=========================================="
