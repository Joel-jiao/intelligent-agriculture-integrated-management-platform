<script setup lang="ts">
import { computed, ref } from 'vue'
import AppModal from '@/components/ui/AppModal.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import { useToast } from '@/composables/useToast'
import { devices as seedDevices, plots } from '@/data/mock'
import type { Device } from '@/data/types'
import { nowDateTime } from '@/utils/format'

const toast = useToast()

const selectedPlotId = ref(plots[0]?.id ?? '')
const deviceList = ref<Device[]>(seedDevices.map((item) => ({ ...item })))
const safetyLock = ref(true)

const filteredDevices = computed(() =>
  deviceList.value.filter(
    (item) => item.plotId === selectedPlotId.value && item.type !== '传感器' && item.type !== '网关',
  ),
)

const runningCount = computed(() => filteredDevices.value.filter((item) => item.running).length)

interface OpRecord {
  id: number
  time: string
  text: string
}

const records = ref<OpRecord[]>([
  { id: 1, time: '2026-11-06 09:40', text: '管理员下发 1号棚水泵启动指令' },
  { id: 2, time: '2026-11-06 08:12', text: '安全锁开启，远程控制已锁定' },
])
let recordSeq = 2

function appendRecord(text: string) {
  recordSeq += 1
  records.value.unshift({ id: recordSeq, time: nowDateTime(), text })
}

function onLockChange() {
  appendRecord(safetyLock.value ? '安全锁已开启，远程控制已锁定' : '安全锁已关闭，允许远程操作')
  toast.info(safetyLock.value ? '安全锁已开启，设备控制已锁定' : '安全锁已关闭，请谨慎操作设备')
}

type ModalMode = 'toggle' | 'stopAll'

const modalOpen = ref(false)
const modalMode = ref<ModalMode>('toggle')
const pendingId = ref('')

const pendingDevice = computed(() => deviceList.value.find((item) => item.id === pendingId.value))

const modalTitle = computed(() => (modalMode.value === 'stopAll' ? '确认全部停止' : '确认设备操作'))

const modalText = computed(() => {
  if (modalMode.value === 'stopAll') {
    return `将停止 ${plots.find((item) => item.id === selectedPlotId.value)?.name ?? '当前地块'} 内全部 ${runningCount.value} 台运行中的设备，请确认现场安全。`
  }
  const device = pendingDevice.value
  if (!device) return '未找到待操作的设备'
  return `${device.name} 当前${device.running ? '运行中' : '已停止'}，确认${device.running ? '停止' : '启动'}该设备？`
})

function requestToggle(device: Device) {
  if (safetyLock.value) {
    toast.warn('安全锁已开启，请先关闭安全锁')
    return
  }
  if (device.status !== '在线') {
    toast.warn('设备当前不在线，无法下发控制指令')
    return
  }
  pendingId.value = device.id
  modalMode.value = 'toggle'
  modalOpen.value = true
}

function requestStopAll() {
  if (safetyLock.value) {
    toast.warn('安全锁已开启，请先关闭安全锁')
    return
  }
  if (runningCount.value === 0) {
    toast.info('当前地块没有运行中的设备')
    return
  }
  modalMode.value = 'stopAll'
  modalOpen.value = true
}

function confirmAction() {
  if (modalMode.value === 'stopAll') {
    const stopped = filteredDevices.value.filter((item) => item.running)
    if (stopped.length === 0) {
      modalOpen.value = false
      return
    }
    stopped.forEach((item) => {
      item.running = false
    })
    appendRecord(`批量停止 ${stopped.length} 台设备`)
    toast.success(`已停止 ${stopped.length} 台设备`)
  } else {
    const device = pendingDevice.value
    if (!device) {
      modalOpen.value = false
      return
    }
    device.running = !device.running
    appendRecord(`${device.name}${device.running ? '启动' : '停止'}指令下发成功`)
    toast.success(`${device.name}已${device.running ? '启动' : '停止'}`)
  }
  modalOpen.value = false
}
</script>

