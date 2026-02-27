#!/bin/bash

# ===========================================
#   VPN KILL SWITCH — RECOVERY SCRIPT
#
#   Run this if your internet stops working.
#
#   OPTIONS:
#     sudo ./vpn_killswitch_RECOVERY.sh restore   → restart VPN, keep kill switch active
#     sudo ./vpn_killswitch_RECOVERY.sh disable    → temporarily disable kill switch
#     sudo ./vpn_killswitch_RECOVERY.sh reenable   → re-enable kill switch after fixing VPN
#     sudo ./vpn_killswitch_RECOVERY.sh status     → check current state
# ===========================================

if [ "$EUID" -ne 0 ]; then
    echo "❌ Please run as root: sudo ./vpn_killswitch_RECOVERY.sh [restore|disable|reenable|status]"
    exit 1
fi

ACTION=${1:-status}

echo "=========================================="
echo "   VPN RECOVERY TOOL"
echo "=========================================="
echo ""

check_status() {
    echo "[ VPN STATUS ]"
    if ip addr show tun0 &>/dev/null; then
        echo "✅ tun0 is UP — VPN is running"
    else
        echo "❌ tun0 is DOWN — VPN is not connected"
    fi

    echo ""
    echo "[ OPENVPN PROCESS ]"
    if pgrep -x openvpn > /dev/null; then
        echo "✅ OpenVPN process running (PID: $(pgrep -x openvpn))"
    else
        echo "❌ OpenVPN is NOT running"
    fi

    echo ""
    echo "[ UFW OUTBOUND POLICY ]"
    ufw status verbose | grep "Default:"

    echo ""
    echo "[ INTERNET REACHABILITY ]"
    PUBLIC=$(curl -4 -s --max-time 5 ifconfig.me)
    if [ -n "$PUBLIC" ]; then
        echo "✅ Internet reachable — public IP: $PUBLIC"
    else
        echo "❌ Internet NOT reachable (kill switch blocking or VPN down)"
    fi
}

restore_vpn() {
    # Step 1: try restarting OpenVPN — kill switch stays fully active
    echo "→ Restarting OpenVPN service..."
    systemctl restart openvpn@surfshark

    echo "→ Waiting for tun0 (up to 30 seconds)..."
    for i in $(seq 1 30); do
        if ip addr show tun0 &>/dev/null; then
            echo "✅ VPN restored after ${i}s — kill switch still active"
            echo "   Public IP: $(curl -4 -s --max-time 5 ifconfig.me)"
            return
        fi
        sleep 1
        echo -n "."
    done

    echo ""
    echo "❌ VPN failed to reconnect after 30s"
    echo ""
    echo "   Check logs for the cause:"
    echo "   sudo journalctl -u openvpn@surfshark -n 50 --no-pager"
    echo ""
    echo "   If you need internet urgently, run:"
    echo "   sudo ./vpn_killswitch_RECOVERY.sh disable"
}

disable_killswitch() {
    # Temporarily allow all outbound traffic so you can fix the VPN
    # ⚠️ Your real IP will be visible while this is active
    echo "⚠️  Temporarily disabling kill switch..."
    echo "   Your real IP will be exposed until you re-enable it!"
    echo ""

    ufw default allow outgoing
    ufw reload

    echo "✅ Kill switch DISABLED — internet restored"
    echo "   Public IP: $(curl -4 -s --max-time 5 ifconfig.me)"
    echo ""
    echo "   Fix your VPN, then re-enable the kill switch:"
    echo "   sudo ./vpn_killswitch_RECOVERY.sh reenable"
}

reenable_killswitch() {
    # Re-enable outbound blocking after fixing the VPN
    echo "→ Re-enabling kill switch..."

    ufw default deny outgoing
    ufw reload

    echo "✅ Kill switch re-enabled"
    echo ""

    # Verify VPN is up before finishing
    if ip addr show tun0 &>/dev/null; then
        echo "✅ VPN is UP — you are protected"
        echo "   Public IP: $(curl -4 -s --max-time 5 ifconfig.me)"
    else
        echo "⚠️  VPN is still DOWN — internet will be blocked"
        echo "   Start VPN with: sudo systemctl start openvpn@surfshark"
    fi
}

case "$ACTION" in
    restore)    restore_vpn ;;
    disable)    disable_killswitch ;;
    reenable)   reenable_killswitch ;;
    status)     check_status ;;
    *)
        echo "Unknown option: $ACTION"
        echo "Usage: sudo ./vpn_killswitch_RECOVERY.sh [restore|disable|reenable|status]"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
