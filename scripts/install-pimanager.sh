#!/bin/bash

set -e

# Variables
INSTALL_DIR="/opt/pi-manager"
UI_REPO="https://github.com/rwright05/pi-manager-ui.git"
UI_DIR="$INSTALL_DIR/ui"
PAT="ghp_3sBPkREDAFqkwJSNyTMsNjWxThMJPc0mZnGp"  # Secure this in future
LOG_FILE="/var/log/pimanager-install.log"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting Pi Manager installation..."

# Ensure necessary tools are installed
log "Checking and installing dependencies..."
apt update
apt install -y curl git net-tools jq gnupg2 software-properties-common sudo netplan.io

# Install Docker if missing
if ! command -v docker &> /dev/null; then
    log "Docker not found, installing..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
else
    log "Docker already installed"
fi

# Install Docker Compose Plugin if missing
if ! docker compose version &>/dev/null; then
    log "Installing Docker Compose plugin..."
    apt install -y docker-compose-plugin
else
    log "Docker Compose plugin already installed"
fi

# Prepare install directory
log "Creating install directory at $INSTALL_DIR"
mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

# Pull Pi Manager UI
log "Cloning Pi Manager UI..."
rm -rf "$UI_DIR"
git clone https://$PAT@github.com/rwright05/pi-manager-ui.git "$UI_DIR"

# Build frontend
log "Installing frontend dependencies..."
cd "$UI_DIR"
apt install -y nodejs npm
npm install
npm run build || log "Frontend build failed. Please check package.json."

# Set up systemd service for frontend
log "Setting up dashboard systemd service..."
cat <<EOF > /etc/systemd/system/pi-manager-ui.service
[Unit]
Description=Pi Manager Dashboard UI
After=network.target

[Service]
Type=simple
WorkingDirectory=$UI_DIR
ExecStart=/usr/bin/npm run preview -- --port 3000 --host
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reexec
systemctl daemon-reload
systemctl enable pi-manager-ui
systemctl restart pi-manager-ui

# Pi-hole setup using Docker
log "Setting up Pi-hole..."
mkdir -p "$INSTALL_DIR/pihole"
cat <<EOF > "$INSTALL_DIR/pihole/docker-compose.yml"
version: "3"

services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    environment:
      TZ: "Etc/UTC"
      WEBPASSWORD: "admin"
    volumes:
      - "./etc-pihole:/etc/pihole"
      - "./etc-dnsmasq.d:/etc/dnsmasq.d"
    network_mode: "host"
    restart: unless-stopped
EOF

cd "$INSTALL_DIR/pihole"
docker compose up -d

# Fastfetch installation
log "Installing Fastfetch..."
apt install -y fastfetch || true

# Tailscale installation
log "Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh
systemctl enable --now tailscaled

# Netplan check
log "Verifying Netplan installation..."
if ! command -v netplan &>/dev/null; then
    log "Netplan not found. Installing..."
    apt install -y netplan.io
else
    log "Netplan already present"
fi

log "Pi Manager installation completed. Access dashboard via http://<your-pi-ip>:3000"
log "Please configure your Pi-hole settings and Tailscale as needed."