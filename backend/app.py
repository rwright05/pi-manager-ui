from flask import Flask, send_file, request, jsonify
import subprocess
import os
import re
import zipfile
import tempfile
import psutil
import platform
from datetime import datetime
import shutil

app = Flask(__name__)

@app.route("/api/log")
def get_log():
    return send_file("/var/log/net_report.log")

@app.route("/api/update")
def run_update():
    subprocess.Popen(["/usr/local/bin/monthly-update.sh"])
    return "Update started", 202

@app.route("/api/reboot")
def reboot():
    subprocess.Popen(["shutdown", "-r", "now"])
    return "Rebooting...", 202

@app.route("/api/status")
def pihole_status():
    try:
        result = subprocess.check_output(["docker", "exec", "pihole", "pihole", "-c"])
        return result.decode()
    except subprocess.CalledProcessError as e:
        return f"Error: {e.output.decode()}", 500

@app.route("/api/speedtest")
def speedtest():
    try:
        result = subprocess.check_output(["speedtest-cli", "--simple"])
        return result.decode()
    except subprocess.CalledProcessError as e:
        return f"Speedtest error: {e.output.decode()}", 500

@app.route("/api/system")
def system_info():
    try:
        return {
            "os": platform.platform(),
            "uptime": subprocess.check_output("uptime -p", shell=True).decode().strip(),
            "cpu": psutil.cpu_percent(interval=1),
            "ram": psutil.virtual_memory().percent,
            "power": subprocess.getoutput("vcgencmd measure_volts") if shutil.which("vcgencmd") else "N/A"
        }
    except Exception as e:
        return {"error": str(e)}, 500

@app.route("/api/fastfetch")
def run_fastfetch():
    try:
        return subprocess.check_output("fastfetch", shell=True).decode()
    except subprocess.CalledProcessError as e:
        return f"Error: {e.output.decode()}", 500

@app.route("/api/stui")
def run_stui():
    try:
        return subprocess.check_output("s-tui --no-interactive", shell=True).decode()
    except subprocess.CalledProcessError as e:
        return f"Error: {e.output.decode()}", 500

@app.route("/api/stats")
def pihole_stats():
    import requests, time
    res = requests.get("http://localhost/admin/api.php?overTimeData10mins=true").json()
    clients = requests.get("http://localhost/admin/api.php?getQuerySources").json()

    query_data = res.get("over_time", {})
    blocked_data = res.get("ads_over_time", {})
    queries = [{"time": time.strftime('%H:%M', time.localtime(int(ts))), "queries": count}
               for ts, count in query_data.items()]
    blocked = [{"time": time.strftime('%H:%M', time.localtime(int(ts))), "blocked": count}
               for ts, count in blocked_data.items()]
    devices = [{"device": k, "queries": v} for k, v in clients.items()]

    return {
        "queries": queries,
        "blocked": blocked,
        "devices": devices
    }

@app.route("/api/speedlog")
def speedlog():
    log_path = "/var/log/net_report.log"
    entries = []

    try:
        with open(log_path, "r") as f:
            log = f.read()

        blocks = log.split("==========")
        for block in blocks:
            if "Download:" in block and "Upload:" in block:
                lines = block.strip().splitlines()
                date_line = lines[0].strip()
                download = upload = 0.0

                for line in lines:
                    if "Download:" in line:
                        download = float(re.findall(r"[\d.]+", line)[0])
                    if "Upload:" in line:
                        upload = float(re.findall(r"[\d.]+", line)[0])

                entries.append({
                    "time": date_line,
                    "download": download,
                    "upload": upload
                })

        return jsonify(entries[-100:])
    except Exception as e:
        return {"error": str(e)}, 500

@app.route("/api/reports/zip", methods=["POST"])
def bundle_reports():
    commands = {
        "fastfetch": "fastfetch",
        "stui": "s-tui --no-interactive",
        "speedtest": "speedtest-cli --simple",
        "log": "cat /var/log/net_report.log",
    }

    selected = request.json.get("reports", [])
    timestamp = datetime.now().strftime("%Y-%m-%dT%H-%M-%S")
    tmp = tempfile.NamedTemporaryFile(delete=False, suffix=".zip")

    with zipfile.ZipFile(tmp.name, "w") as zipf:
        for key in selected:
            if key not in commands: continue
            try:
                output = subprocess.check_output(commands[key], shell=True, stderr=subprocess.STDOUT).decode()
                zipf.writestr(f"{key}_{timestamp}.txt", output)
            except subprocess.CalledProcessError as e:
                zipf.writestr(f"{key}_{timestamp}_ERROR.txt", e.output.decode())

    return send_file(tmp.name, as_attachment=True, download_name=f"PiReports_{timestamp}.zip")

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
