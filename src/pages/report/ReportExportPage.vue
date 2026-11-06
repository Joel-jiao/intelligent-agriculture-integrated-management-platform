<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import LineChart from '@/components/ui/LineChart.vue'
import BarChart from '@/components/ui/BarChart.vue'
import { useToast } from '@/composables/useToast'
import { batches, monthlyReport, park, plots, workOrders } from '@/data/mock'
import { buildCsv, downloadText, formatNumber, nowDateTime } from '@/utils/format'

type ReportType = 'env' | 'water' | 'work' | 'trace'

interface ReportStat {
  label: string
  value: string | number
  unit: string
  icon: string
  note: string
  accent?: boolean
}

interface ExportRecord {
  id: number
  name: string
  format: 'Excel' | 'CSV' | 'PDF'
  time: string
  rows: number
  operator: string
  status: '成功' | '生成中'
}

interface WorkMonthRow {
  month: string
  total: number
  done: number
  doing: number
  avg: number
}

interface TraceMonthRow {
  month: string
  count: number
  weight: number
  qr: number
  scans: number
  recalls: number
}

const toast = useToast()

const tabs: Array<{ key: ReportType; label: string }> = [
  { key: 'env', label: '环境月报' },
  { key: 'water', label: '水肥消耗' },
  { key: 'work', label: '农事汇总' },
  { key: 'trace', label: '溯源统计' },
]

const activeType = ref<ReportType>('env')
const activeLabel = computed(() => tabs.find((item) => item.key === activeType.value)?.label ?? '环境月报')

const monthStart = ref('2026-06')
const monthEnd = ref('2026-11')
const plotFilter = ref('全部')
const applied = reactive({ start: '2026-06', end: '2026-11', plot: '全部' })

const filteredMonths = computed(() =>
  monthlyReport.filter((item) => item.month >= applied.start && item.month <= applied.end),
)

const filteredOrders = computed(() =>
  workOrders.filter((order) => {
    const month = order.createdAt.slice(0, 7)
    const matchMonth = month >= applied.start && month <= applied.end
    const matchPlot = applied.plot === '全部' || order.plot === applied.plot
    return matchMonth && matchPlot
  }),
)

const filteredBatches = computed(() =>
  batches.filter((batch) => {
    const month = batch.harvestedAt.slice(0, 7)
    const matchMonth = month >= applied.start && month <= applied.end
    const matchPlot = applied.plot === '全部' || batch.plot === applied.plot
    return matchMonth && matchPlot
  }),
)

const waterSum = computed(() => filteredMonths.value.reduce((sum, item) => sum + item.water, 0))
const electricSum = computed(() => filteredMonths.value.reduce((sum, item) => sum + item.electric, 0))
const costSum = computed(() => filteredMonths.value.reduce((sum, item) => sum + item.cost, 0))
const alarmSum = computed(() => filteredMonths.value.reduce((sum, item) => sum + item.alarms, 0))
const orderSum = computed(() => filteredMonths.value.reduce((sum, item) => sum + item.orders, 0))

const workDone = computed(() => filteredOrders.value.filter((order) => order.status === '已完成').length)
const workDoing = computed(
  () => filteredOrders.value.filter((order) => order.status === '进行中' || order.status === '待接单' || order.status === '待验收').length,
)
const workAvg = computed(() => {
  if (filteredOrders.value.length === 0) return 0
  const total = filteredOrders.value.reduce((sum, order) => sum + order.progress, 0)
  return Math.round(total / filteredOrders.value.length)
})

const traceWeight = computed(() => filteredBatches.value.reduce((sum, item) => sum + item.weight, 0))
const traceQr = computed(() => filteredBatches.value.reduce((sum, item) => sum + item.qrCount, 0))
const traceScans = computed(() => filteredBatches.value.reduce((sum, item) => sum + item.scans, 0))

const workMonths = computed<WorkMonthRow[]>(() => {
  const map = new Map<string, { total: number; done: number; doing: number; progress: number }>()
  filteredOrders.value.forEach((order) => {
    const month = order.createdAt.slice(0, 7)
    const current = map.get(month) ?? { total: 0, done: 0, doing: 0, progress: 0 }
    current.total += 1
    if (order.status === '已完成') current.done += 1
    if (order.status === '进行中' || order.status === '待接单' || order.status === '待验收') current.doing += 1
    current.progress += order.progress
    map.set(month, current)
  })
  return Array.from(map.entries())
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([month, item]) => ({
      month,
      total: item.total,
      done: item.done,
      doing: item.doing,
      avg: item.total === 0 ? 0 : Math.round(item.progress / item.total),
    }))
})

