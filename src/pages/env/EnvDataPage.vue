<script setup lang="ts">
import { computed, ref } from 'vue'
import LineChart from '@/components/ui/LineChart.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import { useToast } from '@/composables/useToast'
import { devices, envLabels, envSeries, plots } from '@/data/mock'
import { formatNumber, nowDateTime } from '@/utils/format'

type MetricKey = 'temperature' | 'humidity'

const toast = useToast()

const selectedPlotId = ref(plots[0]?.id ?? '')
const selectedPlot = computed(() => plots.find((item) => item.id === selectedPlotId.value))
const plotDevices = computed(() => devices.filter((item) => item.plotId === selectedPlotId.value))
const onlineCount = computed(() => plotDevices.value.filter((item) => item.status === '在线').length)

const activeMetric = ref<MetricKey>('temperature')
const updatedAt = ref('2026-11-06 09:42')

const live = ref({
  temperature: [...envSeries.temperature],
  humidity: [...envSeries.humidity],
  soilTemperature: [...envSeries.soilTemperature],
  soilMoisture: [...envSeries.soilMoisture],
  co2: [...envSeries.co2],
  light: [...envSeries.light],
  ph: [...envSeries.ph],
})

function lastValue(list: number[], fallback: number): number {
  return list[list.length - 1] ?? fallback
}

const gauges = computed(() => [
  {
    label: '空气温度',
    value: lastValue(live.value.temperature, 26).toFixed(1),
    unit: '℃',
    note: '适宜范围 18-30℃',
  },
  {
    label: '空气湿度',
    value: String(lastValue(live.value.humidity, 68)),
    unit: '%',
    note: '适宜范围 55-85%',
  },
  {
    label: '土壤湿度',
    value: String(lastValue(live.value.soilMoisture, 50)),
    unit: '%',
    note: '适宜范围 45-65%',
  },
])

const chartSeries = computed(() =>
  activeMetric.value === 'temperature'
    ? [
        { name: '空气温度', color: '#2f8f5b', data: live.value.temperature },
        { name: '土壤温度', color: '#b8862f', data: live.value.soilTemperature },
      ]
    : [
        { name: '空气湿度', color: '#2f6fae', data: live.value.humidity },
        { name: '土壤湿度', color: '#4fae74', data: live.value.soilMoisture },
      ],
)

const chartUnit = computed(() => (activeMetric.value === 'temperature' ? ' ℃' : ' %'))

const indicators = computed(() => [
  { label: 'CO₂ 浓度', value: formatNumber(lastValue(live.value.co2, 440)), unit: 'ppm', note: '适宜 450-600 ppm' },
  { label: '光照强度', value: formatNumber(lastValue(live.value.light, 0)), unit: 'lux', note: '正午峰值 6080 lux' },
  {
    label: '土壤温度',
    value: lastValue(live.value.soilTemperature, 22).toFixed(1),
    unit: '℃',
    note: '根区适宜 20-28℃',
  },
  { label: '土壤 pH', value: lastValue(live.value.ph, 6.4).toFixed(1), unit: 'pH', note: '适宜 6.0-7.0' },
])

function refresh() {
  live.value.temperature = live.value.temperature.map(
    (value) => Math.round((value + (Math.random() - 0.5) * 1.2) * 10) / 10,
  )
  live.value.humidity = live.value.humidity.map((value) => Math.round(value + (Math.random() - 0.5) * 3))
  live.value.soilMoisture = live.value.soilMoisture.map((value) => Math.round(value + (Math.random() - 0.5) * 2))
  live.value.soilTemperature = live.value.soilTemperature.map(
    (value) => Math.round((value + (Math.random() - 0.5) * 0.8) * 10) / 10,
  )
  live.value.co2 = live.value.co2.map((value) => Math.round(value + (Math.random() - 0.5) * 8))
  live.value.light = live.value.light.map((value) => (value > 0 ? Math.round(value + (Math.random() - 0.5) * 80) : 0))
  live.value.ph = live.value.ph.map((value) => Math.round((value + (Math.random() - 0.5) * 0.1) * 10) / 10)
  updatedAt.value = nowDateTime()
  toast.success('环境监测数据已刷新至最新时刻')
}
</script>

