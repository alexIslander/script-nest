#!/bin/bash
PI_IP=10.0.0.185; APP="${1:-n8n}"
dig @$PI_IP $APP.home.lan +short
curl -skI --resolve $APP.home.lan:443:$PI_IP https://$APP.home.lan | head -1
echo "Public IP (should be VPN): $(curl -s -4 --connect-timeout 10 ifconfig.me)"
docker exec pihole dig +short example.com | head -1
