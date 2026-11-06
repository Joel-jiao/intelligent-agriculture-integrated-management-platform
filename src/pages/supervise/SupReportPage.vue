<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import BarChart from '@/components/ui/BarChart.vue'
import { useToast } from '@/composables/useToast'
import { batches, pesticideLedger, qualityOverview, supWarnings, plotName } from '@/data/mock'
import { buildCsv, downloadText, nowDateTime } from '@/utils/format'

type ReportKey = 'quality' | 'trace' | 'pesticide' | 'warning'
type StatItem = { label: string; value: string | number; unit: string; icon: string; note: string }

interface ExportRecord {
  id: string
  name: string
  type: string
  range: string
  createdAt: string
  status: string
}

const toast = useToast()

const reports: Array<{ key: ReportKey; name: string; desc: string; icon: string }> = [
  { key: 'quality', name: '质量安全汇总', desc: '辖区抽检合格率、品类质量与不合格处置汇总', icon: '质' },
  { key: 'trace', name: '溯源台账', desc: '辖区农产品批次赋码、扫码与召回台账', icon: '溯' },
  { key: 'pesticide', name: '农药使用', desc: '农药使用记录、安全间隔期与合规核查', icon: '药' },
  { key: 'warning', name: '预警处置', desc: '监管预警受理、处置过程与办结情况', icon: '警' },
]

const active = ref<ReportKey>('quality')
const startDate = ref('2026-05-01')
const endDate = ref('2026-11-06')
const district = ref('全部辖区')

const districtOptions = [
  '全部辖区',
  '云岭智慧农业示范园',
  '璧山果蔬种植合作社',
  '璧北粮油生产基地',
  '青杠特色水果基地',
]
const monthLabels = ['6月', '7月', '8月', '9月', '10月', '11月']

const activeInfo = computed(() => reports.find((item) => item.key === active.value) ?? reports[0]!)

const statCards = computed<StatItem[]>(() => {
  if (active.value === 'quality') {
    return [
      { label: '抽检批次', value: qualityOverview.inspectedBatches, unit: '批', icon: '检', note: '近 6 个月累计' },
      { label: '抽检合格率', value: qualityOverview.passRate, unit: '%', icon: '合', note: '同比 +1.2%' },
      { label: '不合格批次', value: qualityOverview.unqualified, unit: '批', icon: '异', note: '均已启动处置' },
      { label: '产品召回', value: qualityOverview.recalls, unit: '起', icon: '召', note: '进行中 1 起' },
    ]
  }
  if (active.value === 'trace') {
    return [
      { label: '溯源批次', value: batches.length, unit: '批', icon: '批', note: '本期新增 6 批' },
      { label: '已赋码批次', value: batches.filter((item) => item.status === '已赋码').length, unit: '批', icon: '码', note: '赋码率 66.7%' },
      { label: '累计扫码', value: batches.reduce((sum, item) => sum + item.scans, 0).toLocaleString('zh-CN'), unit: '次', icon: '扫', note: '消费者访问量' },
      { label: '召回批次', value: batches.filter((item) => item.status === '已召回').length, unit: '批', icon: '召', note: '已同步 H5 提示' },
    ]
  }
  if (active.value === 'pesticide') {
    return [
      { label: '用药记录', value: pesticideLedger.length, unit: '条', icon: '药', note: '近 30 天登记' },
      { label: '合规记录', value: pesticideLedger.filter((item) => item.compliant).length, unit: '条', icon: '合', note: '合规率 83.3%' },
      { label: '违规记录', value: pesticideLedger.filter((item) => !item.compliant).length, unit: '条', icon: '违', note: '待整改 1 条' },
      { label: '涉及地块', value: new Set(pesticideLedger.map((item) => item.plot)).size, unit: '个', icon: '地', note: '覆盖 5 个地块' },
    ]
  }
  return [
    { label: '预警总数', value: supWarnings.length, unit: '条', icon: '警', note: '本期累计受理' },
    { label: '待处理', value: supWarnings.filter((item) => item.status === '待处理').length, unit: '条', icon: '待', note: '需 24 小时内响应' },
    { label: '处理中', value: supWarnings.filter((item) => item.status === '处理中').length, unit: '条', icon: '中', note: '已指派责任人' },
    { label: '已办结', value: supWarnings.filter((item) => item.status === '已办结').length, unit: '条', icon: '结', note: '办结率 33.3%' },
  ]
})

