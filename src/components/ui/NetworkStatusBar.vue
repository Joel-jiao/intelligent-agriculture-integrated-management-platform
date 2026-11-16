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

const message = computed(() => {
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
    <div v-if="visible" class="net-bar" :class="`net-bar--${barTone}`">
      <span class="net-bar__icon" aria-hidden="true">
        <span v-if="barTone === 'retrying'" class="net-spinner" />
        <span v-else>✓</span>
      </span>
      <div class="net-bar__main">
        <b>{{ message }}</b>
        <span>{{ detail }}</span>
      </div>
      <div class="net-bar__actions">
        <button v-if="barTone === 'retrying'" class="net-bar__btn" type="button" @click="manualRetry">立即重试</button>
        <button class="net-bar__close" type="button" aria-label="关闭" @click="dismiss">×</button>
      </div>
    </div>
  </Transition>
</template>

<style scoped>
.net-bar {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 9px 12px;
  font-size: 12px;
  border-bottom: 1px solid var(--line);
  overflow: hidden;
}

.net-bar--retrying {
  background: #fff6e5;
  color: #8a5a00;
}

.net-bar--recovered {
  background: #eaf7ef;
  color: var(--brand-dark);
}

.net-bar__icon {
  display: grid;
  place-items: center;
  width: 18px;
  height: 18px;
  flex-shrink: 0;
}

.net-spinner {
  width: 14px;
  height: 14px;
  border: 2px solid currentColor;
  border-top-color: transparent;
  border-radius: 50%;
  animation: net-spin 0.9s linear infinite;
}

.net-bar__main {
  display: flex;
  flex: 1;
  flex-direction: column;
  min-width: 0;
}

.net-bar__main b {
  font-weight: 650;
  color: inherit;
}

.net-bar__main span {
  margin-top: 1px;
  font-size: 10.5px;
  opacity: 0.72;
}

.net-bar__actions {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-shrink: 0;
}

.net-bar__btn {
  padding: 4px 10px;
  border: 1px solid currentColor;
  border-radius: 7px;
  background: transparent;
  color: inherit;
  font-size: 11px;
  cursor: pointer;
}

.net-bar__close {
  display: grid;
  place-items: center;
  width: 20px;
  height: 20px;
  border: 0;
  background: none;
  color: inherit;
  font-size: 16px;
  line-height: 1;
  cursor: pointer;
  opacity: 0.7;
}

.net-enter-active,
.net-leave-active {
  transition: 0.24s;
}

.net-enter-from,
.net-leave-to {
  opacity: 0;
  transform: translateY(-100%);
}

@keyframes net-spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
