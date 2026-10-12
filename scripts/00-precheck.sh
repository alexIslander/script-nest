#!/bin/bash
# Read-only. Changes nothing.
PI_IP="${PI_IP:-10.0.0.185}"
ok(){ echo "✅ $*"; }; warn(){ echo "⚠️  $*"; }; bad(){ echo "❌ $*"; }

echo "== Who listens on 80/443/53 =="
sudo ss -tlnup | grep -E ':(80|443|53) ' || echo "(nothing found)"

echo; echo "== Port 53 conflicts =="
if sudo ss -tlnup | grep -E ':53 ' | grep -qv docker-proxy; then
  warn "Something already uses :53 (systemd-resolved stub on 127.0.0.53 is the usual suspect)"
  systemctl is-active systemd-resolved 2>/dev/null
else ok ":53 is free"; fi

echo; echo "== CasaOS =="
ls /etc/casaos 2>/dev/null || warn "no /etc/casaos"
systemctl list-units --no-pager | grep -i casaos
grep -rEi '^\s*port' /etc/casaos/gateway.ini 2>/dev/null

echo; echo "== Docker =="
docker --version && docker compose version
docker network ls --format '{{.Name}}' | grep -qx proxy && ok "network 'proxy' exists" || warn "network 'proxy' missing"
docker ps --format '  {{.Names}}\t{{.Ports}}' | grep -E 'traefik|pihole|n8n'

echo; echo "== Pi network =="
ip -4 addr show eth0 | grep inet
ip route | grep default
grep -E '^nameserver' /etc/resolv.conf
ip addr show "$PI_IP" >/dev/null 2>&1 || ip -4 addr show | grep -q "$PI_IP" && ok "Pi has $PI_IP" || bad "Pi does NOT have $PI_IP"
echo "(Make sure the router has a DHCP reservation for $PI_IP, or the Pi uses a static IP.)"

echo; echo "== VPN / kill switch =="
ip addr show tun0 >/dev/null 2>&1 && ok "tun0 up" || warn "tun0 down"
sudo iptables -S VPN_KILLSWITCH 2>/dev/null | head -20
