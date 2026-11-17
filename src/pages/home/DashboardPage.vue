<script setup lang="ts">
import { computed, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import LineChart from '@/components/ui/LineChart.vue'
import DonutChart from '@/components/ui/DonutChart.vue'
import { useToast } from '@/composables/useToast'
import { alarms, devices, envLabels, envSeries, park, plots, workOrders } from '@/api/store'
import { buildCsv, downloadText, formatNumber } from '@/utils/format'

const toast = useToast()

const today = '2026-11-06'

const metrics = [
  { key: 'temperature', label: '空气温度' },
  { key: 'humidity', label: '空气湿度' },
  { key: 'soil', label: '土壤水分' },
  { key: 'light', label: '光照强度' },
] as const

type MetricKey = (typeof metrics)[number]['key']
const activeMetric = ref<MetricKey>('temperature')
const liveSeries = ref({
  temperature: [...envSeries.temperature],
  humidity: [...envSeries.humidity],
  soilMoisture: [...envSeries.soilMoisture],
  light: [...envSeries.light],
})

const chartSeries = computed(() => {
  if (activeMetric.value === 'humidity') {
    return [{ name: '空气湿度', color: '#34c759', data: liveSeries.value.humidity }]
  }
  if (activeMetric.value === 'soil') {
    return [{ name: '土壤水分', color: '#5e5ce6', data: liveSeries.value.soilMoisture }]
  }
  if (activeMetric.value === 'light') {
    return [{ name: '光照强度', color: '#ff9f0a', data: liveSeries.value.light }]
  }
  return [{ name: '空气温度', color: '#007aff', data: liveSeries.value.temperature }]
})

const chartUnit = computed(() => {
  if (activeMetric.value === 'humidity') return ' %'
  if (activeMetric.value === 'soil') return ' %'
  if (activeMetric.value === 'light') return ' lux'
  return ' ℃'
})

const onlineDevices = computed(() => devices.filter((item) => item.status === '在线').length)
const onlineRate = computed(() => Math.round((onlineDevices.value / devices.length) * 100))
const todayAlarms = computed(() => alarms.filter((item) => item.createdAt.startsWith(today)))
const healthyPlots = computed(() => plots.filter((item) => item.status === '正常').length)
const healthyRate = computed(() => Math.round((healthyPlots.value / plots.length) * 100))

const deviceSegments = computed(() => [
  { label: '在线', value: devices.filter((item) => item.status === '在线').length, color: '#34c759' },
  { label: '离线', value: devices.filter((item) => item.status === '离线').length, color: '#c7c7cc' },
  { label: '故障', value: devices.filter((item) => item.status === '故障').length, color: '#ff3b30' },
])

const latestAlarms = computed(() => alarms.slice(0, 4))
const todayTasks = computed(() => workOrders.filter((item) => item.deadline.startsWith(today)).slice(0, 4))

function alarmTone(level: string): 'ok' | 'warn' | 'danger' {
  if (level === '紧急') return 'danger'
  if (level === '重要') return 'warn'
  return 'ok'
}

function alarmLabel(level: string): string {
  if (level === '紧急') return '异常'
  if (level === '重要') return '预警'
  return '正常'
}

function taskTone(status: string): 'ok' | 'warn' | 'brand' | 'mute' {
  if (status === '已完成') return 'ok'
  if (status === '进行中') return 'brand'
  if (status === '待接单') return 'warn'
  return 'mute'
}

function refresh() {
  liveSeries.value.temperature = liveSeries.value.temperature.map(
    (value) => Math.round((value + (Math.random() - 0.5) * 1.4) * 10) / 10,
  )
  liveSeries.value.humidity = liveSeries.value.humidity.map((value) => Math.round(value + (Math.random() - 0.5) * 3))
  toast.success('环境监测数据已刷新至最新时刻')
}

function exportReport() {
  const rows = plots.map((plot) => [plot.code, plot.name, plot.crop, plot.area, plot.stage, plot.status, plot.manager])
  downloadText(
    '园区综合日报_20261106.csv',
    buildCsv(['地块编号', '地块名称', '作物', '面积(亩)', '生育期', '状态', '负责人'], rows),
  )
  toast.success('综合日报已导出为 CSV 文件')
}
</script>

<template>
  <div class="dashboard">
    <PageHeader title="智慧农业管理平台" description="园区环境、设备、告警与农事进度总览 · 数据更新于 2026-11-06 09:42">
      <template #actions>
        <button class="btn" type="button" @click="refresh">刷新数据</button>
        <button class="btn btn--primary" type="button" @click="exportReport">导出日报</button>
      </template>
    </PageHeader>

    <!-- 第一行：KPI -->
    <div class="kpi-row">
      <section class="kpi">
        <div class="kpi__label">农田总面积</div>
        <div class="kpi__value">{{ formatNumber(park.area) }}<small>亩</small></div>
        <div class="kpi__meta">{{ plots.length }} 个地块 · 3 座温室</div>
      </section>
      <section class="kpi">
        <div class="kpi__label">在线设备数</div>
        <div class="kpi__value">{{ onlineDevices }}<small>/ {{ devices.length }} 台</small></div>
        <div class="kpi__meta">设备在线率 {{ onlineRate }}%</div>
      </section>
      <section class="kpi">
        <div class="kpi__label">今日告警</div>
        <div class="kpi__value">{{ todayAlarms.length }}<small>条</small></div>
        <div class="kpi__meta">异常 1 条 · 预警 2 条</div>
      </section>
      <section class="kpi">
        <div class="kpi__label">作物生长良好率</div>
        <div class="kpi__value">{{ healthyRate }}<small>%</small></div>
        <div class="kpi__meta">{{ healthyPlots }} / {{ plots.length }} 个地块长势正常</div>
      </section>
    </div>

    <!-- 第二行：趋势 + 设备状态 -->
    <div class="grid grid--main dashboard__row">
      <section class="card">
        <div class="card__head">
          <div class="card__title">
            环境趋势
            <span class="card__sub">24 小时 · 采集间隔 1 小时</span>
          </div>
          <div class="card__head-right">
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
        </div>
        <div class="card__body">
          <LineChart :labels="envLabels" :series="chartSeries" :unit="chartUnit" :height="236" />
        </div>
      </section>

      <section class="card">
        <div class="card__head">
          <div class="card__title">设备状态</div>
          <RouterLink class="link-action" to="/iot/devices">查看全部</RouterLink>
        </div>
        <div class="card__body">
          <DonutChart
            :segments="deviceSegments"
            :size="148"
            :center-value="`${onlineDevices}`"
            center-label="在线设备"
          />
          <div class="device-foot">
            <span>网关 <b>1 / 1</b> 在线</span>
            <span>最后同步 09:42</span>
          </div>
        </div>
      </section>
    </div>

    <!-- 第三行：告警 + 任务 -->
    <div class="grid grid--2">
      <section class="card">
        <div class="card__head">
          <div class="card__title">
            最近告警
            <span class="card__sub">{{ todayAlarms.length }} 条待处理</span>
          </div>
          <RouterLink class="link-action" to="/alarms">查看全部</RouterLink>
        </div>
        <div class="card__body card__body--list">
          <RouterLink v-for="alarm in latestAlarms" :key="alarm.id" to="/alarms" class="alarm-row">
            <span class="pill" :class="`pill--${alarmTone(alarm.level)}`">
              <i class="dot" :class="`dot--${alarmTone(alarm.level)}`" />
              {{ alarmLabel(alarm.level) }}
            </span>
            <div class="alarm-row__main">
              <div class="alarm-row__title">{{ alarm.title }}</div>
              <div class="alarm-row__meta">{{ alarm.plot }} · {{ alarm.createdAt }}</div>
            </div>
            <span class="alarm-row__value">{{ alarm.value }}</span>
          </RouterLink>
        </div>
      </section>

      <section class="card">
        <div class="card__head">
          <div class="card__title">
            今日农事任务
            <span class="card__sub">{{ todayTasks.length }} 项</span>
          </div>
          <RouterLink class="link-action" to="/farm/work-orders">查看全部</RouterLink>
        </div>
        <div class="card__body card__body--list">
          <div v-for="task in todayTasks" :key="task.id" class="task-row">
            <div class="task-row__main">
              <div class="task-row__title">{{ task.title }}</div>
              <div class="task-row__meta">{{ task.assignee }} · 截止 {{ task.deadline.slice(11) }}</div>
            </div>
            <div class="task-row__progress">
              <div class="progress">
                <div
                  class="progress__bar"
                  :class="{ 'progress__bar--ok': task.progress === 100 }"
                  :style="{ width: `${task.progress}%` }"
                />
              </div>
              <b>{{ task.progress }}%</b>
            </div>
            <span class="pill" :class="`pill--${taskTone(task.status)}`">
              {{ task.status }}
            </span>
          </div>
        </div>
      </section>
    </div>

    <!-- 补充：园区核心指标 -->
    <section class="card dashboard__row">
      <div class="card__head">
        <div class="card__title">
          园区核心指标
          <span class="card__sub">2026 年 11 月累计</span>
        </div>
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
.dashboard__row {
  margin-bottom: 16px;
}

.card__body--list {
  padding-top: 6px;
  padding-bottom: 10px;
}

.alarm-row,
.task-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px 0;
  border-bottom: 1px solid var(--border-card);
}

