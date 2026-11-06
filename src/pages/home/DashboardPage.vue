<script setup lang="ts">
import { computed, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import LineChart from '@/components/ui/LineChart.vue'
import DonutChart from '@/components/ui/DonutChart.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import { useToast } from '@/composables/useToast'
import { alarms, devices, envLabels, envSeries, park, plots, weather, workOrders } from '@/data/mock'
import { buildCsv, downloadText, formatNumber } from '@/utils/format'

const toast = useToast()

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

const onlineDevices = computed(() => devices.filter((item) => item.status === '在线').length)
const pendingAlarms = computed(() => alarms.filter((item) => item.status !== '已归档').length)
const activeOrders = computed(() => workOrders.filter((item) => item.status === '进行中' || item.status === '待接单').length)

const deviceSegments = computed(() => [
  { label: '在线运行', value: devices.filter((item) => item.status === '在线').length, color: '#2f9e5b' },
  { label: '离线', value: devices.filter((item) => item.status === '离线').length, color: '#c47f17' },
  { label: '故障', value: devices.filter((item) => item.status === '故障').length, color: '#c93e3e' },
])

const latestAlarms = computed(() => alarms.slice(0, 5))
const activeOrderList = computed(() => workOrders.filter((item) => item.status !== '已完成').slice(0, 4))

const plotProgress = computed(() =>
  plots.map((plot, index) => ({
    ...plot,
    progress: [78, 56, 92, 64, 85, 32][index] ?? 50,
  })),
)

function refresh() {
  liveSeries.value.temperature = liveSeries.value.temperature.map((value) => Math.round((value + (Math.random() - 0.5) * 1.4) * 10) / 10)
  liveSeries.value.humidity = liveSeries.value.humidity.map((value) => Math.round(value + (Math.random() - 0.5) * 3))
  toast.success('环境监测数据已刷新至最新时刻')
}

function exportReport() {
  const rows = plots.map((plot) => [plot.code, plot.name, plot.crop, plot.area, plot.stage, plot.status, plot.manager])
  downloadText('园区综合日报_20261106.csv', buildCsv(['地块编号', '地块名称', '作物', '面积(亩)', '生育期', '状态', '负责人'], rows))
  toast.success('综合日报已导出为 CSV 文件')
}
</script>

<template>
  <div>
    <PageHeader eyebrow="DASHBOARD" title="综合数据看板" description="园区环境、设备、告警与农事进度一屏总览 · 数据更新于 2026-11-06 09:42">
      <template #actions>
        <button class="btn" type="button" @click="refresh">刷新数据</button>
        <button class="btn btn--primary" type="button" @click="exportReport">导出日报</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="园区种植总面积" :value="park.area" unit="亩" icon="地" note="6 个地块 · 3 座温室" trend="+2.4% 环比" />
      <StatCard label="在线设备" :value="`${onlineDevices}/${devices.length}`" icon="设" note="网关与传感器在线" trend="在线率 90%" />
      <StatCard label="待处置告警" :value="pendingAlarms" unit="条" icon="警" note="紧急 1 条 · 重要 2 条" trend="较昨日 -3" trend-up />
      <StatCard label="进行中工单" :value="activeOrders" unit="单" icon="工" note="今日新增 4 单" trend="按时完成率 96%" accent />
    </div>

    <div class="grid grid--main">
      <div class="stack">
        <section class="card">
          <div class="card__head">
            <div class="card__title">
              24 小时环境趋势
              <span class="card__sub">1号智能大棚 · 采集间隔 1 小时</span>
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
            <LineChart :labels="envLabels" :series="chartSeries" :unit="chartUnit" :height="232" />
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">各地块生长进度 <span class="card__sub">按作物生育期折算</span></div>
            <RouterLink class="link-action" to="/farm/plots">查看地块档案</RouterLink>
          </div>
          <div class="card__body" style="display: grid; gap: 12px">
            <div v-for="plot in plotProgress" :key="plot.id" class="progress-row">
              <span style="width: 98px; color: var(--ink-2)">{{ plot.name }}</span>
              <span class="tag" :class="plot.status === '预警' ? 'tag--warn' : 'tag--brand'" style="width: 52px; justify-content: center">{{ plot.crop }}</span>
              <div class="progress">
                <div class="progress__bar" :class="{ 'progress__bar--warn': plot.progress < 50 }" :style="{ width: `${plot.progress}%` }" />
              </div>
              <b>{{ plot.progress }}%</b>
            </div>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">农事工单动态</div>
            <RouterLink class="link-action" to="/farm/work-orders">全部工单</RouterLink>
          </div>
          <div class="table-wrap" style="border: 0; border-radius: 0 0 14px 14px">
            <table class="data-table">
              <thead>
                <tr>
                  <th>工单编号</th>
                  <th>任务</th>
                  <th>负责人</th>
                  <th>截止时间</th>
                  <th>状态</th>
                  <th>进度</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="order in activeOrderList" :key="order.id">
                  <td><RouterLink class="cell-strong" :to="`/farm/work-orders/${order.id}`">{{ order.id }}</RouterLink></td>
                  <td>{{ order.title }}</td>
                  <td>{{ order.assignee }}</td>
                  <td class="num">{{ order.deadline }}</td>
                  <td>
                    <StatusTag :text="order.status" :tone="order.status === '进行中' ? 'brand' : order.status === '待接单' ? 'warn' : 'info'" dot />
                  </td>
                  <td>
                    <div class="progress" style="width: 90px">
                      <div class="progress__bar" :style="{ width: `${order.progress}%` }" />
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>
      </div>

      <div class="stack">
        <section class="card card--tint">
          <div class="card__head">
            <div class="card__title">园区气象</div>
            <span class="tag tag--brand">实况</span>
          </div>
          <div class="card__body">
            <div class="row row--between">
              <div>
                <div style="font-size: 34px; font-weight: 700; letter-spacing: -1px">{{ weather.temperature }}<small style="font-size: 14px">℃</small></div>
                <div style="font-size: 12px; color: var(--muted)">{{ weather.condition }} · {{ weather.wind }}</div>
              </div>
              <div style="text-align: right; font-size: 11.5px; color: var(--muted); line-height: 1.9">
                <div>湿度 {{ weather.humidity }}%</div>
                <div>降雨 {{ weather.rainfall }} mm</div>
                <div>适宜度 良好</div>
              </div>
            </div>
            <div class="weather-forecast">
              <div v-for="item in weather.forecast" :key="item.day" class="weather-forecast__item">
                <span>{{ item.day }}</span>
                <b>{{ item.icon }}</b>
                <small>{{ item.high }}° / {{ item.low }}°</small>
              </div>
            </div>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">设备运行状态</div>
            <RouterLink class="link-action" to="/iot/devices">设备明细</RouterLink>
          </div>
          <div class="card__body">
            <DonutChart
              :segments="deviceSegments"
              :size="140"
              :center-value="`${onlineDevices}`"
              center-label="在线设备"
            />
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">最新告警</div>
            <RouterLink class="link-action" to="/alarms">处理告警</RouterLink>
          </div>
          <div class="card__body" style="padding-top: 6px">
            <div v-for="alarm in latestAlarms" :key="alarm.id" class="alarm-row">
              <span class="tag" :class="alarm.level === '紧急' ? 'tag--danger' : alarm.level === '重要' ? 'tag--warn' : 'tag--info'">{{ alarm.level }}</span>
              <div style="flex: 1; min-width: 0">
                <div class="alarm-row__title">{{ alarm.title }}</div>
                <div class="alarm-row__meta">{{ alarm.plot }} · {{ alarm.createdAt }}</div>
              </div>
              <span class="dot" :class="alarm.status === '已归档' ? 'dot--ok' : 'dot--warn'" />
            </div>
          </div>
        </section>
      </div>
    </div>

    <section class="card" style="margin-top: 16px">
      <div class="card__head">
        <div class="card__title">园区核心指标 <span class="card__sub">2026 年 11 月累计</span></div>
        <RouterLink class="link-action" to="/reports">综合报表</RouterLink>
      </div>
      <div class="card__body">
        <div class="kv kv--3">
          <div class="kv__item"><span>本月用水量</span><b>{{ formatNumber(1260) }} m³</b></div>
          <div class="kv__item"><span>本月用电量</span><b>{{ formatNumber(3120) }} kWh</b></div>
          <div class="kv__item"><span>本月采收重量</span><b>{{ formatNumber(6820) }} kg</b></div>
          <div class="kv__item"><span>溯源码生成</span><b>{{ formatNumber(6180) }} 枚</b></div>
          <div class="kv__item"><span>溯源扫码访问</span><b>{{ formatNumber(1677) }} 次</b></div>
          <div class="kv__item"><span>平均检测合格率</span><b>98.6%</b></div>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.weather-forecast {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
  margin-top: 16px;
}

.weather-forecast__item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  padding: 9px 6px;
  border-radius: 9px;
  background: rgba(255, 255, 255, 0.7);
  border: 1px solid var(--line);
}

.weather-forecast__item span {
  font-size: 10.5px;
  color: var(--muted);
}

.weather-forecast__item b {
  font-size: 16px;
  color: var(--ink);
}

.weather-forecast__item small {
  font-size: 10px;
  color: var(--faint);
  font-family: var(--font-num);
}

.alarm-row {
  display: flex;
  align-items: center;
  gap: 9px;
  padding: 10px 0;
  border-bottom: 1px dashed var(--line);
}

.alarm-row:last-child {
  border-bottom: 0;
}

.alarm-row__title {
  overflow: hidden;
  font-size: 12px;
  color: var(--ink-2);
  text-overflow: ellipsis;
  white-space: nowrap;
}

.alarm-row__meta {
  margin-top: 1px;
  font-size: 10.5px;
  color: var(--faint);
}
</style>
