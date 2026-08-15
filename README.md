a Linux-based script that turns a spare machine into a small VPS host, with SSH hardening, firewall, Docker, and basic management commands.

you probably need debian or ubuntu for this to run.

if you want your vpn to run permanently, you need to set up the VPS first:

you will need:

computer that stays powered on (if you rent a server this is all moot)
Linux distribution (debian/ubuntu)
stable way to reach it from the internet (public IP, port forwarding, or tunnel)
ssh for administration
firewall such as ufw or nftables
docker to host multiple services
