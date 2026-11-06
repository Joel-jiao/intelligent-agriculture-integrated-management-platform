<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import Pager from '@/components/ui/Pager.vue'
import { useToast } from '@/composables/useToast'
import { devices, plotName, plots } from '@/data/mock'
import type { Device, DeviceType } from '@/data/types'
import { buildCsv, downloadText, formatNumber, nowDateTime } from '@/utils/format'

const toast = useToast()

interface AccessDevice extends Device {
  topic?: string
  interval?: number
  timeout?: number
  filter?: boolean
  note?: string
}

const deviceTypes: DeviceType[] = ['水泵', '风机', '卷帘', '补光灯', '电磁阀', '传感器', '网关']
const protocols = ['MQTT', 'Modbus', 'RS485']

const rows = ref<AccessDevice[]>(
  devices.map((item) => ({
    ...item,
    topic: `iot/${item.id}/data`,
    interval: 30,
    timeout: 90,
    filter: true,
  })),
)

const typeFilter = ref('')
const statusFilter = ref('')
const protocolFilter = ref('')
const keyword = ref('')
const page = ref(1)
const pageSize = 8

const filtered = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  return rows.value.filter((item) => {
    if (typeFilter.value && item.type !== typeFilter.value) return false
    if (statusFilter.value && item.status !== statusFilter.value) return false
    if (protocolFilter.value && item.protocol !== protocolFilter.value) return false
    if (!kw) return true
    return [item.id, item.name, plotName(item.plotId)].some((field) => field.toLowerCase().includes(kw))
  })
})

const paged = computed(() => {
  const start = (page.value - 1) * pageSize
  return filtered.value.slice(start, start + pageSize)
})

watch([typeFilter, statusFilter, protocolFilter, keyword], () => {
  page.value = 1
})

const gatewayOnline = computed(() => rows.value.filter((item) => item.type === '网关' && item.status === '在线').length)
const mqttOnline = computed(() => rows.value.filter((item) => item.protocol === 'MQTT' && item.status === '在线').length)

const addOpen = ref(false)
const addForm = reactive({
  name: '',
  type: '传感器' as DeviceType,
  plotId: plots[0]?.id ?? 'P-01',
  protocol: 'MQTT' as 'MQTT' | 'Modbus' | 'RS485',
  topic: '',
  interval: 30,
  note: '',
})

function openAdd() {
  addForm.name = ''
  addForm.type = '传感器'
  addForm.plotId = plots[0]?.id ?? 'P-01'
  addForm.protocol = 'MQTT'
  addForm.topic = ''
  addForm.interval = 30
  addForm.note = ''
  addOpen.value = true
}

function createDevice() {
  const name = addForm.name.trim()
  if (!name) {
    toast.error('设备名称不能为空')
    return
  }
  if (!addForm.topic.trim()) {
    toast.error('请填写 MQTT / 采集 Topic')
    return
  }
  const nextId = `DEV-${400 + rows.value.length}`
  rows.value.unshift({
    id: nextId,
    name,
    type: addForm.type,
    plotId: addForm.plotId,
    status: '在线',
    running: false,
    lastSeen: nowDateTime(),
    protocol: addForm.protocol,
    power: 0.1,
    topic: addForm.topic.trim(),
    interval: addForm.interval,
    timeout: 90,
    filter: true,
    note: addForm.note.trim(),
  })
  addOpen.value = false
  toast.success(`设备 ${name} 已接入，编号 ${nextId}，等待首次心跳上报`)
}

const configOpen = ref(false)
const configTarget = ref<AccessDevice | null>(null)
const configForm = reactive({ topic: '', interval: 30, timeout: 90, filter: true })

function openConfig(device: AccessDevice) {
  configTarget.value = device
  configForm.topic = device.topic ?? `iot/${device.id}/data`
  configForm.interval = device.interval ?? 30
  configForm.timeout = device.timeout ?? 90
  configForm.filter = device.filter ?? true
  configOpen.value = true
}

function saveConfig() {
  const target = configTarget.value
  if (!target) return
  if (!configForm.topic.trim()) {
    toast.error('Topic 不能为空')
    return
  }
  target.topic = configForm.topic.trim()
  target.interval = configForm.interval
  target.timeout = configForm.timeout
  target.filter = configForm.filter
  configOpen.value = false
  toast.success(`设备 ${target.name} 的接入参数已下发`)
}

function syncDevice(device: AccessDevice) {
  device.lastSeen = nowDateTime()
  device.status = '在线'
  toast.success(`已向 ${device.name} 下发同步指令，回执正常`)
}

function restartDevice(device: AccessDevice) {
  device.status = '在线'
  device.running = false
  toast.success(`${device.name} 重启指令已下发，预计 15 秒后恢复在线`)
}