const previewHeaders = computed<string[]>(() => {
  if (active.value === 'quality') return ['品类', '抽检批次', '合格率', '不合格批次']
  if (active.value === 'trace') return ['批次号', '作物', '地块', '采收日期', '重量（kg）', '状态']
  if (active.value === 'pesticide') return ['日期', '地块', '作物', '农药名称', '用量', '合规性']
  return ['预警内容', '类型', '主体', '等级', '状态', '时间']
})

const previewRows = computed<Array<Array<string | number>>>(() => {
  if (active.value === 'quality') {
    return qualityOverview.categories.map((item) => [
      item.name,
      item.batches,
      `${item.passRate}%`,
      item.passRate < 100 ? 1 : 0,
    ])
  }
  if (active.value === 'trace') {
    return batches.map((item) => [
      item.batchNo,
      item.crop,
      plotName(item.plot),
      item.harvestedAt,
      item.weight,
      item.status,
    ])
  }
  if (active.value === 'pesticide') {
    return pesticideLedger.map((item) => [
      item.date,
      plotName(item.plot),
      item.crop,
      item.name,
      item.amount,
      item.compliant ? '合规' : '违规',
    ])
  }
  return supWarnings.map((item) => [item.title, item.type, item.entity, item.level, item.status, item.createdAt])
})

const chartValues = computed<number[]>(() => {
  if (active.value === 'quality') return [68, 70, 74, 76, 71, 72]
  if (active.value === 'trace') return [12, 15, 18, 16, 14, 6]
  if (active.value === 'pesticide') return [8, 10, 9, 7, 6, 6]
  return [5, 6, 4, 3, 2, 6]
})

const chartUnit = computed(() => {
  if (active.value === 'quality' || active.value === 'trace') return ' 批'
  return ' 条'
})

const exportRecords = reactive<ExportRecord[]>([
  { id: 'ER-20261105', name: '2026年10月质量安全汇总', type: '质量安全汇总', range: '2026-10-01 ~ 2026-10-31', createdAt: '2026-11-01 09:12', status: '已生成' },
  { id: 'ER-20261028', name: '辖区溯源台账（第三季度）', type: '溯源台账', range: '2026-07-01 ~ 2026-09-30', createdAt: '2026-10-08 15:40', status: '已生成' },
  { id: 'ER-20261020', name: '农药使用合规核查表', type: '农药使用', range: '2026-09-01 ~ 2026-09-30', createdAt: '2026-09-28 10:05', status: '已生成' },
])

function applyRange() {
  if (!startDate.value || !endDate.value) {
    toast.warn('请选择完整的统计时间范围')
    return
  }
  if (startDate.value > endDate.value) {
    toast.warn('开始日期不能晚于结束日期')
    return
  }
  toast.success(`已应用 ${district.value} · ${startDate.value} 至 ${endDate.value} 的统计范围`)
}

function exportCsv() {
  if (!startDate.value || !endDate.value) {
    toast.warn('请选择完整的时间范围后再导出')
    return
  }
  if (startDate.value > endDate.value) {
    toast.warn('开始日期不能晚于结束日期')
    return
  }
  const label = activeInfo.value.name
  downloadText(
    `监管报表_${label}_${endDate.value.replace(/-/g, '')}.csv`,
    buildCsv(previewHeaders.value, previewRows.value),
  )
  addRecord(label, '已生成')
  toast.success(`${label}已导出为 CSV 文件`)
}

function exportPdf() {
  const label = activeInfo.value.name
  addRecord(label, '生成中')
  toast.info(`${label} PDF 导出任务已提交，生成后可在导出记录中下载`)
}

function addRecord(label: string, status: string) {
  exportRecords.unshift({
    id: `ER-${Date.now().toString().slice(-6)}`,
    name: `${district.value} · ${label}`,
    type: label,
    range: `${startDate.value} ~ ${endDate.value}`,
    createdAt: nowDateTime(),
    status,
  })
  if (exportRecords.length > 8) exportRecords.splice(8)
}
</script>