<template>
  <div class="mobile-page">
    <header class="page-head">
      <div>
        <h2>环境数据</h2>
        <p>{{ selectedPlot?.name ?? '园区地块' }} · 更新于 {{ updatedAt }}</p>
      </div>
      <button class="mobile-btn mobile-btn--ghost refresh-btn" type="button" @click="refresh">刷新</button>
    </header>

    <label class="mobile-field plot-field">
      <span>选择地块</span>
      <select v-model="selectedPlotId">
        <option v-for="plot in plots" :key="plot.id" :value="plot.id">{{ plot.name }}（{{ plot.crop }}）</option>
      </select>
    </label>

    <div class="gauge-grid">
      <div v-for="item in gauges" :key="item.label" class="mobile-gauge">
        <b class="font-num">{{ item.value }}<small>{{ item.unit }}</small></b>
        <span>{{ item.label }}</span>
        <em class="gauge-note">{{ item.note }}</em>
      </div>
    </div>

    <section class="mobile-section">
      <div class="mobile-section__head">
        <h3>24 小时趋势</h3>
        <div class="mini-tabs">
          <button
            class="mini-tab"
            :class="{ 'is-active': activeMetric === 'temperature' }"
            type="button"
            @click="activeMetric = 'temperature'"
          >
            温度
          </button>
          <button
            class="mini-tab"
            :class="{ 'is-active': activeMetric === 'humidity' }"
            type="button"
            @click="activeMetric = 'humidity'"
          >
            湿度
          </button>
        </div>
      </div>
      <div class="mobile-card">
        <LineChart :labels="envLabels" :series="chartSeries" :unit="chartUnit" :height="200" />
      </div>
    </section>

    <section class="mobile-section">
      <div class="mobile-section__head">
        <h3>环境指标</h3>
        <span>每小时采集</span>
      </div>
      <div class="mobile-card indicator-card">
        <div v-for="item in indicators" :key="item.label" class="mobile-list-item">
          <span class="mobile-icon">测</span>
          <div class="indicator-main">
            <div class="indicator-label">{{ item.label }}</div>
            <div class="indicator-note">{{ item.note }}</div>
          </div>
          <div class="indicator-value font-num">{{ item.value }}<small>{{ item.unit }}</small></div>
        </div>
      </div>
    </section>

    <section class="mobile-section">
      <div class="mobile-section__head">
        <h3>设备在线状态</h3>
        <span class="online-text font-num">{{ onlineCount }}/{{ plotDevices.length }} 在线</span>
      </div>
      <div class="mobile-card">
        <div v-if="plotDevices.length > 0">
          <div v-for="device in plotDevices" :key="device.id" class="mobile-list-item">
            <span class="mobile-icon">设</span>
            <div class="device-main">
              <div class="device-name">{{ device.name }}</div>
              <div class="device-meta">{{ device.type }} · {{ device.protocol }}</div>
            </div>
            <StatusTag
              :text="device.status"
              :tone="device.status === '在线' ? 'ok' : device.status === '故障' ? 'danger' : 'warn'"
              dot
            />
          </div>
        </div>
        <p v-else class="empty-text">该地块暂无接入设备</p>
      </div>
    </section>

    <div class="page-spacer" />
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

.refresh-btn {
  height: 44px;
  padding: 0 14px;
  font-size: 12.5px;
}

.plot-field {
  margin-bottom: 12px;
}

.gauge-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 8px;
}

.mobile-gauge {
  padding: 16px 6px;
}

.gauge-note {
  margin-top: 5px;
  font-size: 9px;
  font-style: normal;
  color: var(--faint);
  text-align: center;
}

.mini-tabs {
  display: flex;
  gap: 5px;
}

.mini-tab {
  height: 44px;
  padding: 0 14px;
  border: 1px solid var(--line);
  border-radius: 22px;
  background: #fff;
  font-size: 11.5px;
  color: var(--muted);
}

.mini-tab.is-active {
  border-color: var(--brand);
  background: var(--brand);
  color: #fff;
}

.indicator-main {
  flex: 1;
  min-width: 0;
}

.indicator-label {
  font-size: 12px;
  font-weight: 600;
  color: var(--ink-2);
}

.indicator-note {
  margin-top: 1px;
  font-size: 10px;
  color: var(--faint);
}

.indicator-value {
  flex: 0 0 auto;
  font-size: 15px;
  color: var(--brand-dark);
}

.indicator-value small {
  margin-left: 2px;
  font-size: 10px;
  color: var(--muted);
}

.online-text {
  font-size: 10.5px;
  color: var(--brand);
}

.device-main {
  flex: 1;
  min-width: 0;
}

.device-name {
  font-size: 12px;
  color: var(--ink-2);
}

.device-meta {
  margin-top: 1px;
  font-size: 10px;
  color: var(--faint);
}

.empty-text {
  padding: 14px 0;
  font-size: 11.5px;
  color: var(--muted);
  text-align: center;
}

.page-spacer {
  height: 24px;
}
</style>
