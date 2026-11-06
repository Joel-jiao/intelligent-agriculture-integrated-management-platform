<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import LineChart from '@/components/ui/LineChart.vue'
import AppModal from '@/components/ui/AppModal.vue'
import Pager from '@/components/ui/Pager.vue'
import { useToast } from '@/composables/useToast'
import { devices, envLabels, envSeries, plotName, plots } from '@/data/mock'
import { buildCsv, downloadText, formatNumber, today } from '@/utils/format'

const toast = useToast()

const selectedPlot = ref('P-01')
const selectedDevice = ref('DEV-201')
const selectedDate = ref(today())
const sensorDevices = computed(() => devices.filter((item) => item.type === '传感器'))

const metrics = [
  { key: 'temperature', label: '空气温湿度' },
  { key: 'soil', label: '土壤墒情' },
  { key: 'co2', label: 'CO₂ 与光照' },
  { key: 'water', label: '水体环境' },
] as const

type MetricKey = (typeof metrics)[number]['key']
const activeMetric = ref<MetricKey>('temperature')

const liveSeries = ref({
  temperature: [...envSeries.temperature],
  humidity: [...envSeries.humidity],
  soilTemperature: [...envSeries.soilTemperature],
  soilMoisture: [...envSeries.soilMoisture],
  co2: [...envSeries.co2],
  light: [...envSeries.light],
  waterTemperature: [...envSeries.waterTemperature],
  ph: [...envSeries.ph],
})

function lastOf(list: number[], digits = 0): number {
  const value = list.length > 0 ? list[list.length - 1] ?? 0 : 0
  const base = 10 ** digits
  return Math.round(value * base) / base
}

interface CurrentStat {
  label: string
  value: number
  unit: string
  icon: string
  note: string
  accent?: boolean
}

const currentStats = computed<CurrentStat[]>(() => [
  { label: '空气温度', value: lastOf(liveSeries.value.temperature, 1), unit: '℃', icon: '温', note: '适宜 18 - 30℃' },
  { label: '空气湿度', value: lastOf(liveSeries.value.humidity), unit: '%', icon: '湿', note: '适宜 55% - 85%' },
  { label: '土壤温度', value: lastOf(liveSeries.value.soilTemperature, 1), unit: '℃', icon: '土', note: '适宜 20 - 28℃' },
  { label: '土壤湿度', value: lastOf(liveSeries.value.soilMoisture), unit: '%', icon: '墒', note: '下限 40%' },
  { label: 'CO₂ 浓度', value: lastOf(liveSeries.value.co2), unit: 'ppm', icon: '碳', note: '适宜 450 - 600 ppm' },
  { label: '光照强度', value: lastOf(liveSeries.value.light), unit: 'lux', icon: '光', note: '峰值 6080 lux' },
  { label: '水体 pH', value: lastOf(liveSeries.value.ph, 1), unit: 'pH', icon: 'pH', note: '适宜 6.0 - 7.0' },
  { label: '水温', value: lastOf(liveSeries.value.waterTemperature, 1), unit: '℃', icon: '水', note: '适宜 18 - 24℃', accent: true },
])

const chartSeries = computed(() => {
  if (activeMetric.value === 'temperature') {
    return [
      { name: '空气温度', color: '#2f8f5b', data: liveSeries.value.temperature },
      { name: '空气湿度', color: '#7ba6d9', data: liveSeries.value.humidity },
    ]
  }
  if (activeMetric.value === 'soil') {
    return [
      { name: '土壤温度', color: '#b8862f', data: liveSeries.value.soilTemperature },
      { name: '土壤湿度', color: '#4fae74', data: liveSeries.value.soilMoisture },
    ]
  }
  if (activeMetric.value === 'co2') {
    return [
      { name: 'CO₂ 浓度', color: '#2f6fae', data: liveSeries.value.co2 },
      { name: '光照强度', color: '#c9973f', data: liveSeries.value.light },
    ]
  }
  return [
    { name: '水温', color: '#2f6fae', data: liveSeries.value.waterTemperature },
    { name: 'pH 值', color: '#7a5cae', data: liveSeries.value.ph },
  ]
})

const chartUnit = computed(() => {
  if (activeMetric.value === 'temperature') return ' ℃ / %'
  if (activeMetric.value === 'soil') return ' ℃ / %'
  if (activeMetric.value === 'co2') return ' ppm / lux'
  return ' ℃ / pH'
})

const tableRows = computed(() =>
  envLabels.map((label, index) => ({
    label,
    temperature: liveSeries.value.temperature[index] ?? 0,
    humidity: liveSeries.value.humidity[index] ?? 0,
    soilTemperature: liveSeries.value.soilTemperature[index] ?? 0,
    soilMoisture: liveSeries.value.soilMoisture[index] ?? 0,
    co2: liveSeries.value.co2[index] ?? 0,
    light: liveSeries.value.light[index] ?? 0,
  })),
)

const pageSize = 8
const page = ref(1)
const pagedRows = computed(() => {
  const start = (page.value - 1) * pageSize
  return tableRows.value.slice(start, start + pageSize)
})

