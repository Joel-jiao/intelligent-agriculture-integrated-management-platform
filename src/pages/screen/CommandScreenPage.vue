<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import GisMap from '@/components/ui/GisMap.vue'
import LineChart from '@/components/ui/LineChart.vue'
import {
  alarms,
  batches,
  devices,
  envLabels,
  envSeries,
  park,
  plotName,
  plots,
  sysInfo,
  waterElectric,
  workOrders,
} from '@/data/mock'
import { formatNumber, pad } from '@/utils/format'

const clock = ref('')
const dateLabel = ref('')
const weekNames = ['日', '一', '二', '三', '四', '五', '六']
let clockTimer = 0

function tick() {
  const date = new Date()
  clock.value = `${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`
  dateLabel.value = `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())} 星期${weekNames[date.getDay()] ?? ''}`
}

const onlineDevices = computed(() => devices.filter((item) => item.status === '在线').length)

const overviewMetrics = computed(() => [
  { label: '种植面积', value: park.area, unit: '亩' },
  { label: '地块数量', value: park.plots, unit: '块' },
  { label: '农户数量', value: park.farmers, unit: '人' },
  { label: '在线设备', value: onlineDevices.value, unit: `/ ${devices.length} 台` },
])

const screenSeries = [
  { name: '空气温度', color: '#7df0ab', data: envSeries.temperature },
  { name: '空气湿度', color: '#6fb7e8', data: envSeries.humidity },
]

const deviceSegments = computed(() => {
  const total = devices.length || 1
  const list = [
    { label: '在线运行', value: devices.filter((item) => item.status === '在线').length },
    { label: '离线', value: devices.filter((item) => item.status === '离线').length },
    { label: '故障', value: devices.filter((item) => item.status === '故障').length },
  ]
  return list.map((item) => ({ ...item, percent: Math.round((item.value / total) * 100) }))
})

const alarmLevels = computed(() =>
  (['紧急', '重要', '一般'] as const).map((level) => ({
    level,
    count: alarms.filter((item) => item.level === level).length,
  })),
)

function levelColor(level: string): string {
  if (level === '紧急') return '#ff6b6b'
  if (level === '重要') return '#ffc94d'
  return '#7db4e6'
}

const activeAlarms = computed(() => alarms.filter((item) => item.status !== '已归档'))

const activeOrders = computed(() => workOrders.filter((item) => item.status !== '已完成').slice(0, 4))

const cropStats = computed(() => {
  const map = new Map<string, number>()
  plots.forEach((plot) => {
    if (plot.status === '休耕') return
    map.set(plot.crop, (map.get(plot.crop) ?? 0) + plot.area)
  })
  const total = Array.from(map.values()).reduce((sum, value) => sum + value, 0) || 1
  return Array.from(map.entries())
    .sort((a, b) => b[1] - a[1])
    .map(([label, value]) => ({
      label,
      value: Math.round(value * 10) / 10,
      percent: Math.round((value / total) * 100),
    }))
})

const traceStats = computed(() => {
  const codeTotal = batches.reduce((sum, item) => sum + item.qrCount, 0)
  const scans = batches.reduce((sum, item) => sum + item.scans, 0)
  return [
    { label: '累计赋码', value: formatNumber(codeTotal), unit: '枚' },
    { label: '扫码访问', value: formatNumber(scans), unit: '次' },
    { label: '今日扫码', value: formatNumber(326), unit: '次' },
    { label: '检测合格率', value: '98.6', unit: '%' },
  ]
})

function lastValue(list: number[], fallback: number): number {
  return list[list.length - 1] ?? fallback
}

const resourceMetrics = computed(() => {
  const water = lastValue(waterElectric.water, 0)
  const electric = lastValue(waterElectric.electric, 0)
  return [
    { label: '本月用水', value: formatNumber(water), unit: 'm³' },
    { label: '本月用电', value: formatNumber(electric), unit: 'kWh' },
    { label: '亩均用水', value: (water / park.area).toFixed(1), unit: 'm³' },
    { label: '亩均用电', value: (electric / park.area).toFixed(1), unit: 'kWh' },
  ]
})

const focusItems = ['园区概览', '环境趋势', 'GIS 地块', '实时告警']
const focusIndex = ref(0)
let focusTimer = 0

onMounted(() => {
  tick()
  clockTimer = window.setInterval(tick, 1000)
  focusTimer = window.setInterval(() => {
    focusIndex.value = (focusIndex.value + 1) % focusItems.length
  }, 4000)
})

onBeforeUnmount(() => {
  window.clearInterval(clockTimer)
  window.clearInterval(focusTimer)
})
</script>

