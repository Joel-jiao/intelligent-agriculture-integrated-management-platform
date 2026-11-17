import { computed } from 'vue'
import { theme as antdTheme } from 'ant-design-vue'
import type { ThemeConfig } from 'ant-design-vue/es/config-provider/context'
import { useTheme } from '@/composables/useTheme'

/**
 * AntD 主题令牌与平台设计系统（assets/theme.css 的 CSS 变量）保持同源：
 * 色板、圆角一致；明暗切换跟随 useTheme 的全局状态。
 */
export function useAntdTheme() {
  const { theme } = useTheme()

  const antdThemeConfig = computed<ThemeConfig>(() => ({
    token: {
      colorPrimary: '#007aff',
      colorSuccess: '#34c759',
      colorWarning: '#ff9f0a',
      colorError: '#ff3b30',
      colorInfo: '#5e5ce6',
      borderRadius: 10,
    },
    algorithm: theme.value === 'dark' ? antdTheme.darkAlgorithm : antdTheme.defaultAlgorithm,
  }))

  return { antdThemeConfig }
}
