#!/bin/bash

echo "🧠 Setting up persistent VXLAN tunnel using Netplan..."

# Create a Netplan override for VXLAN
sudo tee /etc/netplan/50-vxlan.yaml > /dev/null <<EOF
network:
  version: 2
  tunnels:
    vxlan0:
      mode: vxlan
      id: 42
      local: 100.99.104.39
      remote: 100.99.104.33
      port: 4789
      addresses: [192.168.200.1/24]
      mtu: 1400
      parameters:
        key: 42
      interface-name: vxlan0
EOF

# Apply the configuration
echo "⚙️ Applying Netplan configuration..."
sudo netplan apply

#!/bin/bash
# Setup VXLAN over Tailscale
echo "⚙️ Writing vxlan-check.sh health script..."
sudo tee /usr/local/bin/vxlan-check.sh > /dev/null <<'EOCHECK'
#!/bin/bash
echo "⏳ Waiting for VXLAN interface to come up..."
for i in {1..30}; do
    if ip link show vxlan0 | grep -q "state UP"; then
        echo "✅ VXLAN interface is up"
        exit 0
    fi
    sleep 1
done
echo "❌ VXLAN interface did not come up in time"
exit 1
EOCHECK

sudo chmod +x /usr/local/bin/vxlan-check.sh

echo "⚙️ Writing systemd unit: vxlan-check.service..."
sudo tee /etc/systemd/system/vxlan-check.service > /dev/null <<'EOSVC'
[Unit]
Description=VXLAN Interface Readiness Check
After=network-online.target tailscaled.service
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/vxlan-check.sh
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOSVC

echo "✅ Enabling systemd unit..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable vxlan-check.service
sudo systemctl start vxlan-check.service
