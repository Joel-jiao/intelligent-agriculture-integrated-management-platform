<script setup lang="ts">
import { onMounted } from 'vue'
import { RouterView } from 'vue-router'
import ToastHost from '@/components/ui/ToastHost.vue'
import BackendGate from '@/components/ui/BackendGate.vue'
import { backend, loadAllData } from '@/api/store'

onMounted(() => {
  void loadAllData()
})
</script>

<template>
  <!-- 数据全部来自后端：加载完成前不渲染任何业务页面 -->
  <RouterView v-if="backend.status === 'ready'" />
  <BackendGate v-else />
  <ToastHost />
</template>
