<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useNetwork } from '@/composables/useNetwork'

const { state, isOffline, recover } = useNetwork()

const attempt = ref(0)
const recovered = ref(false)

const RETRY_INTERVAL = 4000
const RECOVER_RESET_DELAY = 2600

let autoTimer = 0
let resetTimer = 0

const visible = computed(() => isOffline.value)

const barTone = computed(() => (recovered.value ? 'recovered' : 'retrying'))

const barMessage = computed(() => {
  if (recovered.value) return '网络已恢复，缓存数据已补传'
  if (state.gatewayOffline) return '网关离线，数据存在延迟，正在重试'
  return '网络连接异常，正在重试'
})

const detail = computed(() => {
  if (recovered.value) return '断网期间录入的作业数据已自动同步，请放心继续操作'
  if (state.gatewayOffline) return '设备采集数据已本地缓存，恢复后将自动补传'
  return `已自动重试 ${attempt.value} 次`
})

function doRetry(manual: boolean) {
  if (manual) {
    markRecovered()
    return
  }
  attempt.value += 1
  if (attempt.value >= 2) markRecovered()
}

function markRecovered() {
  recovered.value = true
  stopAutoRetry()
  window.clearTimeout(resetTimer)
  resetTimer = window.setTimeout(() => {
    recover()
    recovered.value = false
    attempt.value = 0
  }, RECOVER_RESET_DELAY)
}

function startAutoRetry() {
  stopAutoRetry()
  autoTimer = window.setInterval(() => doRetry(false), RETRY_INTERVAL)
}

function stopAutoRetry() {
  window.clearInterval(autoTimer)
}

function manualRetry() {
  doRetry(true)
}

function dismiss() {
  stopAutoRetry()
  window.clearTimeout(resetTimer)
  recover()
  recovered.value = false
  attempt.value = 0
}

watch(visible, (value) => {
  if (value) {
    recovered.value = false
    attempt.value = 0
    startAutoRetry()
  } else {
    stopAutoRetry()
  }
})

onBeforeUnmount(() => {
  stopAutoRetry()
  window.clearTimeout(resetTimer)
})
</script>

<template>
  <Transition name="net">
    <a-alert
      v-if="visible"
      class="net-alert"
      :type="barTone === 'recovered' ? 'success' : 'warning'"
      show-icon
      :message="barMessage"
      :description="detail"
      closable
      @close="dismiss"
    >
      <template v-if="barTone === 'retrying'" #action>
        <a-button size="small" @click="manualRetry">立即重试</a-button>
      </template>
    </a-alert>
  </Transition>
</template>

<style scoped>
/* 沿用原顶部横条形态：贴边、无圆角、紧贴视图顶部 */
.net-alert {
  margin: 0;
  border-radius: 0;
  border-top: 0;
  border-left: 0;
  border-right: 0;
  align-items: center;
}
</style>
