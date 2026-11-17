<script setup lang="ts">
import { onMounted } from 'vue'
import { RouterView } from 'vue-router'
import { App as AntApp } from 'ant-design-vue'
import zhCN from 'ant-design-vue/es/locale/zh_CN'
import dayjs from 'dayjs'
import BackendGate from '@/components/ui/BackendGate.vue'
import AntdFeedbackBridge from '@/components/ui/AntdFeedbackBridge.vue'
import { backend, loadAllData } from '@/api/store'
import { useAntdTheme } from '@/composables/useAntdTheme'

import 'dayjs/locale/zh-cn'

dayjs.locale('zh-cn')

const { antdThemeConfig } = useAntdTheme()

onMounted(() => {
  void loadAllData()
})
</script>

<template>
  <a-config-provider :theme="antdThemeConfig" :locale="zhCN">
    <AntApp>
      <AntdFeedbackBridge />
      <!-- 数据全部来自后端：加载完成前不渲染任何业务页面 -->
      <RouterView v-if="backend.status === 'ready'" />
      <BackendGate v-else />
    </AntApp>
  </a-config-provider>
</template>
