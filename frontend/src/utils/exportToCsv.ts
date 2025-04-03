export function exportToCsv(data: any[], filename: string) {
    if (!data.length) return
  
    const headers = Object.keys(data[0])
    const csvContent = [
      headers.join(","), // header row
      ...data.map(row => headers.map(h => JSON.stringify(row[h] ?? "")).join(",")) // escape + rows
    ].join("\n")
  
    const blob = new Blob([csvContent], { type: "text/csv" })
    const url = URL.createObjectURL(blob)
    const a = document.createElement("a")
    a.href = url
    a.download = filename
    a.click()
    URL.revokeObjectURL(url)
  }
  