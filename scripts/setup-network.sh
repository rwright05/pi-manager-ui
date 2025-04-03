#!/bin/bash

echo "🌐 Configuring static IP and VLAN..."

# Write netplan config
sudo tee /etc/netplan/01-pimanager-network.yaml > /dev/null <<EOF
network:
  version: 2
  ethernets:
    eth0:
      dhcp4: no
      addresses: [10.5.20.5/24]
      gateway4: 10.5.20.1
      nameservers:
        addresses: [10.5.20.5]

  vlans:
    vlan25:
      id: 25
      link: eth0
      dhcp4: no
      addresses: [10.5.25.5/24]
      gateway4: 10.5.25.1
      nameservers:
        addresses: [10.5.20.5]
EOF

# Apply the config
echo "✅ Applying netplan..."
sudo netplan apply

echo "✅ Network configured:"
ip a show eth0
ip a show vlan25
echo "✅ Network configured:"