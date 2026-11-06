<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import DonutChart from '@/components/ui/DonutChart.vue'
import Pager from '@/components/ui/Pager.vue'
import { useToast } from '@/composables/useToast'
import { devices, plotName, plots } from '@/data/mock'
import type { Device } from '@/data/types'
import { buildCsv, downloadText, nowDateTime } from '@/utils/format'

const toast = useToast()

const deviceList = ref<Device[]>(devices.map((item) => ({ ...item })))
const typeFilter = ref('全部')
const statusFilter = ref('全部')
const plotFilter = ref('全部')
const keyword = ref('')

const deviceTypes = ['水泵', '风机', '卷帘', '补光灯', '电磁阀', '传感器', '摄像头', '网关']
const statusOptions: Array<Device['status']> = ['在线', '离线', '故障']

function statusTone(status: Device['status']): 'ok' | 'warn' | 'danger' {
  if (status === '在线') return 'ok'
  if (status === '故障') return 'danger'
  return 'warn'
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

const total = computed(() => deviceList.value.length)
const onlineCount = computed(() => deviceList.value.filter((item) => item.status === '在线').length)
const offlineCount = computed(() => deviceList.value.filter((item) => item.status === '离线').length)
const faultCount = computed(() => deviceList.value.filter((item) => item.status === '故障').length)
const onlineRate = computed(() => (total.value === 0 ? 0 : Math.round((onlineCount.value / total.value) * 100)))

const statusSegments = computed(() => [
  { label: '在线', value: onlineCount.value, color: '#2f9e5b' },
  { label: '离线', value: offlineCount.value, color: '#c47f17' },
  { label: '故障', value: faultCount.value, color: '#c93e3e' },
])

const faultDevices = computed(() => deviceList.value.filter((item) => item.status === '故障'))

const pageSize = 8
const page = ref(1)
const pagedDevices = computed(() => {
  const start = (page.value - 1) * pageSize
  return filteredDevices.value.slice(start, start + pageSize)
})

watch([typeFilter, statusFilter, plotFilter, keyword], () => {
  page.value = 1
})

const detailOpen = ref(false)
const selectedDevice = ref<Device | null>(null)

function openDetail(device: Device) {
  selectedDevice.value = device
  detailOpen.value = true
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
</script>

<template>
  <div>
    <PageHeader
      eyebrow="IOT · DEVICES"
      title="设备状态监控"
      :description="`接入设备在线状态、运行工况与故障提醒 · 平台纳管设备 ${total} 台`"
    >
      <template #actions>
        <button class="btn" type="button" @click="refreshStatuses">刷新状态</button>
        <button class="btn btn--primary" type="button" @click="exportCsv">导出设备清单</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="设备总数" :value="total" unit="台" icon="总" note="覆盖 6 个地块" />
      <StatCard label="在线设备" :value="onlineCount" unit="台" icon="在" note="状态正常，可远程控制" :trend="`在线率 ${onlineRate}%`" />
      <StatCard label="离线设备" :value="offlineCount" unit="台" icon="离" note="需排查网络或供电" trend="较昨日 +1" :trend-up="false" />
      <StatCard label="故障设备" :value="faultCount" unit="台" icon="障" note="已触发告警与工单" accent />
    </div>

    <div class="toolbar">
      <div class="field">
        <span class="field__label">设备类型</span>
        <select v-model="typeFilter" class="select" style="width: 130px">
          <option value="全部">全部类型</option>
          <option v-for="type in deviceTypes" :key="type" :value="type">{{ type }}</option>
        </select>
      </div>
      <div class="field">
        <span class="field__label">运行状态</span>
        <select v-model="statusFilter" class="select" style="width: 120px">
          <option value="全部">全部状态</option>
          <option v-for="status in statusOptions" :key="status" :value="status">{{ status }}</option>
        </select>
      </div>
      <div class="field">
        <span class="field__label">所属地块</span>
        <select v-model="plotFilter" class="select" style="width: 150px">
          <option value="全部">全部地块</option>
          <option v-for="plot in plots" :key="plot.id" :value="plot.id">{{ plot.name }}</option>
        </select>
      </div>
      <div class="field">
        <span class="field__label">关键词</span>
        <input v-model="keyword" class="input" placeholder="搜索设备编号或名称" style="width: 190px" />
      </div>
      <div class="toolbar__spacer" />
      <span class="tag tag--brand">筛选结果 {{ filteredDevices.length }} 台</span>
    </div>

    <div class="grid grid--main">
      <section class="card">
        <div class="card__head">
          <div class="card__title">
            设备清单
            <span class="card__sub">点击任意行查看设备详情</span>
          </div>
          <button class="link-action" type="button" @click="exportCsv">导出当前结果</button>
        </div>
        <div class="table-wrap" style="border: 0; border-radius: 0">
          <table class="data-table">
            <thead>
              <tr>
                <th>设备编号</th>
                <th>设备名称</th>
                <th>类型</th>
                <th>地块</th>
                <th>状态</th>
                <th>运行 / 停止</th>
                <th>协议</th>
                <th>最后在线</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="device in pagedDevices" :key="device.id" style="cursor: pointer" @click="openDetail(device)">
                <td class="num cell-strong">{{ device.id }}</td>
                <td>{{ device.name }}</td>
                <td>{{ device.type }}</td>
                <td>{{ plotName(device.plotId) }}</td>
                <td><StatusTag :text="device.status" :tone="statusTone(device.status)" dot /></td>
                <td>
                  <span class="row" style="gap: 6px">
                    <i class="dot" :class="device.running ? 'dot--ok' : 'dot--info'" />
                    {{ device.running ? '运行' : '停止' }}
                  </span>
                </td>
                <td class="num">{{ device.protocol }}</td>
                <td class="num cell-muted">{{ device.lastSeen }}</td>
                <td>
                  <button class="btn btn--sm" type="button" @click.stop="openDetail(device)">详情</button>
                </td>
              </tr>
              <tr v-if="pagedDevices.length === 0">
                <td colspan="9"><div class="empty">没有符合筛选条件的设备</div></td>
              </tr>
            </tbody>
          </table>
        </div>
        <Pager :total="filteredDevices.length" :page="page" :page-size="pageSize" @update:page="page = $event" />
      </section>

      <div class="stack">
        <section class="card">
          <div class="card__head">
            <div class="card__title">设备在线率</div>
            <span class="tag tag--ok">{{ onlineRate }}%</span>
          </div>
          <div class="card__body">
            <DonutChart
              :segments="statusSegments"
              :size="140"
              :center-value="`${onlineRate}%`"
              center-label="在线率"
            />
          </div>
        </section>

        <section v-if="faultDevices.length > 0" class="card">
          <div class="card__head">
            <div class="card__title">故障提醒</div>
            <span class="tag tag--danger">{{ faultDevices.length }} 台</span>
          </div>
          <div class="card__body">
            <div v-for="device in faultDevices" :key="device.id" class="row row--between" style="padding: 7px 0">
              <div>
                <div style="font-size: 12.5px; color: var(--ink)">{{ device.name }}</div>
                <div style="font-size: 10.5px; color: var(--faint)">{{ device.id }} · {{ plotName(device.plotId) }}</div>
              </div>
              <StatusTag text="故障" tone="danger" dot />
            </div>
            <div class="notice notice--warn" style="margin-top: 10px">
              故障设备已停止运行，请安排运维人员现场排查供电与通信链路。
            </div>
            <button class="btn btn--sm btn--full" type="button" style="margin-top: 10px" @click="reportFaults">
              生成维修工单
            </button>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">接入方式分布</div>
          </div>
          <div class="card__body">
            <div class="kv">
              <div class="kv__item"><span>MQTT</span><b>{{ deviceList.filter((item) => item.protocol === 'MQTT').length }} 台</b></div>
              <div class="kv__item"><span>Modbus</span><b>{{ deviceList.filter((item) => item.protocol === 'Modbus').length }} 台</b></div>
              <div class="kv__item"><span>RS485</span><b>{{ deviceList.filter((item) => item.protocol === 'RS485').length }} 台</b></div>
              <div class="kv__item"><span>网关在线</span><b>1 / 1</b></div>
            </div>
          </div>
        </section>
      </div>
    </div>

    <AppModal v-model="detailOpen" title="设备详情" size="lg">
      <div v-if="selectedDevice">
        <div class="row row--between">
          <div>
            <div style="font-size: 17px; font-weight: 700; color: var(--ink)">{{ selectedDevice.name }}</div>
            <div style="font-size: 11.5px; color: var(--muted); margin-top: 2px">
              {{ selectedDevice.id }} · {{ plotName(selectedDevice.plotId) }}
            </div>
          </div>
          <StatusTag :text="selectedDevice.status" :tone="statusTone(selectedDevice.status)" dot />
        </div>
        <div class="kv kv--3" style="margin-top: 18px">
          <div class="kv__item"><span>设备类型</span><b>{{ selectedDevice.type }}</b></div>
          <div class="kv__item"><span>运行状态</span><b>{{ selectedDevice.running ? '运行中' : '已停止' }}</b></div>
          <div class="kv__item"><span>通信协议</span><b>{{ selectedDevice.protocol }}</b></div>
          <div class="kv__item"><span>额定功率</span><b>{{ selectedDevice.power }} kW</b></div>
          <div class="kv__item"><span>剩余电量</span><b>{{ selectedDevice.battery === undefined ? '市电供电' : `${selectedDevice.battery}%` }}</b></div>
          <div class="kv__item"><span>最后在线</span><b>{{ selectedDevice.lastSeen }}</b></div>
        </div>
        <div class="notice" style="margin-top: 16px">
          该设备已纳入物联网平台统一纳管，状态每 30 秒上报一次，可在设备远程控制页下发启停指令。
        </div>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="detailOpen = false">关闭</button>
        <button class="btn btn--primary" type="button" @click="detailOpen = false; toast.success('设备信息已同步至网关')">
          同步状态
        </button>
      </template>
    </AppModal>
  </div>
</template>