<template>
  <div class="screen-page">
    <header class="screen-head">
      <div class="screen-head__side">
        <b class="font-num">{{ clock }}</b>
        <span>{{ dateLabel }}</span>
      </div>
      <div class="screen-head__title">
        <h1>云岭智慧农业指挥中心</h1>
        <p>YUNLING SMART AGRICULTURE COMMAND CENTER</p>
      </div>
      <div class="screen-head__side screen-head__side--right head-right">
        <div class="online-line">
          在线设备<b class="font-num">{{ onlineDevices }}<small>/{{ devices.length }}</small></b>
        </div>
        <RouterLink to="/portals" class="screen-exit">退出大屏</RouterLink>
      </div>
    </header>

    <div class="screen-grid">
      <div class="screen-col">
        <section class="screen-panel" :class="{ 'is-focus': focusIndex === 0 }">
          <div class="screen-panel__head">
            <h3>园区概览</h3>
            <span>REAL TIME</span>
          </div>
          <div class="screen-metrics">
            <div v-for="item in overviewMetrics" :key="item.label" class="screen-metric">
              <span>{{ item.label }}</span>
              <b class="font-num">{{ formatNumber(item.value) }}<small>{{ item.unit }}</small></b>
            </div>
          </div>
        </section>

        <section class="screen-panel" :class="{ 'is-focus': focusIndex === 1 }">
          <div class="screen-panel__head">
            <h3>环境趋势</h3>
            <span>24H · 1 小时采集</span>
          </div>
          <div class="screen-chart">
            <LineChart :labels="envLabels" :series="screenSeries" unit=" ℃ / %" :height="176" />
          </div>
        </section>

        <section class="screen-panel">
          <div class="screen-panel__head">
            <h3>设备与告警</h3>
            <span>LIVE</span>
          </div>
          <div class="sub-title">设备状态分布</div>
          <div v-for="item in deviceSegments" :key="item.label" class="screen-bar">
            <span class="screen-bar__label">{{ item.label }}</span>
            <div class="screen-bar__track">
              <div class="screen-bar__fill" :style="{ width: `${item.percent}%` }" />
            </div>
            <b class="font-num">{{ item.value }}</b>
          </div>
          <div class="sub-title sub-title--gap">告警级别统计</div>
          <div v-for="item in alarmLevels" :key="item.level" class="screen-list__item">
            <span class="level-label">
              <i class="level-dot" :style="{ background: levelColor(item.level) }" />
              {{ item.level }}告警
            </span>
            <b class="font-num">{{ item.count }} 条</b>
          </div>
        </section>
      </div>

      <div class="screen-col">
        <section class="screen-panel" :class="{ 'is-focus': focusIndex === 2 }">
          <div class="screen-panel__head">
            <h3>园区地块分布</h3>
            <span>GIS · {{ plots.length }} 个地块</span>
          </div>
          <div class="screen-map">
            <GisMap :plots="plots" :devices="devices" :height="360" dark />
          </div>
        </section>

        <section class="screen-panel">
          <div class="screen-panel__head">
            <h3>作物种植分布</h3>
            <span>按种植面积</span>
          </div>
          <div v-for="item in cropStats" :key="item.label" class="screen-bar">
            <span class="screen-bar__label">{{ item.label }}</span>
            <div class="screen-bar__track">
              <div class="screen-bar__fill" :style="{ width: `${item.percent}%` }" />
            </div>
            <b class="font-num">{{ item.percent }}%</b>
          </div>
        </section>
      </div>

      <div class="screen-col">
        <section class="screen-panel" :class="{ 'is-focus': focusIndex === 3 }">
          <div class="screen-panel__head">
            <h3>实时告警</h3>
            <span>{{ activeAlarms.length }} 条未归档</span>
          </div>
          <div v-for="alarm in activeAlarms" :key="alarm.id" class="screen-list__item alarm-item">
            <div class="alarm-left">
              <i class="alarm-dot" :style="{ background: levelColor(alarm.level) }" />
              <div class="alarm-main">
                <div class="alarm-title">{{ alarm.title }}</div>
                <div class="alarm-meta">{{ plotName(alarm.plot) }} · {{ alarm.status }}</div>
              </div>
            </div>
            <time>{{ alarm.createdAt.slice(11) }}</time>
          </div>
        </section>

        <section class="screen-panel">
          <div class="screen-panel__head">
            <h3>农事工单进度</h3>
            <span>进行中 {{ activeOrders.length }} 单</span>
          </div>
          <div v-for="order in activeOrders" :key="order.id" class="screen-bar">
            <span class="screen-bar__label order-label">{{ order.title }}</span>
            <div class="screen-bar__track">
              <div class="screen-bar__fill" :style="{ width: `${order.progress}%` }" />
            </div>
            <b class="font-num">{{ order.progress }}%</b>
          </div>
        </section>

        <section class="screen-panel">
          <div class="screen-panel__head">
            <h3>溯源码扫码统计</h3>
            <span>TRACE</span>
          </div>
          <div class="screen-metrics">
            <div v-for="item in traceStats" :key="item.label" class="screen-metric">
              <span>{{ item.label }}</span>
              <b class="font-num">{{ item.value }}<small>{{ item.unit }}</small></b>
            </div>
          </div>
        </section>

        <section class="screen-panel">
          <div class="screen-panel__head">
            <h3>本月水电指标</h3>
            <span>2026-11</span>
          </div>
          <div class="screen-metrics">
            <div v-for="item in resourceMetrics" :key="item.label" class="screen-metric">
              <span>{{ item.label }}</span>
              <b class="font-num">{{ item.value }}<small>{{ item.unit }}</small></b>
            </div>
          </div>
        </section>
      </div>
    </div>

    <footer class="screen-foot">
      <span class="font-num">数据更新于 {{ clock }}</span>
      <span class="focus-tip">轮播中 {{ focusIndex + 1 }}/{{ focusItems.length }} · {{ focusItems[focusIndex] ?? '' }}</span>
      <span>云岭智慧农业 · 指挥中心大屏 {{ sysInfo.version }}</span>
    </footer>
  </div>
