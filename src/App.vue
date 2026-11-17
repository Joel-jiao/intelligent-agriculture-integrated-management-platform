<script setup lang="ts">
import { onMounted } from 'vue'
import { RouterView } from 'vue-router'
import { App as AntApp } from 'ant-design-vue'
import zhCN from 'ant-design-vue/es/locale/zh_CN'
import dayjs from 'dayjs'
import BackendGate from '@/components/ui/BackendGate.vue'
import AntdFeedbackBridge from '@/components/ui/AntdFeedbackBridge.vue'
import { backend, loadAllData, loadPublicData } from '@/api/store'
import { useAntdTheme } from '@/composables/useAntdTheme'
import { useAuth } from '@/composables/useAuth'

import 'dayjs/locale/zh-cn'

dayjs.locale('zh-cn')

const { antdThemeConfig } = useAntdTheme()
const { hasSession } = useAuth()

onMounted(() => {
  // 已登录：加载全部业务数据；未登录：仅加载公开数据（登录页 / 溯源 H5 等公开场景）
  if (hasSession.value) void loadAllData()
  else void loadPublicData()
})
</script>

<template>
  <a-config-provider :theme="antdThemeConfig" :locale="zhCN">
    <AntApp>
      <AntdFeedbackBridge />
      <!-- 未登录：直接渲染公开页（登录页 / 溯源 H5 / 业务端总览）；
           已登录：数据就绪后才渲染业务页 -->
      <RouterView v-if="!hasSession || backend.status === 'ready'" />
      <BackendGate v-else />
    </AntApp>
  </a-config-provider>
</template>
