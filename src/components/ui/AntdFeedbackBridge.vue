<script setup lang="ts">
/**
 * AntD 主题反馈桥接组件。
 * antd 的静态 message API 感知不到 ConfigProvider 主题（暗色模式下会渲染成浅色），
 * 只有在 <a-app> 内部通过 App.useApp() 拿到的实例才会跟随主题。
 * 本组件在应用根部把该实例交给 useToast，使全局轻提示同样支持明暗主题。
 */
import { App } from 'ant-design-vue'
import { bindMessageInstance } from '@/composables/useToast'

const { message } = App.useApp()
bindMessageInstance(message)
</script>

<template>
  <span hidden aria-hidden="true"></span>
</template>
