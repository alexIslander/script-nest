#!/bin/bash

# --- CONFIGURATION ---
LOCAL_NET="10.0.0.0/24"
GATEWAY="10.0.0.138"
VPN_PORT="1194"
DNS_SERVERS=("10.0.0.185" "1.1.1.1")     # Pi-hole first, fallback second

PI_IP="${PI_IP:-10.0.0.185}"

echo "--- [1/7] Hard-Disabling IPv6 (Prevent Leaks) ---"
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1 > /dev/null
sudo sysctl -w net.ipv6.conf.eth0.disable_ipv6=1 > /dev/null

echo "--- [2/7] Cleaning up old processes ---"
sudo systemctl stop openvpn@surfshark 2>/dev/null
sudo killall openvpn 2>/dev/null
sudo ip link delete tun0 2>/dev/null

echo "--- [3/7] Restoring Temporary Connectivity ---"
# We no longer use iptables -F (flush) or -X (delete chains)
# Instead, we create a custom chain if it doesn't exist, and flush ONLY that chain.
sudo iptables -t filter -N VPN_KILLSWITCH 2>/dev/null
sudo iptables -t filter -F VPN_KILLSWITCH
# Ensure the custom chain is linked to OUTPUT
sudo iptables -t filter -C OUTPUT -j VPN_KILLSWITCH 2>/dev/null || sudo iptables -t filter -A OUTPUT -j VPN_KILLSWITCH

sudo ip route add default via $GATEWAY dev eth0 2>/dev/null

echo "--- [4/7] Setting Kill Switch Firewall Rules ---"
# Set default policies without flushing existing chains (like DOCKER)
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT

# Clear rules within our custom chain
sudo iptables -F VPN_KILLSWITCH

# Add rules to the custom VPN chain instead of global OUTPUT
sudo iptables -A VPN_KILLSWITCH -o lo -j ACCEPT
sudo iptables -A VPN_KILLSWITCH -d $LOCAL_NET -j ACCEPT
sudo iptables -A VPN_KILLSWITCH -o docker0 -j ACCEPT
sudo iptables -A VPN_KILLSWITCH -o br+ -j ACCEPT
sudo iptables -A VPN_KILLSWITCH -p udp --dport 53 -j ACCEPT
sudo iptables -A VPN_KILLSWITCH -p tcp --dport 53 -j ACCEPT
sudo iptables -A VPN_KILLSWITCH -p tcp --dport 443 -j ACCEPT
sudo iptables -A VPN_KILLSWITCH -p udp --dport 443 -j ACCEPT
sudo iptables -A VPN_KILLSWITCH -p tcp --dport 587 -d mail.csetesandor.hu -j ACCEPT
sudo iptables -A VPN_KILLSWITCH -p udp --dport 587 -d mail.csetesandor.hu -j ACCEPT
sudo iptables -A VPN_KILLSWITCH -p udp --dport $VPN_PORT -j ACCEPT
sudo iptables -A VPN_KILLSWITCH -o tun+ -j ACCEPT

# IMPORTANT: Drop everything else in the VPN_KILLSWITCH chain to act as the kill switch
# We use DROP for host traffic so it cannot leak
sudo iptables -A VPN_KILLSWITCH -j DROP

echo "--- [4b/7] Kill switch for Docker containers ---"
sudo iptables -N VPN_FWD_GUARD 2>/dev/null; sudo iptables -F VPN_FWD_GUARD
sudo iptables -A VPN_FWD_GUARD -d $LOCAL_NET -j RETURN
sudo iptables -A VPN_FWD_GUARD -o tun+ -j RETURN
sudo iptables -A VPN_FWD_GUARD -o docker0 -j RETURN
sudo iptables -A VPN_FWD_GUARD -o br-+ -j RETURN      # compose networks
sudo iptables -A VPN_FWD_GUARD -o eth0 -j DROP        # any container traffic to the internet via eth0
sudo iptables -C DOCKER-USER -j VPN_FWD_GUARD 2>/dev/null || sudo iptables -I DOCKER-USER -j VPN_FWD_GUARD

echo "--- [5/7] Forcing Secure DNS ---"
echo -e "nameserver ${DNS_SERVERS[0]}\nnameserver ${DNS_SERVERS[1]}" | sudo tee /etc/resolv.conf > /dev/null

echo "--- [6/7] Launching OpenVPN ---"
sudo systemctl start openvpn@surfshark

echo "------------------------------------------"
echo "Waiting 12 seconds for tunnel initialization..."
sleep 12

echo "--- [7/7] Final Status Check ---"
if ip addr show tun0 > /dev/null 2>&1; then
    echo "✅ VPN Interface (tun0) is UP."
    IPV6_CHECK=$(ip -6 addr show eth0 | grep inet6)
    [ -z "$IPV6_CHECK" ] && echo "✅ IPv6 is disabled." || echo "⚠️ WARNING: IPv6 active!"
    
    PUBLIC_IP=$(curl -s -4 --connect-timeout 10 ifconfig.me)
    echo "✅ Current Public IPv4: $PUBLIC_IP"
else
    echo "❌ FAILED: tun0 did not initialize."
fi