</template>

<style scoped>
.font-num {
  font-family: var(--font-num);
}

.screen-page {
  padding-bottom: 14px;
  overflow-y: auto;
}

.head-right {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 6px;
}

.online-line {
  font-size: 11px;
  color: rgba(180, 240, 205, 0.62);
}

.online-line b {
  display: inline-block;
  margin-left: 5px;
  font-size: 16px;
  color: #7df0ab;
}

.online-line b small {
  font-size: 10px;
  font-weight: 400;
  color: rgba(180, 240, 205, 0.5);
}

.screen-chart :deep(.axis-text) {
  fill: rgba(160, 235, 190, 0.58);
}

.screen-chart :deep(.line-chart__legend) {
  color: rgba(200, 247, 221, 0.65);
  font-size: 10.5px;
}

.screen-chart :deep(.line-chart__canvas svg line) {
  stroke: rgba(90, 220, 150, 0.14);
}

.screen-chart :deep(.line-chart__tip) {
  background: rgba(10, 34, 22, 0.94);
  border: 1px solid rgba(90, 220, 150, 0.24);
}

.sub-title {
  margin-bottom: 9px;
  font-size: 10.5px;
  letter-spacing: 1px;
  color: rgba(160, 235, 190, 0.48);
}

.sub-title--gap {
  margin-top: 12px;
  padding-top: 10px;
  border-top: 1px dashed rgba(90, 220, 150, 0.13);
}

.level-label {
  display: flex;
  align-items: center;
  gap: 7px;
  font-size: 11.5px;
  color: rgba(216, 245, 228, 0.82);
}

.screen-list__item b {
  color: #a7f3c5;
}

.level-dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
}

.alarm-item {
  align-items: flex-start;
}

.alarm-left {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  flex: 1;
  min-width: 0;
}

.alarm-dot {
  flex: 0 0 auto;
  width: 6px;
  height: 6px;
  margin-top: 5px;
  border-radius: 50%;
}

.alarm-main {
  flex: 1;
  min-width: 0;
}

.alarm-title {
  overflow: hidden;
  font-size: 11.5px;
  color: rgba(216, 245, 228, 0.9);
  text-overflow: ellipsis;
  white-space: nowrap;
}

.alarm-meta {
  margin-top: 1px;
  font-size: 9.5px;
  color: rgba(180, 240, 205, 0.42);
}

.order-label {
  width: 112px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.screen-panel {
  transition: border-color 0.4s ease, box-shadow 0.4s ease;
}

.screen-panel.is-focus {
  border-color: rgba(125, 240, 171, 0.55);
  box-shadow: 0 0 18px rgba(85, 230, 154, 0.16), inset 0 0 26px rgba(40, 160, 100, 0.12);
}

.screen-panel.is-focus::before {
  width: 90px;
  box-shadow: 0 0 16px #55e69a;
}

.focus-tip {
  padding: 2px 10px;
  border: 1px solid rgba(90, 220, 150, 0.28);
  border-radius: 10px;
  color: #7df0ab;
}

.screen-foot {
  gap: 14px;
}
</style>
