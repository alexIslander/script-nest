#!/bin/bash
set -e
CASAOS_NEW_PORT="${CASAOS_NEW_PORT:-8081}"

# --- A) CasaOS gateway to another port ---
if sudo ss -tlnp | grep -E '0\.0\.0\.0:80 |\*:80 ' | grep -qi casaos; then
  echo "CasaOS holds :80 on all interfaces, moving it to $CASAOS_NEW_PORT"
  sudo cp /etc/casaos/gateway.ini /etc/casaos/gateway.ini.bak
  sudo sed -i "s/^port=.*/port=$CASAOS_NEW_PORT/" /etc/casaos/gateway.ini
  sudo systemctl restart casaos-gateway   # verify the name with: systemctl list-units | grep casaos
else
  echo "CasaOS is not on 0.0.0.0:80 -> use variant B: bind Traefik ports to 10.0.0.185:80/443"
fi

# --- systemd-resolved stub frees :53 (only if it's active) ---
if systemctl is-active --quiet systemd-resolved; then
  sudo mkdir -p /etc/systemd/resolved.conf.d
  printf '[Resolve]\nDNSStubListener=no\n' | sudo tee /etc/systemd/resolved.conf.d/nostub.conf >/dev/null
  sudo systemctl restart systemd-resolved
fi
sudo ss -tlnup | grep -E ':(80|53) ' || echo "✅ 80 and 53 are free"
