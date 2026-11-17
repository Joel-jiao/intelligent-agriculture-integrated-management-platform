<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import DonutChart from '@/components/ui/DonutChart.vue'
import LineChart from '@/components/ui/LineChart.vue'
import { useToast } from '@/composables/useToast'
import { devices, plotName, plots } from '@/api/store'
import type { Device } from '@/data/types'
import { buildCsv, downloadText, nowDateTime } from '@/utils/format'

const toast = useToast()
const router = useRouter()

const deviceList = ref<Device[]>(devices.map((item) => ({ ...item })))
const typeFilter = ref('全部')
const statusFilter = ref('全部')
const plotFilter = ref('全部')
const keyword = ref('')
const selectedId = ref(devices[0]?.id ?? '')

const deviceTypes = ['水泵', '风机', '卷帘', '补光灯', '电磁阀', '传感器', '摄像头', '网关']
const statusOptions: Array<Device['status']> = ['在线', '离线', '故障']

function statusTone(status: Device['status']): 'ok' | 'mute' | 'danger' {
  if (status === '在线') return 'ok'
  if (status === '故障') return 'danger'
  return 'mute'
}

const filteredDevices = computed(() =>
  deviceList.value.filter((item) => {
    if (typeFilter.value !== '全部' && item.type !== typeFilter.value) return false
    if (statusFilter.value !== '全部' && item.status !== statusFilter.value) return false
    if (plotFilter.value !== '全部' && item.plotId !== plotFilter.value) return false
    if (keyword.value.trim() !== '') {
      const text = keyword.value.trim().toLowerCase()
      if (!item.id.toLowerCase().includes(text) && !item.name.toLowerCase().includes(text)) return false
    }
    return true
  }),
)

