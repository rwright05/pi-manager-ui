#!/bin/bash

echo "📆 Setting up scheduled tasks and log rotation..."

# === 1. Add logrotate config for speedtest logs
sudo tee /etc/logrotate.d/net_report > /dev/null <<EOF
/var/log/net_report.log {
    monthly
    rotate 12
    compress
    missingok
    notifempty
    create 644 root adm
}
EOF

echo "🗃 Log rotation set for /var/log/net_report.log (monthly, keep 12 copies)"

# === 2. Install speedtest + ping script
sudo tee /usr/local/bin/network-report.sh > /dev/null <<'EOF'
#!/bin/bash
LOGFILE="/var/log/net_report.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
SPEED=$(speedtest-cli --simple 2>&1)
PING=$(ping -c 4 1.1.1.1 2>&1)

echo -e "\n========== $DATE ==========\n--- Speedtest Results ---\n$SPEED\n\n--- Ping Results ---\n$PING\n" >> "$LOGFILE"
EOF

chmod +x /usr/local/bin/network-report.sh
echo "📶 Speedtest logging script installed at /usr/local/bin/network-report.sh"

# === 3. Add to crontab
(crontab -l 2>/dev/null; echo "0 */6 * * * /usr/local/bin/network-report.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 0 1 * * /usr/local/bin/monthly-update.sh") | crontab -
(crontab -l 2>/dev/null; echo "0 2 * * 1 [ \$(date +\%U) -eq \$((\$(date +\%U)/2*2)) ] && /sbin/shutdown -r now") | crontab -

echo "✅ Cron jobs scheduled"
