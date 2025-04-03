#!/bin/bash

# Pi Manager Installer v1.0.0
# Auto-patched with root check, logging fix, and Tailscale tag support

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script as root: sudo ./install-pimanager.sh"
  exit 1
fi

VERSION="1.0.0"
BUILD_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
FULL_VERSION="v$VERSION - $BUILD_TIME"

LOGFILE="/var/log/pimanager-install-$BUILD_TIME.log"
VERSION_FILE="/etc/pimanager-version"

mkdir -p /var/log
echo "$FULL_VERSION" | tee $VERSION_FILE > /dev/null
exec > >(tee -a "$LOGFILE") 2>&1

echo "📦 Pi Manager Installer $FULL_VERSION — Verifying environment..."

command -v git >/dev/null || { echo "❌ Git is not installed. Please install git."; exit 1; }
command -v curl >/dev/null || { echo "❌ curl is not installed. Please install curl."; exit 1; }
command -v sudo >/dev/null || { echo "❌ sudo is required to run this script."; exit 1; }

# === 1. Update System ===
echo "🔄 Updating system packages..."
apt update && apt upgrade -y

# === 2. Install Docker & Docker Compose ===
if ! command -v docker &> /dev/null; then
  echo "🐳 Installing Docker..."
  curl -fsSL https://get.docker.com | sh
  usermod -aG docker $USER
fi

if ! command -v docker-compose &> /dev/null; then
  echo "🔧 Installing Docker Compose..."
  apt install -y docker-compose
fi

# === 3. Install Tailscale ===
echo "🛡 Installing Tailscale..."
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --authkey tskey-client-kyr3cS7t3621CNTRL-PrW4FoEnRM5geQELyNLkQ5dkw4UMq8Tn \
  --advertise-tags=router \
  --advertise-exit-node \
  --advertise-routes=10.5.20.0/24,10.5.25.0/24 \
  --ssh

# === 4. Install System Tools ===
echo "🧰 Installing fastfetch, s-tui, speedtest-cli..."
apt install -y fastfetch s-tui speedtest-cli python3-pip

# === 5. Setup Pi Manager Docker Project ===
echo "📂 Setting up Pi Manager UI project..."
cd ~/pi-manager-ui

echo "🚀 Building and starting Pi Manager UI..."
docker compose up -d --build

# === 6. Run modular setup scripts ===
echo "🔧 Running modular setup scripts..."
cd scripts
chmod +x setup-*.sh
./setup-network.sh
./setup-pihole.sh
./setup-dashboard.sh
./setup-vxlan.sh
./setup-tasks.sh

# === 7. Enable Cockpit (optional) ===
echo "🖥 Installing Cockpit for full web GUI access..."
apt install -y cockpit cockpit-docker
systemctl enable --now cockpit

# === 8. Final Summary ===
echo -e "\n✅ Pi Manager setup complete."
echo "🧾 Version: $FULL_VERSION"
echo "📜 Version file: $VERSION_FILE"
echo "📄 Install log: $LOGFILE"
echo "➡️  Dashboard: http://$(hostname -I | awk '{print $1}'):8080"
echo "➡️  Cockpit: https://$(hostname -I | awk '{print $1}'):9090"
echo "🔁 Please reboot or log out to ensure all changes take effect."

read -p "Reboot now to complete setup? [y/N]: " confirm && [[ "$confirm" =~ ^[Yy]$ ]] && reboot
echo "🔄 Reboot cancelled. Please reboot manually to complete setup."