const traceMonths = computed<TraceMonthRow[]>(() => {
  const map = new Map<string, { count: number; weight: number; qr: number; scans: number; recalls: number }>()
  filteredBatches.value.forEach((batch) => {
    const month = batch.harvestedAt.slice(0, 7)
    const current = map.get(month) ?? { count: 0, weight: 0, qr: 0, scans: 0, recalls: 0 }
    current.count += 1
    current.weight += batch.weight
    current.qr += batch.qrCount
    current.scans += batch.scans
    if (batch.status === '已召回') current.recalls += 1
    map.set(month, current)
  })
  return Array.from(map.entries())
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([month, item]) => ({ month, ...item }))
})

const stats = computed<ReportStat[]>(() => {
  if (activeType.value === 'env') {
    return [
      { label: '统计月份', value: filteredMonths.value.length, unit: '个月', icon: '月', note: `${applied.start} 至 ${applied.end}` },
      { label: '累计用水量', value: formatNumber(waterSum.value), unit: 'm³', icon: '水', note: '园区灌溉与生活用水' },
      { label: '累计用电量', value: formatNumber(electricSum.value), unit: 'kWh', icon: '电', note: '设备运行与照明用电' },
      { label: '累计告警', value: alarmSum.value, unit: '条', icon: '警', note: `关联工单 ${orderSum.value} 单`, accent: true },
    ]
  }
  if (activeType.value === 'water') {
    return [
      { label: '累计用水量', value: formatNumber(waterSum.value), unit: 'm³', icon: '水', note: '含水肥一体化滴灌' },
      { label: '累计用电量', value: formatNumber(electricSum.value), unit: 'kWh', icon: '电', note: '较上月下降 8%' },
      { label: '能耗费用', value: formatNumber(costSum.value), unit: '元', icon: '费', note: '按现行水电单价估算' },
      { label: '亩均用水', value: formatNumber(waterSum.value / park.area, 2), unit: 'm³/亩', icon: '亩', note: `园区面积 ${park.area} 亩`, accent: true },
    ]
  }
  if (activeType.value === 'work') {
    return [
      { label: '工单总数', value: filteredOrders.value.length, unit: '单', icon: '工', note: '按创建时间统计' },
      { label: '已完成工单', value: workDone.value, unit: '单', icon: '完', note: '含已完成与待验收' },
      { label: '处理中工单', value: workDoing.value, unit: '单', icon: '进', note: '待接单 / 进行中 / 待验收' },
      { label: '平均进度', value: workAvg.value, unit: '%', icon: '率', note: '按工单进度加权计算', accent: true },
    ]
  }
  return [
    { label: '溯源批次数', value: filteredBatches.value.length, unit: '批', icon: '批', note: '按采收月份统计' },
    { label: '采收重量', value: formatNumber(traceWeight.value), unit: 'kg', icon: '重', note: '已登记批次重量' },
    { label: '赋码数量', value: formatNumber(traceQr.value), unit: '枚', icon: '码', note: '已生成溯源码总量' },
    { label: '扫码次数', value: formatNumber(traceScans.value), unit: '次', icon: '扫', note: '消费者扫码访问', accent: true },
  ]
})

const previewHeaders = computed<string[]>(() => {
  if (activeType.value === 'env') {
    return ['月份', '用水量(m³)', '用电量(kWh)', '能耗费用(元)', '告警数', '工单数']
  }
  if (activeType.value === 'water') {
    return ['月份', '用水量(m³)', '用电量(kWh)', '费用(元)', '用水环比']
  }
  if (activeType.value === 'work') {
    return ['月份', '工单数', '已完成', '进行中', '平均进度']
  }
  return ['月份', '批次数', '采收重量(kg)', '赋码数量', '扫码次数', '召回批次']
})

const previewRows = computed<Array<Array<string | number>>>(() => {
  if (activeType.value === 'env') {
    return filteredMonths.value.map((item) => [item.month, item.water, item.electric, item.cost, item.alarms, item.orders])
  }
  if (activeType.value === 'water') {
    let previous: number | null = null
    return filteredMonths.value.map((item) => {
      let ratio = '—'
      if (previous !== null && previous > 0) {
        ratio = `${(((item.water - previous) / previous) * 100).toFixed(1)}%`
      }
      previous = item.water
      return [item.month, item.water, item.electric, item.cost, ratio]
    })
  }
  if (activeType.value === 'work') {
    return workMonths.value.map((item) => [item.month, item.total, item.done, item.doing, `${item.avg}%`])
  }
  return traceMonths.value.map((item) => [item.month, item.count, item.weight, item.qr, item.scans, item.recalls])
})

const chartLabels = computed(() => filteredMonths.value.map((item) => item.month))
const waterElectricSeries = computed(() => [
  { name: '用水量', color: '#2f6fae', data: filteredMonths.value.map((item) => item.water) },
  { name: '用电量', color: '#b8862f', data: filteredMonths.value.map((item) => item.electric) },
])