function applyFilters() {
  page.value = 1
  toast.info(`已切换至「${plotName(selectedPlot.value)}」 · ${selectedDate.value} 监测数据`)
}

function jitter(list: number[], step: number, digits = 0): number[] {
  const base = 10 ** digits
  return list.map((value) => Math.round((value + (Math.random() - 0.5) * step) * base) / base)
}

function refreshData() {
  liveSeries.value.temperature = jitter(liveSeries.value.temperature, 1.4, 1)
  liveSeries.value.humidity = jitter(liveSeries.value.humidity, 4)
  liveSeries.value.soilTemperature = jitter(liveSeries.value.soilTemperature, 0.8, 1)
  liveSeries.value.soilMoisture = jitter(liveSeries.value.soilMoisture, 3)
  liveSeries.value.co2 = jitter(liveSeries.value.co2, 18)
  liveSeries.value.light = jitter(liveSeries.value.light, 90)
  liveSeries.value.waterTemperature = jitter(liveSeries.value.waterTemperature, 0.6, 1)
  liveSeries.value.ph = jitter(liveSeries.value.ph, 0.1, 1)
  toast.success('24 小时环境数据已刷新至最新采集时刻')
}

function exportCsv() {
  const rows = tableRows.value.map((row) => [
    row.label,
    row.temperature,
    row.humidity,
    row.soilTemperature,
    row.soilMoisture,
    row.co2,
    row.light,
  ])
  downloadText(
    `环境监测数据_${selectedDate.value}.csv`,
    buildCsv(['时间', '温度(℃)', '湿度(%)', '土壤温度(℃)', '土壤湿度(%)', 'CO₂(ppm)', '光照(lux)'], rows),
  )
  toast.success('环境监测数据已导出为 CSV 文件')
}

const thresholdOpen = ref(false)
const thresholds = reactive({
  tempMax: 32,
  tempMin: 16,
  humidityMax: 85,
  humidityMin: 50,
  soilMin: 40,
  co2Max: 600,
})

function saveThresholds() {
  if (thresholds.tempMax <= thresholds.tempMin) {
    toast.error('温度上限必须大于下限')
    return
  }
  if (thresholds.humidityMax <= thresholds.humidityMin) {
    toast.error('湿度上限必须大于下限')
    return
  }
  thresholdOpen.value = false
  toast.success('阈值设置已保存，并同步至采集网关')
}

const currentPlot = computed(() => plots.find((item) => item.id === selectedPlot.value))
const currentDevice = computed(() => sensorDevices.value.find((item) => item.id === selectedDevice.value))
</script>

