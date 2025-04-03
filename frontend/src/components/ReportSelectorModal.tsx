import { useState } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"
import { Checkbox } from "@/components/ui/checkbox"
import { Label } from "@/components/ui/label"

const REPORT_OPTIONS = [
  { key: "fastfetch", label: "🧾 Fastfetch Info" },
  { key: "stui", label: "📊 s-tui Stats" },
  { key: "speedtest", label: "⚡ Speedtest" },
  { key: "log", label: "📝 System Update Log" },
]

type ReportSelectorModalProps = {
  open: boolean
  onOpenChange: (open: boolean) => void
}

export default function ReportSelectorModal({ open, onOpenChange }: ReportSelectorModalProps) {
  const [selected, setSelected] = useState<string[]>([])
  const [downloading, setDownloading] = useState(false)

  const toggle = (key: string) => {
    setSelected(prev =>
      prev.includes(key) ? prev.filter(k => k !== key) : [...prev, key]
    )
  }

  const handleDownload = async () => {
    setDownloading(true)
    const res = await fetch("/api/reports/zip", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ reports: selected }),
    })

    const blob = await res.blob()
    const url = window.URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = "PiReports.zip"
    a.click()
    window.URL.revokeObjectURL(url)
    setDownloading(false)
    onOpenChange(false)
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-lg">
        <DialogHeader>
          <DialogTitle>📦 Export Pi Reports</DialogTitle>
        </DialogHeader>

        <div className="space-y-3">
          {REPORT_OPTIONS.map(({ key, label }) => (
            <div key={key} className="flex items-center gap-2">
              <Checkbox
                checked={selected.includes(key)}
                onCheckedChange={() => toggle(key)}
                id={`checkbox-${key}`}
              />
              <Label htmlFor={`checkbox-${key}`} className="text-sm cursor-pointer">{label}</Label>
            </div>
          ))}
        </div>

        <div className="pt-4 flex justify-end">
          <Button
            disabled={selected.length === 0 || downloading}
            onClick={handleDownload}
          >
            {downloading ? "Bundling..." : "⬇️ Download ZIP"}