const workChartLabels = computed(() => workMonths.value.map((item) => item.month.slice(5) + '月'))
const workChartValues = computed(() => workMonths.value.map((item) => item.total))
const traceChartLabels = computed(() => filteredBatches.value.map((item) => item.batchNo.slice(5)))
const traceChartValues = computed(() => filteredBatches.value.map((item) => item.scans))

const records = ref<ExportRecord[]>([
  { id: 1, name: '环境月报_2026-10.csv', format: 'CSV', time: '2026-11-05 16:30', rows: 1, operator: '李明', status: '成功' },
  { id: 2, name: '水肥消耗_2026Q3.xls', format: 'Excel', time: '2026-11-03 10:12', rows: 3, operator: '李明', status: '成功' },
])
let recordSeq = 2

function applyFilters() {
  if (!monthStart.value || !monthEnd.value) {
    toast.error('请选择完整的时间范围')
    return
  }
  if (monthStart.value > monthEnd.value) {
    toast.error('开始月份不能晚于结束月份')
    return
  }
  applied.start = monthStart.value
  applied.end = monthEnd.value
  applied.plot = plotFilter.value
  toast.success(`筛选条件已应用：${applied.start} 至 ${applied.end}`)
}

function resetFilters() {
  monthStart.value = '2026-06'
  monthEnd.value = '2026-11'
  plotFilter.value = '全部'
  applied.start = '2026-06'
  applied.end = '2026-11'
  applied.plot = '全部'
  toast.info('筛选条件已重置')
}

function exportFile(format: 'Excel' | 'CSV') {
  if (previewRows.value.length === 0) {
    toast.warn('当前筛选条件下暂无可导出数据')
    return
  }
  const extension = format === 'Excel' ? 'xls' : 'csv'
  const filename = `${activeLabel.value}_${applied.start}_${applied.end}.${extension}`
  downloadText(filename, buildCsv(previewHeaders.value, previewRows.value))
  recordSeq += 1
  records.value.unshift({
    id: recordSeq,
    name: filename,
    format,
    time: nowDateTime(),
    rows: previewRows.value.length,
    operator: '李明',
    status: '成功',
  })
  toast.success(`${activeLabel.value}已导出为 ${format} 文件，共 ${previewRows.value.length} 条记录`)
}

function exportPdf() {
  if (previewRows.value.length === 0) {
    toast.warn('当前筛选条件下暂无可导出数据')
    return
  }
  const filename = `${activeLabel.value}_${applied.start}_${applied.end}.pdf`
  recordSeq += 1
  records.value.unshift({
    id: recordSeq,
    name: filename,
    format: 'PDF',
    time: nowDateTime(),
    rows: previewRows.value.length,
    operator: '李明',
    status: '生成中',
  })
  toast.info(`${activeLabel.value} PDF 生成任务已提交，完成后可在导出记录中查看`)
}
</script>

