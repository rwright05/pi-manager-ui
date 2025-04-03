import { useEffect, useState } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Textarea } from "@/components/ui/textarea"
import { Switch } from "@/components/ui/switch"
import { LineChart, Line, XAxis, YAxis, Tooltip, ResponsiveContainer } from "recharts"
import CommandModal from "@/components/CommandModal"
import ReportSelectorModal from "@/components/ReportSelectorModal"
import { exportToCsv } from "@/utils/exportToCsv"

export default function PiManager() {
  const [log, setLog] = useState("")
  const [status, setStatus] = useState("")
  const [speed, setSpeed] = useState("")
  const [stats, setStats] = useState([])
  const [blockedStats, setBlockedStats] = useState([])
  const [deviceStats, setDeviceStats] = useState([])
  const [speedlog, setSpeedlog] = useState([])
  const [darkMode, setDarkMode] = useState(() => {
    const saved = localStorage.getItem("darkMode")
    return saved ? JSON.parse(saved) : true
  })
  const [loading, setLoading] = useState(false)

  const [showFastfetch, setShowFastfetch] = useState(false)
  const [showStui, setShowStui] = useState(false)
  const [showReportModal, setShowReportModal] = useState(false)

  const fetchLog = async () => {
    const res = await fetch("/api/log")
    const data = await res.text()
    setLog(data)
  }

  const fetchStatus = async () => {
    const res = await fetch("/api/status")
    const data = await res.text()
    setStatus(data)
  }

  const fetchStats = async () => {
    const res = await fetch("/api/stats")
    const data = await res.json()
    setStats(data.queries)
    setBlockedStats(data.blocked)
    setDeviceStats(data.devices)
  }

  const fetchSpeed = async () => {
    setLoading(true)
    const res = await fetch("/api/speedtest")
    const data = await res.text()
    setSpeed(data)
    setLoading(false)
  }

  const fetchSpeedLog = async () => {
    const res = await fetch("/api/speedlog")
    const data = await res.json()
    setSpeedlog(data)
  }

  const runCommand = async (command: string) => {
    setLoading(true)
    await fetch(`/api/${command}`)
    await fetchLog()
    await fetchStatus()
    setLoading(false)
  }

  useEffect(() => {
    fetchLog()
    fetchStatus()
    fetchSpeed()
    fetchStats()
    fetchSpeedLog()

    const interval = setInterval(() => {
      fetchStats()
    }, 2000)

    return () => clearInterval(interval)
  }, [])

  useEffect(() => {
    document.documentElement.classList.toggle("dark", darkMode)
    localStorage.setItem("darkMode", JSON.stringify(darkMode))
  }, [darkMode])

  return (
    <div className="p-6 space-y-4 min-h-screen bg-background text-foreground transition-colors">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-bold">🧠 Pi Manager Dashboard</h1>
        <div className="flex items-center space-x-2">
          <span className="text-sm">☀️</span>
          <Switch checked={darkMode} onCheckedChange={setDarkMode} />
          <span className="text-sm">🌙</span>
        </div>
      </div>

      <Card>
        <CardContent className="space-y-4 p-4">
          <div className="space-x-2 space-y-2 flex flex-wrap">
            <Button onClick={() => runCommand("update")}>🔄 Run Update</Button>
            <Button onClick={() => runCommand("reboot")}>🔁 Reboot System</Button>
            <Button onClick={fetchLog}>📄 Refresh Log</Button>
            <Button onClick={fetchSpeed}>⚡ Speed Test</Button>
            <Button onClick={() => setShowFastfetch(true)}>🧾 Fastfetch Info</Button>
            <Button onClick={() => setShowStui(true)}>📊 s-tui Stats</Button>
            <Button onClick={() => setShowReportModal(true)}>📦 Export Reports</Button>
          </div>
          <Textarea value={log} readOnly className="h-60 text-xs font-mono" />
        </CardContent>
      </Card>

      <Card>
        <CardContent className="space-y-2 p-4">
          <h2 className="text-xl font-semibold">📊 Pi-hole Status</h2>
          <Textarea value={status} readOnly className="h-32 text-xs font-mono" />
        </CardContent>
      </Card>

      <Card>
        <CardContent className="space-y-4 p-4">
          <div className="flex justify-between items-center">
            <h2 className="text-xl font-semibold">📈 Pi-hole Query Graph</h2>
            <Button variant="outline" onClick={() => exportToCsv(stats, "queries.csv")}>📄 Export CSV</Button>
          </div>
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={stats}>
              <XAxis dataKey="time" />
              <YAxis allowDecimals={false} />
              <Tooltip />
              <Line type="monotone" dataKey="queries" stroke="#8884d8" dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      <Card>
        <CardContent className="space-y-4 p-4">
          <h2 className="text-xl font-semibold">🚫 Blocked Domains Over Time</h2>
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={blockedStats}>
              <XAxis dataKey="time" />
              <YAxis allowDecimals={false} />
              <Tooltip />
              <Line type="monotone" dataKey="blocked" stroke="#f87171" dot={false} />
            </LineChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      <Card>
        <CardContent className="space-y-4 p-4">
          <h2 className="text-xl font-semibold">🖥️ Device Total Queries Today</h2>
          <ul className="text-sm font-mono space-y-1">
            {deviceStats.map((item, idx) => (
              <li key={idx}>{item.device}: {item.queries} queries</li>
            ))}
          </ul>
        </CardContent>
      </Card>

      <Card>
        <CardContent className="space-y-4 p-4">
          <div className="flex justify-between items-center">
            <h2 className="text-xl font-semibold">📊 Speedtest History (Download / Upload)</h2>
            <Button variant="outline" onClick={() => exportToCsv(speedlog, "speedtest_history.csv")}>
              📄 Export CSV
            </Button>
          </div>
          <ResponsiveContainer width="100%" height={200}>
            <LineChart data={speedlog}>
              <XAxis dataKey="time" tick={{ fontSize: 10 }} />
              <YAxis />
              <Tooltip />
              <Line type="monotone" dataKey="download" stroke="#34d399" dot={false} name="Download (Mbit/s)" />
              <Line type="monotone" dataKey="upload" stroke="#60a5fa" dot={false} name="Upload (Mbit/s)" />
            </LineChart>
          </ResponsiveContainer>
        </CardContent>
      </Card>

      <Card>
        <CardContent className="space-y-2 p-4">
          <h2 className="text-xl font-semibold">⚡ Speed Test Result</h2>
          <Textarea value={speed} readOnly className="h-32 text-xs font-mono" />
        </CardContent>
      </Card>

      <CommandModal open={showFastfetch} onOpenChange={setShowFastfetch} title="🧾 Fastfetch Info" endpoint="/api/fastfetch" />
      <CommandModal open={showStui} onOpenChange={setShowStui} title="📊 s-tui Stats" endpoint="/api/stui" />
      <ReportSelectorModal open={showReportModal} onOpenChange={setShowReportModal} />
    </div>
  )
}
