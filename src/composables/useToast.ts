import { message as staticMessage } from 'ant-design-vue'

export type ToastType = 'success' | 'error' | 'warn' | 'info'

/** 本项目实际用到的 message 能力（静态 API 与 useApp 实例均满足） */
interface ToastMessageApi {
  success: (content: string) => unknown
  error: (content: string) => unknown
  warning: (content: string) => unknown
  info: (content: string) => unknown
}

/** 主题化的 message 实例，由 AntdFeedbackBridge 在 <a-app> 内注入 */
let themedMessage: ToastMessageApi | null = null

/**
 * 供 AntdFeedbackBridge 调用：把跟随 ConfigProvider 主题的 message 实例
 * 交给全局提示层，未注入前回退到 antd 静态 API。
 */
export function bindMessageInstance(instance: ToastMessageApi) {
  themedMessage = instance
}

function api(): ToastMessageApi {
  return themedMessage ?? staticMessage
}

function push(text: string, type: ToastType = 'success') {
  switch (type) {
    case 'success':
      void api().success(text)
      break
    case 'error':
      void api().error(text)
      break
    case 'warn':
      void api().warning(text)
      break
    case 'info':
      void api().info(text)
      break
  }
}

/**
 * 全局轻提示。对外 API 与旧版保持一致（success/error/warn/info），
 * 页面代码零改动；实现已切换为 Ant Design Vue 的 message 组件。
 */
export function useToast() {
  return {
    push,
    success: (text: string) => push(text, 'success'),
    error: (text: string) => push(text, 'error'),
    warn: (text: string) => push(text, 'warn'),
    info: (text: string) => push(text, 'info'),
  }
}