<template>
  <div>
    <PageHeader
      eyebrow="REPORT CENTER"
      title="综合报表导出"
      description="按环境、水肥、农事与溯源维度汇总经营数据，支持 Excel、CSV 与 PDF 导出"
    >
      <template #actions>
        <button class="btn" type="button" @click="exportPdf">导出 PDF</button>
        <button class="btn" type="button" @click="exportFile('Excel')">导出 Excel</button>
        <button class="btn btn--primary" type="button" @click="exportFile('CSV')">导出 CSV</button>
      </template>
    </PageHeader>

    <div class="toolbar">
      <div class="tabs">
        <button
          v-for="item in tabs"
          :key="item.key"
          class="tab"
          :class="{ 'tab--active': activeType === item.key }"
          type="button"
          @click="activeType = item.key"
        >
          {{ item.label }}
        </button>
      </div>
      <div class="field field--inline">
        <span class="field__label">开始月份</span>
        <input v-model="monthStart" class="input" type="month" style="width: 148px" />
      </div>
      <div class="field field--inline">
        <span class="field__label">结束月份</span>
        <input v-model="monthEnd" class="input" type="month" style="width: 148px" />
      </div>
      <div class="field field--inline">
        <span class="field__label">地块</span>
        <select v-model="plotFilter" class="select" style="width: 150px">
          <option value="全部">全部地块</option>
          <option v-for="plot in plots" :key="plot.id" :value="plot.id">{{ plot.name }}</option>
        </select>
      </div>
      <div class="toolbar__spacer" />
      <button class="btn btn--sm" type="button" @click="resetFilters">重置</button>
      <button class="btn btn--sm btn--primary" type="button" @click="applyFilters">应用筛选</button>
    </div>

    <div class="stat-grid">
      <StatCard
        v-for="item in stats"
        :key="item.label"
        :label="item.label"
        :value="item.value"
        :unit="item.unit"
        :icon="item.icon"
        :note="item.note"
        :accent="Boolean(item.accent)"
      />
    </div>

    <div class="grid grid--main">
      <section class="card">
        <div class="card__head">
          <div class="card__title">
            数据趋势 <span class="card__sub">{{ activeLabel }} · {{ applied.start }} 至 {{ applied.end }}</span>
          </div>
          <div class="legend">
            <span v-if="activeType === 'env' || activeType === 'water'"><i style="background: #2f6fae" />用水量</span>
            <span v-if="activeType === 'env' || activeType === 'water'"><i style="background: #b8862f" />用电量</span>
            <span v-if="activeType === 'work'"><i style="background: #2f8f5b" />工单数量</span>
            <span v-if="activeType === 'trace'"><i style="background: #2f6fae" />扫码次数</span>
          </div>
        </div>
        <div class="card__body">
          <LineChart
            v-if="activeType === 'env' || activeType === 'water'"
            :labels="chartLabels"
            :series="waterElectricSeries"
            :height="214"
          />
          <BarChart
            v-else-if="activeType === 'work'"
            :labels="workChartLabels"
            :values="workChartValues"
            color="#2f8f5b"
            :height="214"
          />
          <BarChart
            v-else
            :labels="traceChartLabels"
            :values="traceChartValues"
            color="#2f6fae"
            :height="214"
          />
          <div v-if="applied.plot !== '全部' && (activeType === 'env' || activeType === 'water')" class="notice" style="margin-top: 10px">
            环境与水肥报表为全园区汇总口径，地块筛选仅作用于农事与溯源报表。
          </div>
        </div>
      </section>

      <section class="card">
        <div class="card__head">
          <div class="card__title">导出记录 <span class="card__sub">最近 5 条</span></div>
          <button class="link-action" type="button" @click="exportFile('CSV')">快速导出</button>
        </div>
        <div class="card__body" style="padding-top: 8px">
          <div v-for="record in records.slice(0, 5)" :key="record.id" class="export-row">
            <span class="tag" :class="record.format === 'PDF' ? 'tag--danger' : record.format === 'Excel' ? 'tag--ok' : 'tag--info'">
              {{ record.format }}
            </span>
            <div class="export-row__body">
              <div class="export-row__name">{{ record.name }}</div>
              <div class="export-row__meta">{{ record.time }} · {{ record.rows }} 条 · {{ record.operator }}</div>
            </div>
            <StatusTag :text="record.status" :tone="record.status === '成功' ? 'ok' : 'warn'" />
          </div>
          <div v-if="records.length === 0" class="empty">
            <div class="empty__mark">报</div>
            <span>暂无导出记录</span>
          </div>
        </div>
      </section>
    </div>

    <section class="card" style="margin-top: 16px">
      <div class="card__head">
        <div class="card__title">
          报表预览 <span class="card__sub">{{ previewRows.length }} 行 · {{ activeLabel }}</span>
        </div>
        <div class="row" style="gap: 8px">
          <button class="btn btn--sm" type="button" @click="exportFile('CSV')">CSV</button>
          <button class="btn btn--sm btn--primary" type="button" @click="exportFile('Excel')">Excel</button>
        </div>
      </div>
      <div class="table-wrap preview-wrap" style="border: 0; border-radius: 0; margin-top: 14px">
        <table class="data-table">
          <thead>
            <tr>
              <th v-for="header in previewHeaders" :key="header">{{ header }}</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(row, rowIndex) in previewRows" :key="rowIndex">
              <td v-for="(cell, cellIndex) in row" :key="`${rowIndex}-${cellIndex}`" :class="{ num: typeof cell === 'number' || cellIndex === 0 }">
                {{ cell }}
              </td>
            </tr>
            <tr v-if="previewRows.length === 0">
              <td :colspan="previewHeaders.length">
                <div class="empty">
                  <div class="empty__mark">空</div>
                  <span>当前筛选条件下暂无报表数据，请调整时间范围或地块</span>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="card__footer" style="padding-top: 12px">
        <div class="legend">
          <span>数据来源：环境监测、水电计量、农事工单与溯源批次台账</span>
          <span>生成时间 {{ nowDateTime() }}</span>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.export-row {
  display: flex;
  align-items: center;
  gap: 9px;
  padding: 10px 0;
  border-bottom: 1px dashed var(--line);
}

.export-row:last-child {
  border-bottom: 0;
}

.export-row__body {
  flex: 1;
  min-width: 0;
}

.export-row__name {
  overflow: hidden;
  font-size: 12px;
  color: var(--ink-2);
  text-overflow: ellipsis;
  white-space: nowrap;
}

.export-row__meta {
  margin-top: 1px;
  font-size: 10.5px;
  color: var(--faint);
}

.preview-wrap {
  max-height: 420px;
}
</style>
