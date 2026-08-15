#!/usr/bin/env bash

set -euo pipefail

PROJECT_DIR="/opt/homevps"
CONFIG_FILE="/etc/homevps.conf"

if [[ $EUID -ne 0 ]]; then
    echo "Please run this script as root."
    exit 1
fi

echo "================================="
echo "        HomeVPS Installer"
echo "================================="

echo "[1/6] Updating system..."
apt-get update
apt-get upgrade -y

echo "[2/6] Installing base packages..."
apt-get install -y \
    curl \
    git \
    ufw \
    openssh-server \
    ca-certificates \
    gnupg \
    lsb-release

echo "[3/6] Creating HomeVPS directories..."
mkdir -p "$PROJECT_DIR"
mkdir -p /etc/homevps

cp -r scripts "$PROJECT_DIR/"
cp -r config "$PROJECT_DIR/"

if [[ ! -f "$CONFIG_FILE" ]]; then
    cp config/homevps.conf "$CONFIG_FILE"
fi

echo "[4/6] Configuring SSH..."
bash "$PROJECT_DIR/scripts/harden-ssh.sh"

echo "[5/6] Configuring firewall..."
bash "$PROJECT_DIR/scripts/firewall.sh"

echo "[6/6] Installing Docker..."
bash "$PROJECT_DIR/scripts/install-docker.sh"

chmod +x "$PROJECT_DIR/scripts/"*.sh

echo
echo "================================="
echo " HomeVPS installation complete!"
echo "================================="
echo
echo "Run:"
echo "  $PROJECT_DIR/scripts/status.sh"
echo
