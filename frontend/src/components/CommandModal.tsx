import { useEffect, useState, useRef } from "react"
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog"
import { Button } from "@/components/ui/button"

type CommandModalProps = {
  open: boolean
  onOpenChange: (open: boolean) => void
  title: string
  endpoint: string
}

export default function CommandModal({ open, onOpenChange, title, endpoint }: CommandModalProps) {
  const [rawOutput, setRawOutput] = useState("")
  const [typedOutput, setTypedOutput] = useState("")
  const [copied, setCopied] = useState(false)
  const [isFullScreen, setIsFullScreen] = useState(() => {
    const stored = localStorage.getItem("commandModalFullscreen")
    return stored ? JSON.parse(stored) : false
  })

  const containerRef = useRef<HTMLPreElement>(null)

  // Typing animation
  useEffect(() => {
    if (!rawOutput) return
    let i = 0
    setTypedOutput("")
    const interval = setInterval(() => {
      setTypedOutput(prev => prev + rawOutput[i])
      i++
      if (i >= rawOutput.length) clearInterval(interval)
    }, 1)
    return () => clearInterval(interval)
  }, [rawOutput])

  const fetchCommand = () => {
    fetch(endpoint)
      .then(res => res.text())
      .then(setRawOutput)
      .catch(err => setRawOutput(`Error: ${err.message}`))
  }

  const handleCopy = () => {
    const selection = window.getSelection()
    const selectedText = selection?.toString()
    if (selectedText) {
      navigator.clipboard.writeText(selectedText)
      setCopied(true)
      setTimeout(() => setCopied(false), 1500)
    }
  }

  const handleDownload = () => {
    const now = new Date()
    const timestamp = now.toISOString().replace(/[:.]/g, "-")
    const fileName = `${title.replace(/\s+/g, "_")}_${timestamp}_output.txt`
    const blob = new Blob([rawOutput], { type: "text/plain" })
    const url = URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = fileName
    a.click()
    URL.revokeObjectURL(url)
  }

  useEffect(() => {
    if (open) fetchCommand()
  }, [open])

  useEffect(() => {
    const handleKey = (e: KeyboardEvent) => {
      if (e.key.toLowerCase() === "f") {
        setIsFullScreen(prev => {
          localStorage.setItem("commandModalFullscreen", JSON.stringify(!prev))
          return !prev
        })
      }
    }
    if (open) window.addEventListener("keydown", handleKey)
    return () => window.removeEventListener("keydown", handleKey)
  }, [open])

  useEffect(() => {
    localStorage.setItem("commandModalFullscreen", JSON.stringify(isFullScreen))
  }, [isFullScreen])

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className={`${isFullScreen ? "w-screen h-screen max-w-none" : "max-w-2xl"} transition-all resize`}>
        <DialogHeader>
          <DialogTitle>{title}</DialogTitle>
        </DialogHeader>

        <div className="flex flex-wrap justify-between mb-2 gap-2">
          <div className="flex gap-2 flex-wrap">
            <Button variant="outline" onClick={fetchCommand}>🔁 Refresh</Button>
            <Button variant="outline" onClick={handleCopy}>📋 {copied ? "Copied!" : "Copy Selection"}</Button>
            <Button variant="outline" onClick={handleDownload}>📄 Download</Button>
          </div>
          <Button variant="outline" onClick={() => setIsFullScreen(prev => !prev)}>
            {isFullScreen ? "🗕 Exit Fullscreen" : "🗖 Fullscreen"}
          </Button>
        </div>

        <pre
          ref={containerRef}
          className="bg-black text-green-400 p-4 overflow-auto h-[70vh] text-sm rounded font-mono resize-y"
        >
          {typedOutput}
        </pre>
      </DialogContent>
    </Dialog>
  )
}
