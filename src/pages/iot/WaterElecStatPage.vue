<script setup lang="ts">
import { computed, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import BarChart from '@/components/ui/BarChart.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import { useToast } from '@/composables/useToast'
import { monthlyReport, park, plots, waterElectric } from '@/data/mock'
import { buildCsv, downloadText, formatNumber } from '@/utils/format'

const toast = useToast()

const rangeStart = ref('6月')
const rangeEnd = ref('11月')
const selectedPlot = ref('all')

const monthLabels = waterElectric.months

function monthIndexOf(rowMonth: string): number {
  return monthLabels.indexOf(`${Number(rowMonth.slice(5, 7))}月`)
}

const startIndex = computed(() => Math.max(0, monthLabels.indexOf(rangeStart.value)))
const endIndex = computed(() => Math.max(0, monthLabels.indexOf(rangeEnd.value)))
const lowIndex = computed(() => Math.min(startIndex.value, endIndex.value))
const highIndex = computed(() => Math.max(startIndex.value, endIndex.value))

const plotFactor = computed(() => {
  if (selectedPlot.value === 'all') return 1
  const plot = plots.find((item) => item.id === selectedPlot.value)
  return plot ? plot.area / park.area : 1
})

const plotScope = computed(() =>
  selectedPlot.value === 'all' ? '全园区' : plots.find((item) => item.id === selectedPlot.value)?.name ?? '全园区',
)

const reportRows = computed(() =>
  monthlyReport.filter((row) => {
    const index = monthIndexOf(row.month)
    return index >= lowIndex.value && index <= highIndex.value
  }),
)

const displayRows = computed(() =>
  reportRows.value.map((row) => ({
    ...row,
    water: Math.round(row.water * plotFactor.value),
    electric: Math.round(row.electric * plotFactor.value),
    cost: Math.round(row.cost * plotFactor.value),
  })),
)

const latest = computed(() => displayRows.value[displayRows.value.length - 1])
const previous = computed(() => displayRows.value[displayRows.value.length - 2])

const yoy = computed(() => {
  const last = latest.value
  const prev = previous.value
  if (!last || !prev) return 0
  const base = prev.water + prev.electric
  if (base === 0) return 0
  return Math.round((((last.water + last.electric) - base) / base) * 1000) / 10
})

const waterChange = computed(() => {
  const last = latest.value
  const prev = previous.value
  if (!last || !prev || prev.water === 0) return 0
  return Math.round(((last.water - prev.water) / prev.water) * 1000) / 10
})

const electricChange = computed(() => {
  const last = latest.value
  const prev = previous.value
  if (!last || !prev || prev.electric === 0) return 0
  return Math.round(((last.electric - prev.electric) / prev.electric) * 1000) / 10
})

const chartLabels = computed(() => displayRows.value.map((row) => `${Number(row.month.slice(5, 7))}月`))
const waterValues = computed(() => displayRows.value.map((row) => row.water))
const electricValues = computed(() => displayRows.value.map((row) => row.electric))

const waterMax = computed(() => Math.max(1, ...waterValues.value))
const electricMax = computed(() => Math.max(1, ...electricValues.value))

function applyFilters() {
  toast.info(`已按「${plotScope.value} · ${rangeStart.value} 至 ${rangeEnd.value}」重新统计水电用量`)
}

function exportCsv() {
  const rows = displayRows.value.map((row) => [row.month, row.water, row.electric, row.cost, row.alarms, row.orders])
  downloadText(
    `水电计量统计_${plotScope.value}_${rangeStart.value}-${rangeEnd.value}.csv`,
    buildCsv(['月份', '用水量(m³)', '用电量(kWh)', '费用(元)', '告警数', '工单数'], rows),
  )
  toast.success(`已导出 ${rows.length} 条月度水电记录`)
}
</script>

<template>
  <div>
    <PageHeader
      eyebrow="IOT · METERING"
      title="水电计量统计"
      description="园区用水用电分月统计与对比分析 · 计量表读数每 60 分钟同步一次"
    >
      <template #actions>
        <button class="btn" type="button" @click="applyFilters">重新统计</button>
        <button class="btn btn--primary" type="button" @click="exportCsv">导出统计表</button>
      </template>
    </PageHeader>

    <div class="toolbar">
      <div class="field">
        <span class="field__label">开始月份</span>
        <select v-model="rangeStart" class="select" style="width: 120px">
          <option v-for="month in monthLabels" :key="month" :value="month">{{ month }}</option>
        </select>
      </div>
      <div class="field">
        <span class="field__label">结束月份</span>
        <select v-model="rangeEnd" class="select" style="width: 120px">
          <option v-for="month in monthLabels" :key="month" :value="month">{{ month }}</option>
        </select>
      </div>
      <div class="field">
        <span class="field__label">统计地块</span>
        <select v-model="selectedPlot" class="select" style="width: 160px">
          <option value="all">全园区</option>
          <option v-for="plot in plots" :key="plot.id" :value="plot.id">{{ plot.name }}</option>
        </select>
      </div>
      <button class="btn btn--primary" type="button" @click="applyFilters">查询</button>
      <div class="toolbar__spacer" />
      <span class="tag tag--brand">统计范围 {{ plotScope }}</span>
      <span class="tag tag--info">{{ reportRows.length }} 个月</span>
    </div>

    <div class="stat-grid">
      <StatCard
        label="本月用水量"
        :value="formatNumber(latest?.water ?? 0)"
        unit="m³"
        icon="水"
        :note="plotScope"
        :trend="`较上月 ${waterChange > 0 ? '+' : ''}${waterChange}%`"
        :trend-up="waterChange <= 0"
      />
      <StatCard
        label="本月用电量"
        :value="formatNumber(latest?.electric ?? 0)"
        unit="kWh"
        icon="电"
        :note="plotScope"
        :trend="`较上月 ${electricChange > 0 ? '+' : ''}${electricChange}%`"
        :trend-up="electricChange <= 0"
      />
      <StatCard
        label="本月水电费用"
        :value="formatNumber(latest?.cost ?? 0)"
        unit="元"
        icon="费"
        note="含基本电费与水资源费"
        accent
      />
      <StatCard
        label="水电同比"
        :value="Math.abs(yoy)"
        unit="%"
        icon="比"
        :trend="`${yoy > 0 ? '+' : ''}${yoy}% 环比`"
        :trend-up="yoy <= 0"
        note="用水与用电合计"
      />
    </div>

    <div class="grid grid--2">
      <section class="card">
        <div class="card__head">
          <div class="card__title">
            用水量趋势
            <span class="card__sub">单位 m³</span>
          </div>
          <span class="tag tag--info">{{ plotScope }}</span>
        </div>
        <div class="card__body">
          <BarChart :labels="chartLabels" :values="waterValues" color="#2f7fae" :height="210" />
        </div>
      </section>

      <section class="card">
        <div class="card__head">
          <div class="card__title">
            用电量趋势
            <span class="card__sub">单位 kWh</span>
          </div>
          <span class="tag tag--warn">{{ plotScope }}</span>
        </div>
        <div class="card__body">
          <BarChart :labels="chartLabels" :values="electricValues" color="#b8862f" :height="210" />
        </div>
      </section>
    </div>

    <div class="grid grid--main" style="margin-top: 16px">
      <section class="card">
        <div class="card__head">
          <div class="card__title">月度明细</div>
          <button class="link-action" type="button" @click="exportCsv">导出</button>
        </div>
        <div class="table-wrap" style="border: 0; border-radius: 0">
          <table class="data-table">
            <thead>
              <tr>
                <th>月份</th>
                <th>用水量 (m³)</th>
                <th>用电量 (kWh)</th>
                <th>费用 (元)</th>
                <th>告警数</th>
                <th>工单数</th>
                <th>状态</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="row in displayRows" :key="row.month">
                <td class="num cell-strong">{{ row.month }}</td>
                <td class="num">{{ formatNumber(row.water) }}</td>
                <td class="num">{{ formatNumber(row.electric) }}</td>
                <td class="num">{{ formatNumber(row.cost) }}</td>
                <td class="num">{{ row.alarms }}</td>
                <td class="num">{{ row.orders }}</td>
                <td>
                  <StatusTag v-if="row.alarms > 20" text="偏高" tone="warn" />
                  <StatusTag v-else text="正常" tone="ok" />
                </td>
              </tr>
              <tr v-if="displayRows.length === 0">
                <td colspan="7"><div class="empty">所选时间范围内暂无计量数据</div></td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <div class="stack">
        <section class="card">
          <div class="card__head">
            <div class="card__title">用水用电对比</div>
            <span class="tag">按月归一化</span>
          </div>
          <div class="card__body" style="display: grid; gap: 14px">
            <div v-for="row in displayRows" :key="row.month" class="compare-row">
              <div class="compare-row__head">
                <b>{{ row.month }}</b>
                <span>水 {{ formatNumber(row.water) }} m³ · 电 {{ formatNumber(row.electric) }} kWh</span>
              </div>
              <div class="compare-row__bar">
                <span class="compare-row__label">水</span>
                <div class="progress">
                  <div class="progress__bar progress__bar--info" :style="{ width: `${(row.water / waterMax) * 100}%` }" />
                </div>
              </div>
              <div class="compare-row__bar">
                <span class="compare-row__label">电</span>
                <div class="progress">
                  <div class="progress__bar progress__bar--warn" :style="{ width: `${(row.electric / electricMax) * 100}%` }" />
                </div>
              </div>
            </div>
            <div v-if="displayRows.length === 0" class="empty">暂无对比数据</div>
          </div>
        </section>

        <section class="card card--tint">
          <div class="card__head">
            <div class="card__title">节能建议</div>
            <span class="tag tag--brand">自动生成</span>
          </div>
          <div class="card__body" style="display: grid; gap: 10px">
            <div class="notice notice--brand">
              11 月用水用电量进入回落区间，主要因气温下降、灌溉频次减少，符合季节性规律。
            </div>
            <div class="notice notice--warn">
              建议将环流风机运行时段与棚内温度联动，预计每月可节电 6% - 9%。
            </div>
            <div class="notice">
              夜间灌溉改为清晨时段，可减少蒸发损耗，提升水资源利用率约 5%。
            </div>
          </div>
        </section>
      </div>
    </div>
  </div>
</template>

<style scoped>
.progress__bar--info {
  background: linear-gradient(90deg, var(--info), #6ea3d8);
}

.compare-row {
  padding: 10px 12px;
  border: 1px solid var(--line);
  border-radius: 9px;
  background: var(--surface-2);
}

.compare-row__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  margin-bottom: 8px;
  font-size: 11px;
  color: var(--muted);
}

.compare-row__head b {
  font-size: 12px;
  color: var(--ink);
  font-family: var(--font-num);
}

.compare-row__bar {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 6px;
}

.compare-row__label {
  width: 14px;
  font-size: 11px;
  color: var(--muted);
}

.compare-row__bar .progress {
  flex: 1;
}
</style>
