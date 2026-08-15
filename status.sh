#!/usr/bin/env bash

echo "================================="
echo "          HomeVPS Status"
echo "================================="

echo
echo "Hostname:"
hostname

echo
echo "Kernel:"
uname -r

echo
echo "Uptime:"
uptime

echo
echo "IP addresses:"
ip -brief address

echo
echo "Listening ports:"
ss -tulpn

echo
echo "Firewall:"
ufw status verbose

echo
echo "Docker:"
if command -v docker >/dev/null 2>&1; then
    docker --version
    echo
    docker ps
else
    echo "Docker is not installed."
fi