.alarm-row:last-child,
.task-row:last-child {
  border-bottom: 0;
}

.alarm-row:hover .alarm-row__title,
.task-row:hover .task-row__title {
  color: var(--primary);
}

.alarm-row__main,
.task-row__main {
  flex: 1;
  min-width: 0;
}

.alarm-row__title,
.task-row__title {
  font-size: 13px;
  color: var(--text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  transition: color 0.16s ease;
}

.alarm-row__meta,
.task-row__meta {
  margin-top: 2px;
  font-size: 11.5px;
  color: var(--text-secondary);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.alarm-row__value {
  font-family: var(--font-num);
  font-size: 12px;
  color: var(--text-secondary);
  white-space: nowrap;
}

.task-row__progress {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 104px;
  flex: 0 0 auto;
}

.task-row__progress .progress {
  flex: 1;
}

.task-row__progress b {
  font-family: var(--font-num);
  font-size: 11.5px;
  font-weight: 500;
  color: var(--text-secondary);
}

.device-foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  margin-top: 18px;
  padding-top: 14px;
  border-top: 1px solid var(--border-card);
  font-size: 11.5px;
  color: var(--text-secondary);
}

.device-foot b {
  color: var(--text-primary);
  font-weight: 500;
}

@media (max-width: 720px) {
  .alarm-row__value,
  .task-row__progress {
    display: none;
  }
}
</style>
