#!/bin/bash

echo "🧱 Setting up Pi-hole with Docker and DHCP..."

# Create Docker project directory
mkdir -p ~/pihole/etc-pihole ~/pihole/etc-dnsmasq.d
cd ~/pihole

# Create docker-compose.yml
tee docker-compose.yml > /dev/null <<EOF
version: "3"
services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    environment:
      TZ: 'Etc/New_York'
      WEBPASSWORD: 'C@stle'
      DHCP_ACTIVE: "true"
      DHCP_START: "10.5.20.6"
      DHCP_END: "10.5.20.250"
      DHCP_ROUTER: "10.5.20.1"
      DHCP_LEASETIME: "24"
      PIHOLE_DNS_: "127.0.0.1#5053"
    volumes:
      - './etc-pihole/:/etc/pihole/'
      - './etc-dnsmasq.d/:/etc/dnsmasq.d/'
    cap_add:
      - NET_ADMIN
    network_mode: "host"
    restart: unless-stopped

  cloudflared:
    image: cloudflare/cloudflared:latest
    container_name: cloudflared
    command: proxy-dns
    network_mode: "host"
    restart: unless-stopped
EOF

# Add VLAN25 DHCP config to Pi-hole
tee etc-dnsmasq.d/02-dhcp-vlan25.conf > /dev/null <<EOF
interface=vlan25
dhcp-range=10.5.25.6,10.5.25.250,24h
dhcp-option=3,10.5.25.1
EOF

# Pull and start containers
docker compose pull
docker compose up -d

echo "✅ Pi-hole and cloudflared are running"
echo "➡️ Access Pi-hole at: http://10.5.20.5/admin"
