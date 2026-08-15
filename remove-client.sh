#!/usr/bin/env bash

set -euo pipefail

VPN_DIR="/etc/homevps/wireguard"
SERVER_CONFIG="$VPN_DIR/server.conf"
CLIENT_DIR="$VPN_DIR/clients"
WG_INTERFACE="wg0"

if [[ $EUID -ne 0 ]]; then
    echo "Run this script as root."
    exit 1
fi

CLIENT_NAME="${1:-}"

if [[ -z "$CLIENT_NAME" ]]; then
    echo "Usage:"
    echo "  sudo $0 <client-name>"
    exit 1
fi

CLIENT_PATH="$CLIENT_DIR/$CLIENT_NAME"

if [[ ! -d "$CLIENT_PATH" ]]; then
    echo "Client does not exist: $CLIENT_NAME"
    exit 1
fi

if [[ ! -f "$CLIENT_PATH/public.key" ]]; then
    echo "Client public key not found."
    exit 1
fi

CLIENT_PUBLIC_KEY="$(cat "$CLIENT_PATH/public.key")"

echo "Removing client: $CLIENT_NAME"

# Remove peer from running WireGuard interface.
wg set "$WG_INTERFACE" peer "$CLIENT_PUBLIC_KEY" remove || true

# Remove the client's peer block from persistent configuration.
TMP_CONFIG="$(mktemp)"

awk -v name="$CLIENT_NAME" '
BEGIN {
    skip = 0
}

/^# Client:/ {
    if ($0 == "# Client: " name) {
        skip = 1
        next
    }

    if (skip) {
        skip = 0
    }
}

skip == 0 {
    print
}
' "$SERVER_CONFIG" > "$TMP_CONFIG"

mv "$TMP_CONFIG" "$SERVER_CONFIG"

chmod 600 "$SERVER_CONFIG"

# Delete client secrets/configuration.
rm -rf "$CLIENT_PATH"

echo
echo "Client removed."
echo
echo "Verify with:"
echo "  wg show"