const groups = computed(() => {
  const map = new Map<string, Device[]>()
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

const total = computed(() => deviceList.value.length)
const onlineCount = computed(() => deviceList.value.filter((item) => item.status === '在线').length)
const offlineCount = computed(() => deviceList.value.filter((item) => item.status === '离线').length)
const faultCount = computed(() => deviceList.value.filter((item) => item.status === '故障').length)
const onlineRate = computed(() => (total.value === 0 ? 0 : Math.round((onlineCount.value / total.value) * 100)))

const statusSegments = computed(() => [
  { label: '在线', value: onlineCount.value, color: '#34c759' },
  { label: '离线', value: offlineCount.value, color: '#c7c7cc' },
  { label: '故障', value: faultCount.value, color: '#ff3b30' },
])

const faultDevices = computed(() => deviceList.value.filter((item) => item.status === '故障'))

const selectedDevice = computed(() => deviceList.value.find((item) => item.id === selectedId.value) ?? null)
const selectedDevicePlot = computed(() => (selectedDevice.value ? plotName(selectedDevice.value.plotId) : ''))

const runtimeLabels = computed(() => Array.from({ length: 12 }, (_, index) => `${String(index * 2).padStart(2, '0')}:00`))
const runtimeSeries = computed(() => {
  const device = selectedDevice.value
  if (!device) return []
  const seed = Number(device.id.replace(/\D/g, '')) || 1
  const base = device.power * 0.72
  const data = Array.from({ length: 12 }, (_, index) => {
    const wave = Math.sin((index + seed) / 2.1) * 0.16 + Math.cos((index + seed) / 3.4) * 0.08
    return Math.round(base * (1 + wave) * 100) / 100
  })
  return [{ name: '实时功率', color: '#007aff', data }]
})

function openDetail(device: Device) {
  selectedId.value = device.id
}

function refreshStatuses() {
  deviceList.value = deviceList.value.map((item) => ({ ...item, lastSeen: nowDateTime() }))
  toast.success(`设备在线状态已刷新，共同步 ${deviceList.value.length} 台设备`)
}

function reportFaults() {
  if (faultDevices.value.length === 0) {
    toast.info('当前没有故障设备')
    return
  }
  toast.success(`已为 ${faultDevices.value.map((item) => item.name).join('、')} 生成维修工单`)
}

function exportCsv() {
  const rows = filteredDevices.value.map((item) => [
    item.id,
    item.name,
    item.type,
    plotName(item.plotId),
    item.status,
    item.running ? '运行' : '停止',
    item.protocol,
    item.lastSeen,
    item.power,
  ])
  downloadText(
    '设备状态监控_20261106.csv',
    buildCsv(['设备编号', '设备名称', '类型', '所属地块', '状态', '运行状态', '通信协议', '最后在线', '功率(kW)'], rows),
  )
  toast.success(`已导出 ${rows.length} 条设备记录`)
}

function control(device: Device) {
  toast.info(`正在跳转至「${device.name}」远程控制`)
  router.push('/control/device')
}

function editDevice(device: Device) {
  toast.info(`「${device.name}」的参数编辑入口已打开`)
}

function removeDevice(device: Device) {
  toast.warn(`删除「${device.name}」需在运维端确认，已记录操作申请`)
}

function toggleRunning() {
  const device = selectedDevice.value
  if (!device) return
  if (device.status !== '在线') {
    toast.error(`${device.name} 当前离线，指令无法下发`)
    return
  }
  device.running = !device.running
  device.lastSeen = nowDateTime()
  toast.success(`${device.name} 已${device.running ? '启动' : '停止'}`)
}

function batteryText(device: Device): string {
  return device.battery === undefined ? '市电供电' : `电量 ${device.battery}%`
}
</script>

<template>
  <div>
    <PageHeader
      title="设备管理"
      :description="`接入设备状态、运行工况与远程控制 · 平台纳管设备 ${total} 台`"
    >
      <template #actions>
        <button class="btn" type="button" @click="refreshStatuses">刷新状态</button>
        <button class="btn btn--primary" type="button" @click="exportCsv">导出设备清单</button>
      </template>
    </PageHeader>

    <!-- 筛选 -->
    <div class="filter-bar">
      <select v-model="typeFilter" class="select" aria-label="设备类型">
        <option value="全部">全部类型</option>
        <option v-for="type in deviceTypes" :key="type" :value="type">{{ type }}</option>
      </select>
      <select v-model="statusFilter" class="select" aria-label="运行状态">
        <option value="全部">全部状态</option>
        <option v-for="status in statusOptions" :key="status" :value="status">{{ status }}</option>
      </select>
      <select v-model="plotFilter" class="select" aria-label="所属地块">
        <option value="全部">全部地块</option>
        <option v-for="plot in plots" :key="plot.id" :value="plot.id">{{ plot.name }}</option>
      </select>
      <input v-model="keyword" class="input input--search" placeholder="搜索设备名称或编号" />
      <span class="filter-bar__count">共 {{ filteredDevices.length }} 台</span>
    </div>

    <div class="split">
      <!-- 分组设备表格 -->
      <div>
        <section v-for="group in groups" :key="group.plotId" class="card device-group">
          <div class="device-group__head">
            <div class="device-group__title">
              {{ group.plotName }}
              <span>{{ group.devices.length }} 台</span>
            </div>
            <span class="tag tag--outline">{{ group.plotId }}</span>
          </div>
          <div class="table-wrap">
            <table class="data-table">
              <thead>
                <tr>
                  <th>设备 / 位置</th>
                  <th>编号</th>
                  <th>状态</th>
                  <th>电量 / 运行</th>
                  <th>最后上报</th>
                  <th class="cell-actions">操作</th>
                </tr>
              </thead>
              <tbody>
                <tr
                  v-for="device in group.devices"
                  :key="device.id"
                  class="device-row"
                  :class="{ 'is-active': device.id === selectedId }"
                  @click="openDetail(device)"
                >
                  <td>
                    <div class="cell-strong">{{ device.name }}</div>
                    <div class="cell-sub">{{ plotName(device.plotId) }}</div>
                  </td>
                  <td class="num cell-muted">{{ device.id }}</td>
                  <td>
                    <span class="pill" :class="`pill--${statusTone(device.status)}`">
                      <i class="dot" :class="`dot--${statusTone(device.status) === 'mute' ? 'mute' : statusTone(device.status)}`" />
                      {{ device.status === '故障' ? '告警' : device.status }}
                    </span>
                  </td>
                  <td>
                    <div class="running-cell">
                      <span>{{ batteryText(device) }}</span>
                      <span class="running-cell__state">
                        <i class="dot" :class="device.running ? 'dot--ok' : 'dot--mute'" />
                        {{ device.running ? '运行中' : '已停止' }}
                      </span>
                    </div>
                  </td>
                  <td class="num cell-muted">{{ device.lastSeen }}</td>
                  <td class="cell-actions">
                    <div class="table-actions" @click.stop>
                      <button class="link-action" type="button" @click="openDetail(device)">查看详情</button>
                      <button class="link-action" type="button" @click="control(device)">远程控制</button>
                      <button class="link-action link-action--muted" type="button" @click="editDevice(device)">编辑</button>
                      <button class="link-action link-action--danger" type="button" @click="removeDevice(device)">删除</button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <div v-if="groups.length === 0" class="card">
          <div class="empty">
            <div class="empty__mark">空</div>
            <span>没有符合筛选条件的设备</span>
          </div>
        </div>
      </div>

      <!-- 右侧详情面板 -->
      <aside class="side-panel">
        <template v-if="selectedDevice">
          <div class="side-panel__head">
            <div>
              <div class="side-panel__title">{{ selectedDevice.name }}</div>
              <div class="side-panel__sub">{{ selectedDevice.id }} · {{ selectedDevicePlot }}</div>
            </div>
            <span class="pill" :class="`pill--${statusTone(selectedDevice.status)}`">
              {{ selectedDevice.status === '故障' ? '告警' : selectedDevice.status }}
            </span>
          </div>
          <div class="side-panel__body">
            <div class="side-panel__section" style="padding-top: 0; margin-top: 0; border-top: 0">
              <div class="side-panel__section-title">设备参数</div>
              <div class="kv">
                <div class="kv__item"><span>设备类型</span><b>{{ selectedDevice.type }}</b></div>
                <div class="kv__item"><span>通信协议</span><b>{{ selectedDevice.protocol }}</b></div>
                <div class="kv__item"><span>额定功率</span><b>{{ selectedDevice.power }} kW</b></div>
                <div class="kv__item"><span>供电方式</span><b>{{ batteryText(selectedDevice) }}</b></div>
                <div class="kv__item"><span>运行状态</span><b>{{ selectedDevice.running ? '运行中' : '已停止' }}</b></div>
                <div class="kv__item"><span>最后上报</span><b>{{ selectedDevice.lastSeen.slice(11) }}</b></div>
              </div>
            </div>

            <div class="side-panel__section">
              <div class="side-panel__section-title">24 小时运行曲线</div>
              <LineChart :labels="runtimeLabels" :series="runtimeSeries" unit=" kW" :height="132" dense />
            </div>

            <div class="side-panel__section">
              <div class="side-panel__section-title">远程控制</div>
              <div class="control-row">
                <button class="btn btn--primary" type="button" :disabled="selectedDevice.status !== '在线'" @click="toggleRunning">
                  {{ selectedDevice.running ? '停止设备' : '启动设备' }}
                </button>
                <button class="btn" type="button" @click="control(selectedDevice)">进入控制台</button>
              </div>
              <button
                class="btn btn--danger btn--full"
                type="button"
                style="margin-top: 8px"
                @click="toast.warn('重启指令需二次确认，已发送确认请求')"
              >
                重启设备
              </button>
              <div class="side-panel__note">指令经网关下发，平均响应 0.4 秒，操作全程留痕。</div>
            </div>
          </div>
        </template>

        <template v-else>
          <div class="side-panel__head">
            <div>
              <div class="side-panel__title">设备概况</div>
              <div class="side-panel__sub">选择左侧设备查看详情</div>
            </div>
          </div>
          <div class="side-panel__body">
            <DonutChart
              :segments="statusSegments"
              :size="132"
              :center-value="`${onlineRate}%`"
              center-label="在线率"
            />
            <div v-if="faultDevices.length > 0" class="side-panel__section">
              <div class="side-panel__section-title">故障提醒</div>
              <div v-for="device in faultDevices" :key="device.id" class="fault-row">
                <span>{{ device.name }}</span>
                <StatusTag text="故障" tone="danger" dot />
              </div>
              <button class="btn btn--sm btn--full" type="button" style="margin-top: 10px" @click="reportFaults">
                生成维修工单
              </button>
            </div>
          </div>
        </template>
      </aside>
    </div>
  </div>
</template>

<style scoped>
.filter-bar__count {
  margin-left: auto;
  font-size: 12px;
  color: var(--text-secondary);
  white-space: nowrap;
}

.device-row {
  cursor: pointer;
}

.cell-sub {
  margin-top: 1px;
  font-size: 11px;
  color: var(--text-tertiary);
}

.device-row .table-actions {
  gap: 10px;
}

.device-group .data-table th,
.device-group .data-table td {
  padding: 0 14px;
}

.device-row.is-active {
  background: var(--primary-softer);
}

.running-cell {
  display: flex;
  flex-direction: column;
  gap: 1px;
  font-size: 12px;
  color: var(--text-secondary);
}

.running-cell__state {
  display: flex;
  align-items: center;
  gap: 5px;
  font-size: 11.5px;
}

.side-panel__note {
  margin-top: 10px;
  font-size: 11px;
  line-height: 1.6;
  color: var(--text-tertiary);
}

.fault-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 7px 0;
  font-size: 12.5px;
}

@media (max-width: 720px) {
  .filter-bar__count {
    width: 100%;
    margin-left: 0;
  }
}
</style>
