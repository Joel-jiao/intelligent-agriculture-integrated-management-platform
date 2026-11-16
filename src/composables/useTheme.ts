import { ref } from 'vue'

export type ThemeMode = 'light' | 'dark'

const STORAGE_KEY = 'agri-platform-theme'

function readPreferred(): ThemeMode {
  if (typeof window === 'undefined') return 'light'
  const saved = window.localStorage.getItem(STORAGE_KEY)
  if (saved === 'light' || saved === 'dark') return saved
  return window.matchMedia?.('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
}

const theme = ref<ThemeMode>(readPreferred())

function apply(mode: ThemeMode) {
  if (typeof document === 'undefined') return
  document.documentElement.dataset.theme = mode
  document.documentElement.style.colorScheme = mode
}

/** 在应用挂载前调用，避免首屏闪烁；支持 ?theme=dark 直接预览 */
export function initTheme() {
  if (typeof window !== 'undefined') {
    const query = new URLSearchParams(window.location.search).get('theme')
    if (query === 'dark' || query === 'light') theme.value = query
  }
  apply(theme.value)
}

export function useTheme() {
  function setTheme(mode: ThemeMode) {
    theme.value = mode
    apply(mode)
    try {
      window.localStorage.setItem(STORAGE_KEY, mode)
    } catch {
      /* 忽略隐私模式下的写入失败 */
    }
  }

  function toggle() {
    setTheme(theme.value === 'dark' ? 'light' : 'dark')
  }

  return { theme, setTheme, toggle, isDark: () => theme.value === 'dark' }
}
