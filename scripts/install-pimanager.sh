#!/bin/bash

# Pi Manager Installer v1.0.1
# Improved with retries, validation, skip-if-installed checks, and better logging

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script as root: sudo ./install-pimanager.sh"
  exit 1
fi

VERSION="1.0.1"
BUILD_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
FULL_VERSION="v$VERSION - $BUILD_TIME"
LOGFILE="/var/log/pimanager-install-$BUILD_TIME.log"
VERSION_FILE="/etc/pimanager-version"
PROJECT_DIR="/root/pi-manager-ui"

mkdir -p /var/log
echo "$FULL_VERSION" | tee $VERSION_FILE > /dev/null
exec > >(tee -a "$LOGFILE") 2>&1

echo "📦 Pi Manager Installer $FULL_VERSION — Starting..."

command -v curl >/dev/null || { echo "❌ curl is required."; exit 1; }
command -v sudo >/dev/null || { echo "❌ sudo is required."; exit 1; }
command -v git >/dev/null || apt install -y git

echo "🔄 Updating system packages..."
apt update -y && apt upgrade -y

# Ensure required tools are installed
echo "🧰 Installing fastfetch, s-tui, speedtest-cli..."
apt install -y s-tui speedtest-cli || true
apt install -y fastfetch 2>/dev/null || echo "⚠️ fastfetch not available in this repo."

# Docker check/install
if ! command -v docker &>/dev/null; then
  echo "🐳 Installing Docker..."
  curl -fsSL https://get.docker.com | sh
fi

if ! command -v docker-compose &>/dev/null; then
  echo "🔧 Installing Docker Compose..."
  apt install -y docker-compose
fi

# Tailscale setup (retry if not connected)
echo "🛡 Verifying Tailscale setup..."
if ! tailscale status &>/dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh
  until tailscale status &>/dev/null; do
    echo "🔁 Trying Tailscale login..."
    tailscale up \
      --authkey tskey-client-kyr3cS7t3621CNTRL-PrW4FoEnRM5geQELyNLkQ5dkw4UMq8Tn \
      --advertise-tags=router \
      --advertise-exit-node \
      --advertise-routes=10.5.20.0/24,10.5.25.0/24 \
      --ssh || sleep 5
  done
  echo "✅ Tailscale connected."
else
  echo "✅ Tailscale is already running."
fi

# Clone repo if missing
if [ ! -d "$PROJECT_DIR" ]; then
  echo "📥 Cloning Pi Manager UI..."
  git clone https://github.com/rwright05/pi-manager-ui.git "$PROJECT_DIR" || {
    echo "❌ Failed to clone project. Check credentials or SSH keys."; exit 1;
  }
fi

# Docker setup
cd "$PROJECT_DIR" || { echo "❌ Project folder not found."; exit 1; }
if [ ! -f docker-compose.yml ]; then
  echo "❌ docker-compose.yml missing. Exiting."
  exit 1
fi

echo "🐳 Starting Docker containers..."
docker compose up -d --build || echo "⚠️ Docker may already be running."

# Run modular setup scripts if not done
cd "$PROJECT_DIR/scripts" || { echo "❌ Missing scripts directory."; exit 1; }
chmod +x setup-*.sh

for script in setup-network.sh setup-pihole.sh setup-dashboard.sh setup-vxlan.sh setup-tasks.sh; do
  echo "🔧 Running $script..."
  ./"$script" || { echo "⚠️ $script failed. Retrying..."; ./"$script"; }
done

# Cockpit setup
if ! systemctl is-enabled cockpit.service &>/dev/null; then
  echo "🖥 Installing Cockpit..."
  apt install -y cockpit cockpit-docker || echo "⚠️ cockpit-docker not available"
  systemctl enable --now cockpit || echo "⚠️ Failed to enable cockpit"
fi

# Done
IP=$(hostname -I | awk '{print $1}')
echo -e "\n✅ Pi Manager setup complete."
echo "🧾 Version: $FULL_VERSION"
echo "📜 Version file: $VERSION_FILE"
echo "📄 Install log: $LOGFILE"
echo "➡️  Dashboard: http://$IP:8080"
echo "➡️  Cockpit: https://$IP:9090"
echo "🔁 Please reboot or log out to ensure all changes take effect."

read -p "Reboot now to complete setup? [y/N]: " confirm && [[ "$confirm" =~ ^[Yy]$ ]] && reboot
echo "❌ Reboot skipped. Please reboot manually to apply changes."