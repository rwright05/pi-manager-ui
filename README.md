# 🧠 Pi Manager UI

A full-featured Raspberry Pi management dashboard with DNS control, network monitoring, scheduled maintenance, and modular configuration — all in one beautiful web UI.

---

## 📦 Features

- 🧰 Web-based management dashboard (React + Flask)
- 🔐 Secure networking via Tailscale (with exit node + route advertisement)
- 🌐 Multi-network setup with VLAN and static IPs
- 🛡️ DNS blocking via Pi-hole (Docker)
- 📶 DHCP for multiple networks (via Pi-hole or static fallback)
- 🧠 VXLAN over Tailscale with L2 broadcast domain
- 🔁 Bi-weekly reboots & monthly auto updates
- 📊 Speedtest logging + history graph
- 💻 System info via fastfetch / s-tui
- 📥 Exportable reports + downloadable ZIPs
- 🎨 Light/Dark mode toggle (with persistence)

---

## 🚀 Quick Start (Recommended)

> Run this on a fresh Raspberry Pi OS (Debian Bookworm or Bullseye)

```bash
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/YOUR_GITHUB/pi-manager-ui/main/scripts/install-pimanager.sh)"
