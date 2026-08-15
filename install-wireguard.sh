#!/usr/bin/env bash

set -euo pipefail

VPN_DIR="/etc/homevps/wireguard"
WG_INTERFACE="wg0"
WG_PORT="51820"
WG_NETWORK="10.8.0.0/24"
WG_SERVER_IP="10.8.0.1/24"

if [[ $EUID -ne 0 ]]; then
    echo "Run this script as root."
    exit 1
fi

echo "=== HomeVPS WireGuard Setup ==="

apt-get update
apt-get install -y wireguard iptables qrencode

mkdir -p "$VPN_DIR"
chmod 700 "$VPN_DIR"

# Detect the public network interface.
WAN_INTERFACE="$(ip route get 1.1.1.1 | awk '{print $5; exit}')"

if [[ -z "$WAN_INTERFACE" ]]; then
    echo "Could not determine WAN interface."
    exit 1
fi

echo "WAN interface: $WAN_INTERFACE"

# Enable IPv4 forwarding.
cat > /etc/sysctl.d/99-homevps-vpn.conf <<EOF
net.ipv4.ip_forward=1
EOF

sysctl --system

# Generate server private key.
if [[ ! -f "$VPN_DIR/server_private.key" ]]; then
    umask 077
    wg genkey > "$VPN_DIR/server_private.key"
fi

SERVER_PRIVATE_KEY="$(cat "$VPN_DIR/server_private.key")"

# Generate server configuration.
cat > "$VPN_DIR/server.conf" <<EOF
[Interface]
Address = $WG_SERVER_IP
ListenPort = $WG_PORT
PrivateKey = $SERVER_PRIVATE_KEY

# VPN client traffic -> Internet
PostUp = iptables -A FORWARD -i %i -j ACCEPT; iptables -A FORWARD -o %i -j ACCEPT; iptables -t nat -A POSTROUTING -s $WG_NETWORK -o $WAN_INTERFACE -j MASQUERADE
PostDown = iptables -D FORWARD -i %i -j ACCEPT; iptables -D FORWARD -o %i -j ACCEPT; iptables -t nat -D POSTROUTING -s $WG_NETWORK -o $WAN_INTERFACE -j MASQUERADE
EOF

chmod 600 "$VPN_DIR/server.conf"

# Allow WireGuard through UFW if UFW is installed.
if command -v ufw >/dev/null 2>&1; then
    ufw allow "$WG_PORT/udp"
fi

# Enable and start WireGuard.
systemctl enable "wg-quick@$WG_INTERFACE"
systemctl restart "wg-quick@$WG_INTERFACE"

echo
echo "WireGuard is running."
echo
wg show
echo
echo "VPN network: $WG_NETWORK"
echo "VPN port:    $WG_PORT/UDP"
echo "Interface:   $WAN_INTERFACE"
echo
echo "Next:"
echo "  sudo ./add-client.sh laptop"
