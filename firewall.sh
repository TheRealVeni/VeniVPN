#!/usr/bin/env bash

set -euo pipefail

CONFIG="/etc/homevps.conf"

if [[ -f "$CONFIG" ]]; then
    source "$CONFIG"
else
    SSH_PORT="22"
    ALLOW_HTTP="yes"
    ALLOW_HTTPS="yes"
fi

echo "Configuring firewall..."

ufw --force reset

ufw default deny incoming
ufw default allow outgoing

if [[ "${ALLOW_SSH:-yes}" == "yes" ]]; then
    ufw allow "${SSH_PORT:-22}/tcp"
fi

if [[ "${ALLOW_HTTP:-yes}" == "yes" ]]; then
    ufw allow 80/tcp
fi

if [[ "${ALLOW_HTTPS:-yes}" == "yes" ]]; then
    ufw allow 443/tcp
fi

ufw --force enable

echo "Firewall configured."
ufw status verbose