<template>
  <div>
    <PageHeader
      eyebrow="IOT · ENVIRONMENT"
      title="环境数据监测"
      description="温室环境要素实时采集与趋势分析 · 采集间隔 1 小时 · 数据更新于 2026-11-06 09:42"
    >
      <template #actions>
        <button class="btn" type="button" @click="thresholdOpen = true">阈值设置</button>
        <button class="btn" type="button" @click="refreshData">刷新数据</button>
        <button class="btn btn--primary" type="button" @click="exportCsv">导出 CSV</button>
      </template>
    </PageHeader>

    <div class="toolbar">
      <div class="field">
        <span class="field__label">监测地块</span>
        <select v-model="selectedPlot" class="select" style="width: 160px">
          <option v-for="plot in plots" :key="plot.id" :value="plot.id">{{ plot.name }}</option>
        </select>
      </div>
      <div class="field">
        <span class="field__label">采集设备</span>
        <select v-model="selectedDevice" class="select" style="width: 180px">
          <option v-for="device in sensorDevices" :key="device.id" :value="device.id">{{ device.name }}</option>
        </select>
      </div>
      <div class="field">
        <span class="field__label">监测日期</span>
        <input v-model="selectedDate" class="input" type="date" style="width: 160px" />
      </div>
      <button class="btn btn--primary" type="button" @click="applyFilters">查询数据</button>
      <div class="toolbar__spacer" />
      <span class="tag tag--ok"><i class="dot dot--ok" />采集正常</span>
      <span class="tag tag--info">数据完整率 99.2%</span>
    </div>

    <div class="stat-grid">
      <StatCard
        v-for="item in currentStats"
        :key="item.label"
        :label="item.label"
        :value="item.value"
        :unit="item.unit"
        :icon="item.icon"
        :note="item.note"
        :accent="item.accent"
      />
    </div>

    <div class="grid grid--main">
      <section class="card">
        <div class="card__head">
          <div class="card__title">
            24 小时环境趋势
            <span class="card__sub">{{ currentPlot?.name ?? '—' }} · {{ selectedDate }}</span>
          </div>
          <div class="tabs">
            <button
              v-for="item in metrics"
              :key="item.key"
              class="tab"
              :class="{ 'tab--active': activeMetric === item.key }"
              type="button"
              @click="activeMetric = item.key"
            >
              {{ item.label }}
            </button>
          </div>
        </div>
        <div class="card__body">
          <LineChart :labels="envLabels" :series="chartSeries" :unit="chartUnit" :height="250" />
        </div>
      </section>

      <div class="stack">
        <section class="card card--tint">
          <div class="card__head">
            <div class="card__title">采集点位</div>
            <span class="tag tag--brand">实时在线</span>
          </div>
          <div class="card__body">
            <div class="kv">
              <div class="kv__item"><span>所属地块</span><b>{{ currentPlot?.name ?? '—' }}</b></div>
              <div class="kv__item"><span>采集设备</span><b>{{ currentDevice?.name ?? '—' }}</b></div>
              <div class="kv__item"><span>设备编号</span><b>{{ currentDevice?.id ?? '—' }}</b></div>
              <div class="kv__item"><span>通信协议</span><b>{{ currentDevice?.protocol ?? '—' }}</b></div>
              <div class="kv__item"><span>采集间隔</span><b>1 小时</b></div>
              <div class="kv__item"><span>最后上报</span><b>{{ currentDevice?.lastSeen ?? '—' }}</b></div>
            </div>
            <div class="notice notice--brand" style="margin-top: 14px">
              当前点位阈值：温度 {{ thresholds.tempMin }} - {{ thresholds.tempMax }}℃ · 湿度 {{ thresholds.humidityMin }}% -
              {{ thresholds.humidityMax }}% · 土壤湿度下限 {{ thresholds.soilMin }}%
            </div>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">今日监测摘要</div>
          </div>
          <div class="card__body">
            <div class="kv">
              <div class="kv__item"><span>温度峰值</span><b>{{ lastOf(liveSeries.temperature, 1) }} ℃</b></div>
              <div class="kv__item"><span>湿度均值</span><b>{{ Math.round(liveSeries.humidity.reduce((sum, value) => sum + value, 0) / liveSeries.humidity.length) }} %</b></div>
              <div class="kv__item"><span>光合有效时段</span><b>07:00 - 18:00</b></div>
              <div class="kv__item"><span>数据条数</span><b>{{ tableRows.length }} 条</b></div>
            </div>
          </div>
        </section>
      </div>
    </div>

    <section class="card" style="margin-top: 16px">
      <div class="card__head">
        <div class="card__title">
          24 小时明细数据
          <span class="card__sub">{{ currentPlot?.name ?? '—' }} · {{ selectedDate }}</span>
        </div>
        <div class="row">
          <button class="link-action" type="button" @click="refreshData">刷新</button>
          <button class="link-action" type="button" @click="exportCsv">导出</button>
        </div>
      </div>
      <div class="table-wrap" style="border: 0; border-radius: 0">
        <table class="data-table">
          <thead>
            <tr>
              <th>时间</th>
              <th>温度 (℃)</th>
              <th>湿度 (%)</th>
              <th>土壤温度 (℃)</th>
              <th>土壤湿度 (%)</th>
              <th>CO₂ (ppm)</th>
              <th>光照 (lux)</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in pagedRows" :key="row.label">
              <td class="num cell-strong">{{ row.label }}</td>
              <td class="num">{{ row.temperature }}</td>
              <td class="num">{{ row.humidity }}</td>
              <td class="num">{{ row.soilTemperature }}</td>
              <td class="num">{{ row.soilMoisture }}</td>
              <td class="num">{{ formatNumber(row.co2) }}</td>
              <td class="num">{{ formatNumber(row.light) }}</td>
            </tr>
            <tr v-if="pagedRows.length === 0">
              <td colspan="7">
                <div class="empty">当前筛选条件下暂无环境数据</div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <Pager :total="tableRows.length" :page="page" :page-size="pageSize" @update:page="page = $event" />
    </section>

    <AppModal v-model="thresholdOpen" title="环境阈值设置" size="lg">
      <div class="notice">
        阈值将应用于 {{ currentPlot?.name ?? '当前地块' }}，超过上下限时系统自动生成环境告警。
      </div>
      <div class="form-grid" style="margin-top: 14px">
        <div class="field">
          <span class="field__label">空气温度下限（℃）</span>
          <input v-model.number="thresholds.tempMin" class="input" type="number" />
        </div>
        <div class="field">
          <span class="field__label">空气温度上限（℃）</span>
          <input v-model.number="thresholds.tempMax" class="input" type="number" />
        </div>
        <div class="field">
          <span class="field__label">空气湿度下限（%）</span>
          <input v-model.number="thresholds.humidityMin" class="input" type="number" />
        </div>
        <div class="field">
          <span class="field__label">空气湿度上限（%）</span>
          <input v-model.number="thresholds.humidityMax" class="input" type="number" />
        </div>
        <div class="field">
          <span class="field__label">土壤湿度下限（%）</span>
          <input v-model.number="thresholds.soilMin" class="input" type="number" />
        </div>
        <div class="field">
          <span class="field__label">CO₂ 浓度上限（ppm）</span>
          <input v-model.number="thresholds.co2Max" class="input" type="number" />
        </div>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="thresholdOpen = false">取消</button>
        <button class="btn btn--primary" type="button" @click="saveThresholds">保存阈值</button>
      </template>
    </AppModal>
  </div>
</template>

<style scoped>
.kv + .kv {
  margin-top: 12px;
}
</style>