const deleteTarget = ref<AccessDevice | null>(null)
const deleteOpen = computed({
  get: () => deleteTarget.value !== null,
  set: (value: boolean) => {
    if (!value) deleteTarget.value = null
  },
})

function confirmDelete() {
  const target = deleteTarget.value
  if (!target) return
  rows.value = rows.value.filter((item) => item.id !== target.id)
  if (page.value > 1 && paged.value.length === 0) page.value -= 1
  deleteTarget.value = null
  toast.success(`设备 ${target.name} 已从接入列表移除`)
}

function exportDevices() {
  const list = filtered.value.map((item) => [item.id, item.name, item.type, plotName(item.plotId), item.protocol, item.status, item.lastSeen, item.topic ?? ''])
  downloadText('设备接入清单_20261106.csv', buildCsv(['设备编号', '名称', '类型', '地块', '协议', '状态', '最后心跳', 'Topic'], list))
  toast.success(`已导出 ${list.length} 条设备接入记录`)
}
</script>

<template>
  <div>
    <PageHeader eyebrow="DEVICE ACCESS" title="设备接入管理" description="管理网关、传感器与执行设备的接入协议、数据 Topic 与采集策略">
      <template #actions>
        <button class="btn" type="button" @click="exportDevices">导出清单</button>
        <button class="btn btn--primary" type="button" @click="openAdd">新增设备接入</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="接入设备" :value="rows.length" unit="台" icon="设" note="覆盖 5 种协议类型" trend="本周新增 2" trend-up />
      <StatCard label="网关在线" :value="`${gatewayOnline}/1`" icon="关" note="主网关心跳正常" trend="在线率 100%" />
      <StatCard label="MQTT 连接" :value="mqttOnline" unit="个" icon="联" note="QoS 1 · 保留会话" trend="连接稳定" />
      <StatCard label="今日上报" :value="formatNumber(12860)" unit="条" icon="报" note="平均延迟 1.2 s" trend="+4.1% 环比" trend-up accent />
    </div>

    <section class="card">
      <div class="card__body" style="padding-bottom: 0">
        <div class="toolbar">
          <div class="field">
            <span class="field__label">设备类型</span>
            <select v-model="typeFilter" class="select" style="width: 118px">
              <option value="">全部类型</option>
              <option v-for="type in deviceTypes" :key="type" :value="type">{{ type }}</option>
            </select>
          </div>
          <div class="field">
            <span class="field__label">状态</span>
            <select v-model="statusFilter" class="select" style="width: 100px">
              <option value="">全部状态</option>
              <option value="在线">在线</option>
              <option value="离线">离线</option>
              <option value="故障">故障</option>
            </select>
          </div>
          <div class="field">
            <span class="field__label">协议</span>
            <select v-model="protocolFilter" class="select" style="width: 108px">
              <option value="">全部协议</option>
              <option v-for="item in protocols" :key="item" :value="item">{{ item }}</option>
            </select>
          </div>
          <div class="field" style="flex: 1; min-width: 170px">
            <span class="field__label">关键词</span>
            <input v-model="keyword" class="input" placeholder="搜索设备编号 / 名称 / 地块" />
          </div>
          <button class="btn btn--sm" type="button" style="margin-top: 18px" @click="typeFilter = ''; statusFilter = ''; protocolFilter = ''; keyword = ''">重置</button>
          <div class="toolbar__spacer" />
          <span class="tag tag--brand" style="margin-top: 18px">{{ filtered.length }} 台设备</span>
        </div>

        <div class="table-wrap">
          <table class="data-table">
            <thead>
              <tr>
                <th>设备编号</th>
                <th>名称</th>
                <th>类型</th>
                <th>地块</th>
                <th>协议</th>
                <th>状态</th>
                <th>最后心跳</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="device in paged" :key="device.id">
                <td class="cell-strong num">{{ device.id }}</td>
                <td>{{ device.name }}</td>
                <td><span class="tag">{{ device.type }}</span></td>
                <td class="cell-muted">{{ plotName(device.plotId) }}</td>
                <td><span class="tag tag--info">{{ device.protocol }}</span></td>
                <td>
                  <StatusTag :text="device.status" :tone="device.status === '在线' ? 'ok' : device.status === '故障' ? 'danger' : 'mute'" dot />
                </td>
                <td class="num">{{ device.lastSeen }}</td>
                <td>
                  <div class="table-actions">
                    <button class="link-action" type="button" @click="openConfig(device)">配置</button>
                    <button class="link-action" type="button" @click="syncDevice(device)">同步</button>
                    <button class="link-action" type="button" @click="restartDevice(device)">重启</button>
                    <button class="link-action link-action--danger" type="button" @click="deleteTarget = device">移除</button>
                  </div>
                </td>
              </tr>
              <tr v-if="paged.length === 0">
                <td colspan="8">
                  <div class="empty"><span class="empty__mark">空</span>没有符合条件的接入设备</div>
                </td>
              </tr>
            </tbody>
          </table>
          <Pager :total="filtered.length" :page="page" :page-size="pageSize" @update:page="page = $event" />
        </div>
      </div>
    </section>

    <AppModal v-model="addOpen" title="新增设备接入" size="lg">
      <div class="form-grid">
        <label class="field">
          <span class="field__label">设备名称</span>
          <input v-model="addForm.name" class="input" placeholder="如：4号棚环境传感器" />
        </label>
        <label class="field">
          <span class="field__label">设备类型</span>
          <select v-model="addForm.type" class="select">
            <option v-for="type in deviceTypes" :key="type" :value="type">{{ type }}</option>
          </select>
        </label>
        <label class="field">
          <span class="field__label">所属地块</span>
          <select v-model="addForm.plotId" class="select">
            <option v-for="plot in plots" :key="plot.id" :value="plot.id">{{ plot.name }}</option>
          </select>
        </label>
        <label class="field">
          <span class="field__label">接入协议</span>
          <select v-model="addForm.protocol" class="select">
            <option v-for="item in protocols" :key="item" :value="item">{{ item }}</option>
          </select>
        </label>
        <label class="field span-2">
          <span class="field__label">数据 Topic / 寄存器地址</span>
          <input v-model="addForm.topic" class="input" placeholder="如：iot/DEV-401/data 或 40001-40010" />
        </label>
        <label class="field">
          <span class="field__label">采集频率（秒）</span>
          <input v-model.number="addForm.interval" class="input" type="number" min="5" max="3600" />
        </label>
        <label class="field">
          <span class="field__label">备注</span>
          <input v-model="addForm.note" class="input" placeholder="安装位置或用途说明（可选）" />
        </label>
      </div>
      <div class="notice notice--brand" style="margin-top: 14px">
        <span>接入后需校验首条心跳，若 90 秒内未收到数据将自动标记为离线并触发告警。</span>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="addOpen = false">取消</button>
        <button class="btn btn--primary" type="button" @click="createDevice">提交接入</button>
      </template>
    </AppModal>

    <AppModal v-model="configOpen" title="接入参数配置">
      <div v-if="configTarget" class="kv" style="margin-bottom: 14px">
        <div class="kv__item"><span>设备编号</span><b>{{ configTarget.id }}</b></div>
        <div class="kv__item"><span>设备名称</span><b>{{ configTarget.name }}</b></div>
      </div>
      <div class="form-grid">
        <label class="field span-2">
          <span class="field__label">Topic / 寄存器地址</span>
          <input v-model="configForm.topic" class="input" />
        </label>
        <label class="field">
          <span class="field__label">采集频率（秒）</span>
          <input v-model.number="configForm.interval" class="input" type="number" min="5" max="3600" />
        </label>
        <label class="field">
          <span class="field__label">掉线判定（秒）</span>
          <input v-model.number="configForm.timeout" class="input" type="number" min="30" max="600" />
        </label>
      </div>
      <label class="switch" style="margin-top: 14px">
        <input v-model="configForm.filter" type="checkbox" />
        <span class="switch__track" />
        <span>启用异常数据过滤（越界值自动剔除）</span>
      </label>
      <template #footer>
        <button class="btn" type="button" @click="configTarget = null; configOpen = false">取消</button>
        <button class="btn btn--primary" type="button" @click="saveConfig">保存并下发</button>
      </template>
    </AppModal>

    <AppModal v-model="deleteOpen" title="移除设备接入">
      <div class="notice notice--danger">
        <span>移除后该设备将停止数据上报，历史遥测数据保留。此操作不可撤销。</span>
      </div>
      <div class="kv" style="margin-top: 14px">
        <div class="kv__item"><span>设备编号</span><b>{{ deleteTarget?.id }}</b></div>
        <div class="kv__item"><span>设备名称</span><b>{{ deleteTarget?.name }}</b></div>
        <div class="kv__item"><span>协议</span><b>{{ deleteTarget?.protocol }}</b></div>
        <div class="kv__item"><span>最后心跳</span><b>{{ deleteTarget?.lastSeen }}</b></div>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="deleteTarget = null">取消</button>
        <button class="btn btn--danger" type="button" @click="confirmDelete">确认移除</button>
      </template>
    </AppModal>
  </div>
</template>

<style scoped>
.link-action--danger {
  color: var(--danger);
}
</style>
