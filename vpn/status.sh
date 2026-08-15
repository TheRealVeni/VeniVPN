#!/usr/bin/env bash

set -euo pipefail

WG_INTERFACE="wg0"
VPN_DIR="/etc/homevps/wireguard"
CLIENT_DIR="$VPN_DIR/clients"

echo "======================================"
echo "       HomeVPS VPN Status"
echo "======================================"
echo

if ! command -v wg >/dev/null 2>&1; then
    echo "WireGuard is not installed."
    exit 1
fi

echo "Interface:"
echo

if ! wg show "$WG_INTERFACE"; then
    echo
    echo "WireGuard interface is not running."
    exit 1
fi

echo
echo "--------------------------------------"
echo "Configured clients"
echo "--------------------------------------"

if [[ ! -d "$CLIENT_DIR" ]]; then
    echo "No clients directory."
    exit 0
fi

FOUND=0

for CLIENT in "$CLIENT_DIR"/*; do
    [[ -d "$CLIENT" ]] || continue

    FOUND=1

    NAME="$(basename "$CLIENT")"

    if [[ -f "$CLIENT/public.key" ]]; then
        PUBLIC_KEY="$(cat "$CLIENT/public.key")"
    else
        PUBLIC_KEY="unknown"
    fi

    echo
    echo "Client: $NAME"
    echo "Public key: $PUBLIC_KEY"
done

if [[ "$FOUND" -eq 0 ]]; then
    echo "No clients configured."
fi

echo
echo "--------------------------------------"
echo "Listening UDP ports"
echo "--------------------------------------"

ss -lunp | grep -E '51820|wireguard' || true
