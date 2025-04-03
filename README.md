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
sudo bash -c "$(curl -fsSL https://raw.githubusercontent.com/rwright05/pi-manager-ui/main/scripts/install-pimanager.sh)"
```

---

## 🛠 Manual Installation

1. Clone the repo:

```bash
git clone https://github.com/rwright05/pi-manager-ui.git
cd pi-manager-ui
```

2. Make the install script executable:

```bash
chmod +x scripts/install-pimanager.sh
sudo ./scripts/install-pimanager.sh
```

---

## 📍 Web Interface

| Tool        | URL                                |
|-------------|-------------------------------------|
| 🧠 Pi Manager Dashboard | `http://<your-pi-ip>:8080`          |
| 🧪 Cockpit Web Admin    | `https://<your-pi-ip>:9090` *(optional)* |

> You can also access the Pi via Tailscale on its `100.x.x.x` IP

---

## 🧩 Modular Scripts

Located in the `scripts/` folder:

| Script              | Description                                      |
|---------------------|--------------------------------------------------|
| `setup-network.sh`  | Configures static IP, VLAN, and routes           |
| `setup-pihole.sh`   | Installs Pi-hole via Docker and configures DoH   |
| `setup-vxlan.sh`    | Sets up VXLAN tunnel via Tailscale + Netplan     |
| `setup-dashboard.sh`| Builds and runs the Pi Manager UI in Docker      |
| `setup-tasks.sh`    | Sets up cron tasks, log rotation, speedtest      |
| `install-pimanager.sh` | Full automated installer with version logging  |

---

## ⚙️ Requirements

- Raspberry Pi OS / Debian Bookworm (ARM64 or ARMv7)
- Docker + Docker Compose
- Internet access (for setup)
- Tailscale Auth Key (`tskey-*`)
- System tools: `fastfetch`, `s-tui`, `speedtest-cli`

---

## 📂 Project Structure

```txt
pi-manager-ui/
├── backend/                  # Flask API
├── frontend/                 # React UI
├── scripts/                  # Setup scripts
├── docker-compose.yml        # App stack
├── Dockerfile                # Full build
├── nginx.conf                # Serves frontend & proxies backend
├── README.md
```

---

## 🧪 Troubleshooting

- ❌ **Permission denied logging**  
  Make sure you're running `install-pimanager.sh` as **root**.

- 🐢 **Slow or missing Pi-hole stats**  
  Ensure Pi-hole container is named `pihole` and uses the API at `/admin/api.php`.

- 🔒 **Tailscale not authenticating**  
  Make sure your auth key is active, and if ACLs are used, pass the correct tag:  
  `--advertise-tags=router`

---

## 🧾 Versioning

Installed version is saved at:  
```bash
/etc/pimanager-version
```

Installation logs are saved to:  
```bash
/var/log/pimanager-install-YYYY-MM-DD_HH-MM-SS.log
```

---

## 🧬 Coming Soon

- `.deb` installer for air-gapped setups  
- Mobile-friendly UI mode  
- Pi-hole query drilldown by device  
- Auto-updater and online sync with GitHub  
- Email alerts for health, downtime, etc.

---

## 💡 Credits

Built with:
- 🧠 [React](https://reactjs.org)
- 🧪 [Flask](https://flask.palletsprojects.com/)
- 🛡️ [Tailscale](https://tailscale.com/)
- 🧰 [Pi-hole](https://pi-hole.net/)
- 📊 [Recharts](https://recharts.org/)
- 🛠️ [Cockpit](https://cockpit-project.org/)

---

## 📬 Feedback & Contributions

PRs and feedback welcome.  
Open issues, ideas, or new modules are appreciated!

> Maintained by [@rwright05](https://github.com/rwright05)
