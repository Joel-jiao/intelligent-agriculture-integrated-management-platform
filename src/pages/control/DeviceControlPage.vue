<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { devices, plotName, plots } from '@/data/mock'
import type { Device } from '@/data/types'
import { nowDateTime } from '@/utils/format'

const toast = useToast()

interface ControlDevice extends Device {
  selected: boolean
}

interface DeviceGroup {
  plotId: string
  plotName: string
  devices: ControlDevice[]
}

type ControlAction = '启动' | '停止'

const controlTypes = ['水泵', '风机', '卷帘', '补光灯', '电磁阀']

function isControllable(device: Device): boolean {
  return controlTypes.includes(device.type)
}

const controllables = ref<ControlDevice[]>(
  devices.filter((item) => isControllable(item)).map((item) => ({ ...item, selected: false })),
)

const plotFilter = ref('all')
const typeFilter = ref('all')
const safetyLock = ref(false)
const operator = '李明（园区管理员）'

watch(safetyLock, (value) => {
  if (value) {
    toast.warn('全局安全锁已开启，所有远程控制指令将被拦截')
  } else {
    toast.success('全局安全锁已关闭，可正常下发控制指令')
  }
})

const filteredDevices = computed(() =>
  controllables.value.filter((item) => {
    if (plotFilter.value !== 'all' && item.plotId !== plotFilter.value) return false
    if (typeFilter.value !== 'all' && item.type !== typeFilter.value) return false
    return true
  }),
)

const groups = computed<DeviceGroup[]>(() => {
  const map = new Map<string, ControlDevice[]>()
  filteredDevices.value.forEach((item) => {
    const list = map.get(item.plotId) ?? []
    list.push(item)
    map.set(item.plotId, list)
  })
  return Array.from(map.entries()).map(([plotId, list]) => ({
    plotId,
    plotName: plotName(plotId),
    devices: list,
  }))
})

const selectedCount = computed(() => filteredDevices.value.filter((item) => item.selected).length)
const runningCount = computed(() => controllables.value.filter((item) => item.running).length)
const allSelected = computed(
  () => filteredDevices.value.length > 0 && filteredDevices.value.every((item) => item.selected),
)

function toggleSelectAll() {
  const target = !allSelected.value
  filteredDevices.value.forEach((item) => {
    item.selected = target
  })
  toast.info(target ? '已选中当前筛选范围内的全部设备' : '已取消当前筛选范围的选择')
}

function clearSelection() {
  controllables.value.forEach((item) => {
    item.selected = false
  })
  toast.info('已清空设备选择')
}

const confirmOpen = ref(false)
const pending = ref<{ devices: ControlDevice[]; action: ControlAction } | null>(null)

function blockedByLock(): boolean {
  if (safetyLock.value) {
    toast.warn('安全锁已开启，控制指令被拦截，请先关闭全局安全锁')
    return true
  }
  return false
}

function requestToggle(device: ControlDevice) {
  if (blockedByLock()) return
  pending.value = { devices: [device], action: device.running ? '停止' : '启动' }
  confirmOpen.value = true
}

function requestBatch(action: ControlAction) {
  if (blockedByLock()) return
  if (selectedCount.value === 0) {
    toast.warn('请先勾选需要批量控制的设备')
    return
  }
  pending.value = { devices: filteredDevices.value.filter((item) => item.selected), action }
  confirmOpen.value = true
}

interface ControlLog {
  id: string
  time: string
  device: string
  action: string
  result: '成功' | '失败'
}

const logs = ref<ControlLog[]>([
  { id: 'LOG-001', time: '2026-11-06 09:40:12', device: '1号棚水泵', action: '启动', result: '成功' },
  { id: 'LOG-002', time: '2026-11-06 08:15:40', device: '1号棚外遮阳卷帘', action: '收起', result: '成功' },
  { id: 'LOG-003', time: '2026-11-05 22:30:08', device: '育苗棚补光灯', action: '停止', result: '成功' },
  { id: 'LOG-004', time: '2026-11-05 18:12:25', device: '3号棚水泵', action: '启动', result: '失败' },
])

function appendLog(deviceName: string, action: ControlAction, result: '成功' | '失败') {
  logs.value.unshift({
    id: `LOG-${String(logs.value.length + 1).padStart(3, '0')}`,
    time: nowDateTime(),
    device: deviceName,
    action,
    result,
  })
}

