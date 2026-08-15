#!/usr/bin/env bash

set -euo pipefail

VPN_DIR="/etc/homevps/wireguard"
SERVER_CONFIG="$VPN_DIR/server.conf"
CLIENT_DIR="$VPN_DIR/clients"
WG_INTERFACE="wg0"
WG_NETWORK_PREFIX="10.8.0"

if [[ $EUID -ne 0 ]]; then
    echo "Run this script as root."
    exit 1
fi

CLIENT_NAME="${1:-}"

if [[ -z "$CLIENT_NAME" ]]; then
    echo "Usage:"
    echo "  sudo $0 <client-name>"
    echo
    echo "Example:"
    echo "  sudo $0 laptop"
    exit 1
fi

if [[ ! "$CLIENT_NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "Invalid client name."
    echo "Use only letters, numbers, '_' and '-'."
    exit 1
fi

mkdir -p "$CLIENT_DIR"
chmod 700 "$CLIENT_DIR"

CLIENT_DIR="$CLIENT_DIR/$CLIENT_NAME"

if [[ -e "$CLIENT_DIR" ]]; then
    echo "Client already exists: $CLIENT_NAME"
    exit 1
fi

mkdir -p "$CLIENT_DIR"
chmod 700 "$CLIENT_DIR"

# Find next available address.
USED_IPS="$(grep -rhoE '10\.8\.0\.[0-9]+' "$VPN_DIR" 2>/dev/null || true)"

CLIENT_IP=""

for LAST_OCTET in $(seq 2 254); do
    CANDIDATE="$WG_NETWORK_PREFIX.$LAST_OCTET"

    if ! echo "$USED_IPS" | grep -qx "$CANDIDATE"; then
        CLIENT_IP="$CANDIDATE"
        break
    fi
done

if [[ -z "$CLIENT_IP" ]]; then
    echo "No available VPN addresses."
    exit 1
fi

# Generate client keys.
umask 077

wg genkey > "$CLIENT_DIR/private.key"
wg pubkey < "$CLIENT_DIR/private.key" > "$CLIENT_DIR/public.key"

CLIENT_PRIVATE_KEY="$(cat "$CLIENT_DIR/private.key")"
CLIENT_PUBLIC_KEY="$(cat "$CLIENT_DIR/public.key")"

SERVER_PUBLIC_KEY="$(
    wg pubkey < "$VPN_DIR/server_private.key"
)"

# Determine server's public IP.
SERVER_ENDPOINT="${SERVER_ENDPOINT:-}"

if [[ -z "$SERVER_ENDPOINT" ]]; then
    SERVER_ENDPOINT="$(curl -4 -fsS https://api.ipify.org || true)"
fi

if [[ -z "$SERVER_ENDPOINT" ]]; then
    echo "Could not determine public IP."
    echo "Run:"
    echo "  SERVER_ENDPOINT=your.domain.example $0 $CLIENT_NAME"
    exit 1
fi

# Add peer to persistent server configuration.
cat >> "$SERVER_CONFIG" <<EOF

# Client: $CLIENT_NAME
[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = $CLIENT_IP/32
EOF

chmod 600 "$SERVER_CONFIG"

# Add peer to the currently running interface.
wg set "$WG_INTERFACE" \
    peer "$CLIENT_PUBLIC_KEY" \
    allowed-ips "$CLIENT_IP/32"

# Generate client configuration.
cat > "$CLIENT_DIR/$CLIENT_NAME.conf" <<EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP/32
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_ENDPOINT:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

chmod 600 "$CLIENT_DIR/$CLIENT_NAME.conf"

# Generate QR code.
if command -v qrencode >/dev/null 2>&1; then
    qrencode \
        -t ansiutf8 \
        < "$CLIENT_DIR/$CLIENT_NAME.conf" \
        > "$CLIENT_DIR/$CLIENT_NAME.qr.txt"
fi

echo
echo "======================================"
echo " WireGuard client created"
echo "======================================"
echo
echo "Name:      $CLIENT_NAME"
echo "VPN IP:    $CLIENT_IP"
echo "Config:    $CLIENT_DIR/$CLIENT_NAME.conf"
echo
echo "To display the QR code:"
echo
echo "  cat '$CLIENT_DIR/$CLIENT_NAME.qr.txt'"
echo
echo "Keep the .conf and private key secret."
