#!/usr/bin/env bash

set -euo pipefail

SSHD_CONFIG="/etc/ssh/sshd_config"

echo "Hardening SSH..."

cp "$SSHD_CONFIG" "${SSHD_CONFIG}.backup"

# Disable direct root login.
sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' "$SSHD_CONFIG"

# Disable password authentication.
# Make sure SSH keys are configured BEFORE enabling this.
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' "$SSHD_CONFIG"

# Disable empty passwords.
sed -i 's/^#\?PermitEmptyPasswords.*/PermitEmptyPasswords no/' "$SSHD_CONFIG"

# Ensure public-key authentication is enabled.
if grep -q "^PubkeyAuthentication" "$SSHD_CONFIG"; then
    sed -i 's/^PubkeyAuthentication.*/PubkeyAuthentication yes/' "$SSHD_CONFIG"
else
    echo "PubkeyAuthentication yes" >> "$SSHD_CONFIG"
fi

sshd -t

systemctl restart ssh

echo "SSH hardening complete."