function confirmControl() {
  const task = pending.value
  if (!task) return
  if (blockedByLock()) {
    confirmOpen.value = false
    pending.value = null
    return
  }

  let succeeded = 0
  let failed = 0

  task.devices.forEach((device) => {
    const target = controllables.value.find((item) => item.id === device.id)
    if (!target || target.status !== '在线') {
      appendLog(device.name, task.action, '失败')
      failed += 1
      return
    }
    target.running = task.action === '启动'
    target.lastSeen = nowDateTime()
    appendLog(device.name, task.action, '成功')
    succeeded += 1
  })

  confirmOpen.value = false
  pending.value = null
  controllables.value.forEach((item) => {
    item.selected = false
  })

  if (succeeded > 0) {
    toast.success(`已成功下发 ${succeeded} 条${task.action}指令，设备状态已更新`)
  }
  if (failed > 0) {
    toast.error(`${failed} 台设备离线或故障，指令下发失败并已记录日志`)
  }
}

function refreshDevices() {
  controllables.value = controllables.value.map((item) => ({ ...item, lastSeen: nowDateTime() }))
  toast.success('可控设备状态已刷新')
}
</script>

<template>
  <div>
    <PageHeader
      eyebrow="CONTROL · DEVICE"
      title="设备远程控制"
      description="水泵、风机、卷帘、补光灯与电磁阀远程启停 · 所有指令均记录操作日志"
    >
      <template #actions>
        <button class="btn" type="button" @click="refreshDevices">刷新设备状态</button>
        <span class="tag" :class="safetyLock ? 'tag--danger' : 'tag--ok'">
          <i class="dot" :class="safetyLock ? 'dot--danger' : 'dot--ok'" />
          {{ safetyLock ? '安全锁已开启' : '安全锁已关闭' }}
        </span>
      </template>
    </PageHeader>

    <section class="card card--tint" style="margin-bottom: 16px">
      <div class="card__body row row--between wrap">
        <div>
          <div class="card__title" style="font-size: 14px">全局安全锁</div>
          <div style="margin-top: 4px; font-size: 11.5px; color: var(--muted)">
            开启后所有远程启停指令将被拦截，适用于现场检修、设备调试等场景。
          </div>
        </div>
        <div class="row">
          <span class="tag" :class="safetyLock ? 'tag--danger' : 'tag--ok'">
            {{ safetyLock ? '已锁定' : '未锁定' }}
          </span>
          <label class="switch">
            <input v-model="safetyLock" type="checkbox" />
            <span class="switch__track" />
            <span style="font-size: 11.5px">{{ safetyLock ? '解锁控制' : '开启锁定' }}</span>
          </label>
        </div>
      </div>
    </section>

    <div class="notice" style="margin-bottom: 14px">
      当前可控设备 {{ controllables.length }} 台，运行中 {{ runningCount }} 台。控制指令下发后需经网关回执确认，平均响应 0.4 秒。
    </div>

    <div class="toolbar">
      <div class="field">
        <span class="field__label">所属地块</span>
        <select v-model="plotFilter" class="select" style="width: 160px">
          <option value="all">全部地块</option>
          <option v-for="plot in plots" :key="plot.id" :value="plot.id">{{ plot.name }}</option>
        </select>
      </div>
      <div class="field">
        <span class="field__label">设备类型</span>
        <select v-model="typeFilter" class="select" style="width: 130px">
          <option value="all">全部类型</option>
          <option v-for="type in controlTypes" :key="type" :value="type">{{ type }}</option>
        </select>
      </div>
      <div class="toolbar__spacer" />
      <span class="tag tag--brand">已选 {{ selectedCount }} 台</span>
      <button class="link-action" type="button" @click="toggleSelectAll">
        {{ allSelected ? '取消全选' : '全选当前' }}
      </button>
      <button class="link-action" type="button" @click="clearSelection">清空选择</button>
      <button class="btn btn--sm" type="button" @click="requestBatch('启动')">批量启动</button>
      <button class="btn btn--sm btn--danger" type="button" @click="requestBatch('停止')">批量停止</button>
    </div>

    <div v-if="groups.length > 0" class="stack">
      <section v-for="group in groups" :key="group.plotId" class="card">
        <div class="card__head">
          <div class="card__title">
            {{ group.plotName }}
            <span class="card__sub">{{ group.devices.length }} 台可控设备</span>
          </div>
          <span class="tag tag--info">{{ group.plotId }}</span>
        </div>
        <div class="card__body device-grid">
          <div
            v-for="device in group.devices"
            :key="device.id"
            class="device-card"
            :class="{ 'is-selected': device.selected, 'is-locked': safetyLock }"
          >
            <div class="device-card__top">
              <label class="device-check">
                <input v-model="device.selected" type="checkbox" />
                <span>{{ device.id }}</span>
              </label>
              <StatusTag
                :text="device.status"
                :tone="device.status === '在线' ? 'ok' : device.status === '故障' ? 'danger' : 'warn'"
                dot
              />
            </div>
            <div class="device-card__name">{{ device.name }}</div>
            <div class="row" style="gap: 6px; margin-top: 6px">
              <i class="dot" :class="device.running ? 'dot--ok' : 'dot--info'" />
              <span style="font-size: 11.5px; color: var(--muted)">{{ device.running ? '运行中' : '已停止' }}</span>
            </div>
            <div class="device-card__meta">
              <span>{{ device.type }}</span>
              <span>{{ device.protocol }}</span>
              <span>{{ device.power }} kW</span>
            </div>
            <div class="device-card__meta">
              <span style="font-family: var(--font-num)">{{ device.lastSeen }}</span>
            </div>
            <button
              class="btn btn--sm btn--full"
              :class="device.running ? 'btn--danger' : ''"
              type="button"
              @click="requestToggle(device)"
            >
              {{ device.running ? '停止设备' : '启动设备' }}
            </button>
          </div>
        </div>
      </section>
    </div>
    <div v-else class="card">
      <div class="empty">当前筛选条件下没有可控设备</div>
    </div>

    <section class="card" style="margin-top: 16px">
      <div class="card__head">
        <div class="card__title">操作日志</div>
        <span class="tag tag--brand">最近 {{ logs.length }} 条</span>
      </div>
      <div class="table-wrap" style="border: 0; border-radius: 0 0 14px 14px">
        <table class="data-table">
          <thead>
            <tr>
              <th>时间</th>
              <th>设备</th>
              <th>动作</th>
              <th>结果</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="log in logs.slice(0, 10)" :key="log.id">
              <td class="num cell-strong">{{ log.time }}</td>
              <td>{{ log.device }}</td>
              <td>{{ log.action }}</td>
              <td>
                <StatusTag :text="log.result" :tone="log.result === '成功' ? 'ok' : 'danger'" dot />
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <AppModal v-model="confirmOpen" title="下发控制指令确认" size="lg">
      <div v-if="pending">
        <div class="notice" :class="pending.action === '停止' ? 'notice--warn' : 'notice--brand'">
          即将对 {{ pending.devices.length }} 台设备执行「{{ pending.action }}」操作，指令将通过物联网网关实时下发。
        </div>
        <div class="kv kv--3" style="margin-top: 14px">
          <div class="kv__item"><span>操作动作</span><b>{{ pending.action }}</b></div>
          <div class="kv__item"><span>设备数量</span><b>{{ pending.devices.length }} 台</b></div>
          <div class="kv__item"><span>操作人</span><b>{{ operator }}</b></div>
        </div>
        <div class="table-wrap" style="margin-top: 14px">
          <table class="data-table">
            <thead>
              <tr>
                <th>设备编号</th>
                <th>设备名称</th>
                <th>所属地块</th>
                <th>当前状态</th>
                <th>目标状态</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="device in pending.devices" :key="device.id">
                <td class="num cell-strong">{{ device.id }}</td>
                <td>{{ device.name }}</td>
                <td>{{ plotName(device.plotId) }}</td>
                <td>{{ device.running ? '运行中' : '已停止' }}</td>
                <td>
                  <StatusTag :text="pending.action === '启动' ? '启动' : '停止'" :tone="pending.action === '启动' ? 'ok' : 'warn'" />
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="confirmOpen = false; pending = null">取消</button>
        <button class="btn btn--primary" type="button" @click="confirmControl">确认下发</button>
      </template>
    </AppModal>
  </div>
</template>

<style scoped>
.device-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
}

.device-card {
  padding: 12px;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: var(--surface-2);
  transition: 0.16s;
}

.device-card:hover {
  border-color: var(--line-strong);
  background: var(--surface);
}

.device-card.is-selected {
  border-color: var(--brand);
  box-shadow: 0 0 0 2px rgba(47, 143, 91, 0.14);
  background: var(--brand-softer);
}

.device-card.is-locked {
  background: #fbfbfa;
}

.device-card__top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.device-check {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 11px;
  color: var(--muted);
  font-family: var(--font-num);
  cursor: pointer;
}

.device-check input {
  width: 14px;
  height: 14px;
  margin: 0;
  accent-color: var(--brand);
}

.device-card__name {
  margin-top: 8px;
  font-size: 13.5px;
  font-weight: 650;
  color: var(--ink);
}

.device-card__meta {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 6px;
  font-size: 10.5px;
  color: var(--faint);
  flex-wrap: wrap;
}

.device-card .btn {
  margin-top: 11px;
}

@media (max-width: 1280px) {
  .device-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }
}

@media (max-width: 720px) {
  .device-grid {
    grid-template-columns: 1fr;
  }
}
</style>
