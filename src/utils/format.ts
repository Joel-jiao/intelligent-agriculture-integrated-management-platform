export function pad(value: number): string {
  return value < 10 ? `0${value}` : String(value)
}

export function today(): string {
  return '2026-11-06'
}

export function nowTime(): string {
  const date = new Date()
  return `${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`
}

export function nowDateTime(): string {
  const date = new Date()
  return `${today()} ${pad(date.getHours())}:${pad(date.getMinutes())}`
}

export function formatNumber(value: number, digits = 0): string {
  return value.toLocaleString('zh-CN', {
    minimumFractionDigits: digits,
    maximumFractionDigits: digits,
  })
}

export function downloadText(filename: string, content: string) {
  const blob = new Blob([content], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  link.click()
  URL.revokeObjectURL(url)
}

export function buildCsv(headers: string[], rows: Array<Array<string | number>>): string {
  const head = headers.map((item) => `"${item}"`).join(',')
  const body = rows
    .map((row) => row.map((cell) => `"${String(cell).replace(/"/g, '""')}"`).join(','))
    .join('\n')
  return `\uFEFF${head}\n${body}`
}
