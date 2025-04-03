#!/bin/bash

# Pi Manager Installer v1.0.2
# Rewritten for clean logic, retries, and compatibility

if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run this script as root: sudo ./install-pimanager.sh"
  exit 1
fi

VERSION="1.0.2"
BUILD_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
FULL_VERSION="v$VERSION - $BUILD_TIME"
LOGFILE="/var/log/pimanager-install-$BUILD_TIME.log"
VERSION_FILE="/etc/pimanager-version"
PROJECT_DIR="/root/pi-manager-ui"

mkdir -p /var/log
echo "$FULL_VERSION" | tee $VERSION_FILE > /dev/null
exec > >(tee -a "$LOGFILE") 2>&1

echo "📦 Pi Manager Installer $FULL_VERSION — Starting..."

# === Environment Check ===
command -v curl >/dev/null || { echo "❌ curl is required."; exit 1; }
command -v sudo >/dev/null || { echo "❌ sudo is required."; exit 1; }
command -v git >/dev/null || apt install -y git

# === System Update ===
echo "🔄 Updating system packages..."
apt update -y && apt upgrade -y

# === Tools Install ===
echo "🧰 Installing system tools..."
apt install -y s-tui speedtest-cli python3-pip || true

# Attempt to install fastfetch from GitHub if not in apt
if ! command -v fastfetch &> /dev/null; then
  echo "⚠️ fastfetch not found in apt, installing from GitHub..."
  apt install -y cmake build-essential git libpci-dev libdrm-dev libgl1-mesa-dev
  git clone --depth=1 https://github.com/fastfetch-cli/fastfetch.git /tmp/fastfetch
  cd /tmp/fastfetch && cmake -B build -DCMAKE_BUILD_TYPE=Release && cmake --build build -j$(nproc)
  cp build/fastfetch /usr/local/bin/
  cd ~
fi

# === Docker Setup ===
if ! command -v docker &> /dev/null; then
  echo "🐳 Installing Docker..."
  curl -fsSL https://get.docker.com | sh
fi
if ! command -v docker-compose &> /dev/null; then
  echo "🔧 Installing Docker Compose..."
  apt install -y docker-compose
fi

# === Tailscale Interactive Setup ===
echo "🛡 Verifying Tailscale setup..."
if ! tailscale status &> /dev/null; then
  curl -fsSL https://tailscale.com/install.sh | sh

  read -rp "Enter your Tailscale auth key (tskey-...): " TSKEY
  read -rp "Enter any advertise flags (e.g., --advertise-exit-node --advertise-routes=10.5.20.0/24,10.5.25.0/24): " TSFLAGS
  read -rp "Enter advertise tag (just the value after tag:), or leave blank: " TSTAG

  while ! tailscale status &> /dev/null; do
    echo "🔁 Attempting Tailscale connection..."
    CMD="tailscale up --authkey $TSKEY --ssh"
    [ -n "$TSFLAGS" ] && CMD="$CMD $TSFLAGS"
    [ -n "$TSTAG" ] && CMD="$CMD --advertise-tags=tag:$TSTAG"
    echo "Running: $CMD"
    eval $CMD || sleep 5
  done
  echo "✅ Tailscale connected."
else
  echo "✅ Tailscale is already running."
fi

# === Clone Project ===
if [ ! -d "$PROJECT_DIR" ]; then
  echo "📥 Cloning Pi Manager UI..."
  git clone https://github.com/rwright05/pi-manager-ui.git "$PROJECT_DIR" || {
    echo "❌ Git clone failed. Check authentication."; exit 1;
  }
fi

# === Launch Dashboard ===
cd "$PROJECT_DIR" || { echo "❌ Project folder not found."; exit 1; }
if [ -f docker-compose.yml ]; then
  echo "🚀 Building and starting Docker containers..."
  docker compose up -d --build || echo "⚠️ Docker may already be running."
else
  echo "❌ Missing docker-compose.yml. Cannot proceed."
  exit 1
fi

# === Run Modular Scripts ===
cd "$PROJECT_DIR/scripts" || { echo "❌ Missing scripts folder."; exit 1; }
chmod +x setup-*.sh
for script in setup-network.sh setup-pihole.sh setup-dashboard.sh setup-vxlan.sh setup-tasks.sh; do
  echo "🔧 Running $script..."
  ./"$script" || { echo "⚠️ $script failed. Retrying..."; sleep 2; ./"$script"; }
done

# === Cockpit Install ===
if ! systemctl is-enabled cockpit.service &>/dev/null; then
  echo "🖥 Installing Cockpit..."
  apt install -y cockpit || echo "⚠️ cockpit not available"
  systemctl enable --now cockpit || echo "⚠️ Failed to enable cockpit"
fi

# === Summary ===
IP=$(hostname -I | awk '{print $1}')
echo -e "\n✅ Pi Manager setup complete."
echo "🧾 Version: $FULL_VERSION"
echo "📜 Version file: $VERSION_FILE"
echo "📄 Install log: $LOGFILE"
echo "➡️  Dashboard: http://$IP:8080"
echo "➡️  Cockpit: https://$IP:9090"
echo "🔁 Please reboot or log out to ensure all changes take effect."
read -p "Reboot now to complete setup? [y/N]: " confirm && [[ "$confirm" =~ ^[Yy]$ ]] && reboot
echo "🔄 Reboot canceled. Please reboot manually to apply changes."