<template>
  <div class="mobile-page">
    <header class="page-head">
      <div>
        <h2>设备控制</h2>
        <p>远程启停 · 当前 {{ runningCount }} 台运行中</p>
      </div>
      <span class="lock-badge" :class="{ 'lock-badge--off': !safetyLock }">
        {{ safetyLock ? '控制锁定' : '已解锁' }}
      </span>
    </header>

    <label class="mobile-field plot-field">
      <span>选择地块</span>
      <select v-model="selectedPlotId">
        <option v-for="plot in plots" :key="plot.id" :value="plot.id">{{ plot.name }}（{{ plot.crop }}）</option>
      </select>
    </label>

    <div class="mobile-card lock-card">
      <div class="lock-main">
        <div class="lock-title">安全锁</div>
        <div class="lock-desc">开启后禁止下发远程控制指令，避免误操作</div>
      </div>
      <label class="switch">
        <input v-model="safetyLock" type="checkbox" @change="onLockChange" />
        <span class="switch__track" />
      </label>
    </div>

    <section class="mobile-section">
      <div class="mobile-section__head">
        <h3>设备列表</h3>
        <span>{{ filteredDevices.length }} 台可控设备</span>
      </div>

      <div v-for="device in filteredDevices" :key="device.id" class="mobile-card device-card">
        <div class="device-card__top">
          <div class="device-head">
            <span class="mobile-icon">设</span>
            <div class="device-text">
              <div class="device-name">{{ device.name }}</div>
              <div class="device-meta">{{ device.type }} · {{ device.protocol }} · {{ device.power }} kW</div>
            </div>
          </div>
          <StatusTag
            :text="device.status"
            :tone="device.status === '在线' ? 'ok' : device.status === '故障' ? 'danger' : 'warn'"
            dot
          />
        </div>
        <div class="device-card__foot">
          <div class="run-state">
            <span class="run-dot" :class="{ 'run-dot--on': device.running }" />
            <span>{{ device.running ? '运行中' : '已停止' }}</span>
            <span class="last-seen font-num">{{ device.lastSeen.slice(11) }}</span>
          </div>
          <button
            class="mobile-btn device-btn"
            :class="{ 'mobile-btn--danger': device.running }"
            type="button"
            :disabled="safetyLock || device.status !== '在线'"
            @click="requestToggle(device)"
          >
            {{ device.running ? '停止' : '启动' }}
          </button>
        </div>
      </div>

      <div v-if="filteredDevices.length === 0" class="mobile-card empty-card">
        <span class="empty-mark">空</span>
        <p>该地块暂无可远程控制的设备</p>
      </div>
    </section>

    <section class="mobile-section">
      <div class="mobile-section__head">
        <h3>批量操作</h3>
        <span>需关闭安全锁</span>
      </div>
      <button
        class="mobile-btn mobile-btn--danger mobile-btn--full"
        type="button"
        :disabled="runningCount === 0"
        @click="requestStopAll"
      >
        全部停止
      </button>
    </section>

    <section class="mobile-section">
      <div class="mobile-section__head">
        <h3>操作记录</h3>
        <span>{{ records.length }} 条</span>
      </div>
      <div class="mobile-card">
        <div v-for="record in records" :key="record.id" class="mobile-list-item">
          <span class="mobile-icon">记</span>
          <div class="record-main">
            <div class="record-text">{{ record.text }}</div>
            <div class="record-time font-num">{{ record.time }}</div>
          </div>
        </div>
      </div>
    </section>

    <div class="page-spacer" />

    <AppModal v-model="modalOpen" :title="modalTitle">
      <p class="modal-text">{{ modalText }}</p>
      <p class="modal-hint">指令下发后约 1 秒生效，可在操作记录中查看结果。</p>
      <template #footer>
        <button class="mobile-btn mobile-btn--ghost" type="button" @click="modalOpen = false">取消</button>
        <button class="mobile-btn" type="button" @click="confirmAction">确认执行</button>
      </template>
    </AppModal>
  </div>
</template>

<style scoped>
.font-num {
  font-family: var(--font-num);
}

.page-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  margin: 6px 0 12px;
  padding: 0 2px;
}

.page-head h2 {
  font-size: 20px;
  font-weight: 700;
  color: var(--ink);
}

.page-head p {
  margin-top: 3px;
  font-size: 11.5px;
  color: var(--muted);
}

.lock-badge {
  padding: 5px 10px;
  border-radius: 12px;
  background: var(--danger-soft);
  color: var(--danger);
  font-size: 11px;
  white-space: nowrap;
}

.lock-badge--off {
  background: var(--ok-soft);
  color: var(--ok);
}

.plot-field {
  margin-bottom: 12px;
}

.lock-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
}

.lock-title {
  font-size: 13px;
  font-weight: 650;
  color: var(--ink);
}

.lock-desc {
  margin-top: 2px;
  font-size: 10.5px;
  line-height: 1.5;
  color: var(--muted);
}

.device-card__top {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: 10px;
}

.device-head {
  display: flex;
  align-items: center;
  gap: 9px;
  min-width: 0;
}

.device-text {
  min-width: 0;
}

.device-name {
  font-size: 13px;
  font-weight: 650;
  color: var(--ink);
}

.device-meta {
  margin-top: 1px;
  font-size: 10.5px;
  color: var(--faint);
}

.device-card__foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  margin-top: 12px;
  padding-top: 10px;
  border-top: 1px dashed var(--line);
}

.run-state {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  color: var(--muted);
}

.run-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--faint);
}

.run-dot--on {
  background: var(--ok);
  box-shadow: 0 0 0 3px rgba(47, 158, 90, 0.16);
}

.last-seen {
  margin-left: 4px;
  font-size: 10px;
  color: var(--faint);
}

.device-btn {
  height: 44px;
  padding: 0 20px;
  font-size: 13px;
}

.record-main {
  flex: 1;
  min-width: 0;
}

.record-text {
  font-size: 11.5px;
  color: var(--ink-2);
}

.record-time {
  margin-top: 1px;
  font-size: 10px;
  color: var(--faint);
}

.empty-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 7px;
  padding: 28px 16px;
}

.empty-card p {
  font-size: 12px;
  color: var(--muted);
}

.empty-mark {
  display: grid;
  place-items: center;
  width: 46px;
  height: 46px;
  border-radius: 50%;
  background: var(--surface-2);
  color: var(--faint);
  font-size: 14px;
}

.modal-text {
  font-size: 13px;
  line-height: 1.7;
  color: var(--ink-2);
}

.modal-hint {
  margin-top: 8px;
  font-size: 11px;
  color: var(--muted);
}

.page-spacer {
  height: 20px;
}
</style>
