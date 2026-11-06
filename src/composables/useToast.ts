import { reactive } from 'vue'

export type ToastType = 'success' | 'error' | 'warn' | 'info'

export interface ToastItem {
  id: number
  type: ToastType
  message: string
}

const toasts = reactive<ToastItem[]>([])
let seq = 0

function push(message: string, type: ToastType = 'success') {
  const id = ++seq
  toasts.push({ id, type, message })
  window.setTimeout(() => {
    const index = toasts.findIndex((item) => item.id === id)
    if (index > -1) toasts.splice(index, 1)
  }, 2800)
}

export function useToast() {
  return {
    toasts,
    push,
    success: (message: string) => push(message, 'success'),
    error: (message: string) => push(message, 'error'),
    warn: (message: string) => push(message, 'warn'),
    info: (message: string) => push(message, 'info'),
  }
}
