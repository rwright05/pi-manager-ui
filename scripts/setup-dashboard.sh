#!/bin/bash

echo "🧠 Installing dashboard tools and Pi Manager..."

# === 1. Install CLI tools
echo "🔧 Installing fastfetch, s-tui, speedtest-cli..."
sudo apt install -y fastfetch s-tui speedtest-cli python3-pip

# === 2. Clone or copy the Pi Manager UI repo
cd ~
if [ ! -d "pi-manager-ui" ]; then
  echo "📥 Cloning Pi Manager UI..."
  git clone https://github.com/youruser/pi-manager-ui.git  # 🔁 Replace with your repo
else
  echo "📂 Found existing pi-manager-ui folder"
fi

cd ~/pi-manager-ui

# === 3. Start the Docker stack
echo "🐳 Building dashboard container..."
docker compose up -d --build

echo "✅ Dashboard is running!"
echo "➡️ Visit http://10.5.20.5:8080"