<template>
  <div>
    <PageHeader
      eyebrow="SUPERVISION REPORT"
      title="监管报表导出"
      description="按报表类型、时间范围与辖区组合生成监管报表 · 支持 CSV 下载与 PDF 任务提交"
    >
      <template #actions>
        <button class="btn" type="button" @click="exportPdf">导出 PDF</button>
        <button class="btn btn--primary" type="button" @click="exportCsv">导出 CSV</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard
        v-for="item in statCards"
        :key="item.label"
        :label="item.label"
        :value="item.value"
        :unit="item.unit"
        :icon="item.icon"
        :note="item.note"
      />
    </div>

    <section class="card" style="margin-bottom: 16px">
      <div class="card__head">
        <div class="card__title">报表配置 <span class="card__sub">{{ activeInfo.desc }}</span></div>
        <span class="tag tag--brand">{{ activeInfo.name }}</span>
      </div>
      <div class="card__body">
        <div class="tabs" style="margin-bottom: 14px">
          <button
            v-for="item in reports"
            :key="item.key"
            class="tab"
            :class="{ 'tab--active': active === item.key }"
            type="button"
            @click="active = item.key"
          >
            {{ item.name }}
          </button>
        </div>
        <div class="toolbar" style="margin-bottom: 0">
          <div class="field field--inline">
            <span class="field__label">开始日期</span>
            <input v-model="startDate" type="date" class="input" style="width: 155px" />
          </div>
          <div class="field field--inline">
            <span class="field__label">结束日期</span>
            <input v-model="endDate" type="date" class="input" style="width: 155px" />
          </div>
          <div class="field field--inline">
            <span class="field__label">辖区</span>
            <select v-model="district" class="select" style="width: 190px">
              <option v-for="item in districtOptions" :key="item" :value="item">{{ item }}</option>
            </select>
          </div>
          <div class="toolbar__spacer" />
          <button class="btn btn--sm" type="button" @click="applyRange">应用筛选</button>
        </div>
      </div>
    </section>

    <div class="grid grid--main">
      <section class="card">
        <div class="card__head">
          <div class="card__title">数据预览 <span class="card__sub">{{ activeInfo.name }}</span></div>
          <button class="link-action" type="button" @click="exportCsv">导出当前预览</button>
        </div>
        <div class="table-wrap" style="border: 0; border-radius: 0 0 14px 14px">
          <table class="data-table">
            <thead>
              <tr>
                <th v-for="header in previewHeaders" :key="header">{{ header }}</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(row, rowIndex) in previewRows" :key="rowIndex">
                <td
                  v-for="(cell, cellIndex) in row"
                  :key="`${rowIndex}-${cellIndex}`"
                  :class="cellIndex === 0 ? 'cell-strong' : ''"
                >
                  {{ cell }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="card__footer" style="padding-top: 12px; font-size: 11.5px; color: var(--muted)">
          预览共 {{ previewRows.length }} 行 · 导出内容与预览一致
        </div>
      </section>

      <section class="card">
        <div class="card__head">
          <div class="card__title">近 6 个月数据预览</div>
          <span class="tag tag--outline">{{ activeInfo.name }}</span>
        </div>
        <div class="card__body">
          <BarChart :labels="monthLabels" :values="chartValues" :unit="chartUnit" color="#2f5fa8" :height="220" />
          <div class="notice notice--brand" style="margin-top: 16px">
            报表数据来源于辖区质量抽检、溯源台账与预警处置记录，导出前请确认时间范围与辖区范围。
          </div>
        </div>
      </section>
    </div>

    <section class="card" style="margin-top: 16px">
      <div class="card__head">
        <div class="card__title">导出记录 <span class="card__sub">最近 8 条</span></div>
        <button class="link-action" type="button" @click="toast.info('导出记录已是最新状态')">刷新记录</button>
      </div>
      <div class="table-wrap" style="border: 0; border-radius: 0 0 14px 14px">
        <table class="data-table">
          <thead>
            <tr>
              <th>记录编号</th>
              <th>报表名称</th>
              <th>类型</th>
              <th>统计范围</th>
              <th>生成时间</th>
              <th>状态</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in exportRecords" :key="item.id">
              <td class="cell-strong num">{{ item.id }}</td>
              <td>{{ item.name }}</td>
              <td>{{ item.type }}</td>
              <td class="num cell-muted">{{ item.range }}</td>
              <td class="num cell-muted">{{ item.createdAt }}</td>
              <td>
                <span class="tag" :class="item.status === '已生成' ? 'tag--ok' : 'tag--warn'">{{ item.status }}</span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  </div>
</template>
