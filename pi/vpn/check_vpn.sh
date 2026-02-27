#!/bin/bash

echo "=========================================="
echo "         VPN & IP STATUS CHECK"
echo "=========================================="

# --- VPN Interface ---
echo ""
echo "[ VPN INTERFACE (tun0) ]"
if ip addr show tun0 &>/dev/null; then
    echo "✅ OpenVPN is UP"
    VPN_IPV4=$(ip addr show tun0 | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
    VPN_IPV6=$(ip addr show tun0 | grep 'inet6' | awk '{print $2}' | cut -d/ -f1)
    echo "   VPN IPv4 : ${VPN_IPV4:-none}"
    echo "   VPN IPv6 : ${VPN_IPV6:-none}"
else
    echo "❌ OpenVPN is DOWN (tun0 not found)"
fi

# --- Real Interface (eth0 or wlan0) ---
echo ""
echo "[ REAL INTERFACE (eth0) ]"
REAL_IPV4=$(ip addr show eth0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)
REAL_IPV6=$(ip addr show eth0 2>/dev/null | grep 'inet6' | grep -v 'fe80' | awk '{print $2}' | cut -d/ -f1)
REAL_IPV6_LL=$(ip addr show eth0 2>/dev/null | grep 'inet6' | grep 'fe80' | awk '{print $2}' | cut -d/ -f1)
echo "   Local IPv4       : ${REAL_IPV4:-none}"
echo "   Public IPv6      : ${REAL_IPV6:-none}"
echo "   Link-local IPv6  : ${REAL_IPV6_LL:-none} (fe80:: — never routable, safe)"

# --- What the internet sees ---
echo ""
echo "[ WHAT THE INTERNET SEES ]"
PUBLIC_IPV4=$(curl -4 -s --max-time 5 https://ifconfig.me)
PUBLIC_IPV6=$(curl -6 -s --max-time 5 https://ifconfig.me)
echo "   Public IPv4 : ${PUBLIC_IPV4:-could not retrieve}"
echo "   Public IPv6 : ${PUBLIC_IPV6:-none (good — means IPv6 is blocked or not leaking)}"

# --- DNS Check ---
echo ""
echo "[ DNS SERVERS IN USE ]"
grep 'nameserver' /etc/resolv.conf | awk '{print "   " $2}'

# --- Verdict ---
echo ""
echo "[ VERDICT ]"
if [ -z "$PUBLIC_IPV6" ]; then
    echo "✅ No IPv6 leak detected — internet only sees your IPv4"
else
    echo "⚠️  IPv6 is exposed to the internet: $PUBLIC_IPV6"
    echo "   To fix, disable IPv6 on eth0:"
    echo "   sudo sysctl -w net.ipv6.conf.eth0.disable_ipv6=1"
fi

if [ -n "$PUBLIC_IPV4" ] && [ "$PUBLIC_IPV4" = "$REAL_IPV4" ]; then
    echo "⚠️  Your real IP is exposed! VPN may not be routing traffic."
elif [ -n "$PUBLIC_IPV4" ]; then
    echo "✅ Public IPv4 differs from local IP — traffic is likely going through VPN"
fi

echo ""
echo "=========================================="
