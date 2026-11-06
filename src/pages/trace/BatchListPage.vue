<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import Pager from '@/components/ui/Pager.vue'
import { useToast } from '@/composables/useToast'
import { batches, plotName, plots, traceTimeline } from '@/data/mock'
import type { TraceBatch } from '@/data/types'
import { buildCsv, downloadText, formatNumber, today } from '@/utils/format'

const toast = useToast()
const router = useRouter()

const rows = ref<TraceBatch[]>(batches.map((item) => ({ ...item })))

const keyword = ref('')
const statusFilter = ref('全部')
const cropFilter = ref('全部')
const page = ref(1)
const pageSize = 6

const statusOptions = ['全部', '已赋码', '待赋码', '已召回']
const cropOptions = computed(() => ['全部', ...Array.from(new Set(rows.value.map((item) => item.crop)))])
function gradeTone(grade: string): 'brand' | 'ok' | 'warn' {
  if (grade === '特级') return 'brand'
  if (grade === '一级') return 'ok'
  return 'warn'
}
watch([keyword, statusFilter, cropFilter], () => {
  page.value = 1
})

const filtered = computed(() => {
  const text = keyword.value.trim().toLowerCase()
  return rows.value.filter((row) => {
    const matchStatus = statusFilter.value === '全部' || row.status === statusFilter.value
    const matchCrop = cropFilter.value === '全部' || row.crop === cropFilter.value
    const matchKeyword =
      !text ||
      [row.batchNo, row.plot, plotName(row.plot), row.crop, row.variety].some((value) =>
        value.toLowerCase().includes(text),
      )
    return matchStatus && matchCrop && matchKeyword
  })
})

const totalPages = computed(() => Math.max(1, Math.ceil(filtered.value.length / pageSize)))
watch(totalPages, (value) => {
  if (page.value > value) page.value = value
})

const paged = computed(() => {
  const start = (page.value - 1) * pageSize
  return filtered.value.slice(start, start + pageSize)
})

const codedBatches = computed(() => rows.value.filter((item) => item.status === '已赋码'))
const codedCount = computed(() => codedBatches.value.reduce((sum, item) => sum + item.qrCount, 0))
const pendingCount = computed(() => rows.value.filter((item) => item.status === '待赋码').length)
const totalScans = computed(() => rows.value.reduce((sum, item) => sum + item.scans, 0))

const createOpen = ref(false)
const form = reactive({
  batchNo: `B${today().replace(/-/g, '')}-07`,
  plot: 'P-01',
  crop: '',
  variety: '',
  harvestedAt: today(),
  weight: 0,
  grade: '一级',
})

watch(
  () => form.plot,
  (plotId) => {
    const plot = plots.find((item) => item.id === plotId)
    if (!plot) return
    form.crop = plot.crop
    form.variety = plot.variety
  },
  { immediate: true },
)

const detailOpen = ref(false)
const selected = ref<TraceBatch | null>(null)

function statusTone(status: TraceBatch['status']): 'ok' | 'warn' | 'danger' {
  if (status === '已赋码') return 'ok'
  if (status === '待赋码') return 'warn'
  return 'danger'
}

function openDetail(row: TraceBatch) {
  selected.value = row
  detailOpen.value = true
}

function createBatch() {
  const batchNo = form.batchNo.trim()
  if (!batchNo) {
    toast.error('请填写批次号')
    return
  }
  if (rows.value.some((item) => item.batchNo === batchNo)) {
    toast.error('批次号已存在，请重新填写')
    return
  }
  if (!form.crop.trim()) {
    toast.error('请填写作物名称')
    return
  }
  if (!form.weight || form.weight <= 0) {
    toast.error('采收重量需大于 0')
    return
  }
  const plot = plots.find((item) => item.id === form.plot)
  rows.value.unshift({
    id: `TB-${String(rows.value.length + 1).padStart(2, '0')}`,
    batchNo,
    plot: form.plot,
    crop: form.crop.trim(),
    variety: form.variety.trim() || '未填写',
    plantedAt: plot?.plantedAt ?? today(),
    harvestedAt: form.harvestedAt,
    weight: Number(form.weight),
    grade: form.grade,
    status: '待赋码',
    qrCount: 0,
    scans: 0,
  })
  createOpen.value = false
  page.value = 1
  toast.success(`批次 ${batchNo} 已创建，等待赋码`)
}

function gotoQrcode(row: TraceBatch) {
  router.push({ path: '/trace/qrcode', query: { batch: row.batchNo } })
}

function exportCsv() {
  const data = filtered.value.map((row) => [
    row.batchNo,
    row.plot,
    plotName(row.plot),
    row.crop,
    row.variety,
    row.harvestedAt,
    row.weight,
    row.grade,
    row.qrCount,
    row.scans,
    row.status,
  ])
  downloadText(
    `溯源批次_${today()}.csv`,
    buildCsv(
      ['批次号', '地块编号', '地块名称', '作物', '品种', '采收日期', '重量(kg)', '等级', '赋码数量', '扫码次数', '状态'],
      data,
    ),
  )
  toast.success(`已导出 ${data.length} 条批次记录`)
}
</script>

<template>
  <div>
    <PageHeader
      eyebrow="TRACEABILITY"
      title="溯源批次档案"
      description="按采收批次建立一物一码溯源档案，覆盖赋码、扫码与召回全流程"
    >
      <template #actions>
        <button class="btn" type="button" @click="exportCsv">导出 CSV</button>
        <button class="btn btn--primary" type="button" @click="createOpen = true">新建批次</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="溯源批次总数" :value="rows.length" unit="批" icon="批" note="覆盖 6 个地块" trend="本月新增 3 批" />
      <StatCard
        label="已赋码批次"
        :value="codedBatches.length"
        unit="批"
        icon="码"
        :note="`累计赋码 ${formatNumber(codedCount)} 枚`"
        trend="赋码率 50%"
      />
      <StatCard label="待赋码批次" :value="pendingCount" unit="批" icon="待" note="需尽快完成赋码" accent />
      <StatCard label="累计扫码次数" :value="formatNumber(totalScans)" unit="次" icon="扫" note="消费者访问溯源页" trend="较上周 +18%" />
    </div>

    <div class="toolbar">
      <div class="field field--inline">
        <span class="field__label">状态</span>
        <select v-model="statusFilter" class="select" style="width: 128px">
          <option v-for="item in statusOptions" :key="item" :value="item">{{ item }}</option>
        </select>
      </div>
      <div class="field field--inline">
        <span class="field__label">作物</span>
        <select v-model="cropFilter" class="select" style="width: 128px">
          <option v-for="item in cropOptions" :key="item" :value="item">{{ item }}</option>
        </select>
      </div>
      <div class="field field--inline" style="flex: 1; min-width: 220px">
        <span class="field__label">关键词</span>
        <input v-model="keyword" class="input" type="search" placeholder="搜索批次号、地块、作物或品种" />
      </div>
      <div class="toolbar__spacer" />
      <span class="tag tag--brand">共 {{ filtered.length }} 批</span>
    </div>

    <section class="card">
      <div class="card__head">
        <div class="card__title">批次明细 <span class="card__sub">按采收日期倒序</span></div>
        <button class="link-action" type="button" @click="exportCsv">导出当前筛选</button>
      </div>
      <div class="table-wrap" style="border: 0; border-radius: 0; margin-top: 14px">
        <table class="data-table">
          <thead>
            <tr>
              <th>批次号</th>
              <th>地块</th>
              <th>作物 / 品种</th>
              <th>采收日期</th>
              <th>重量</th>
              <th>等级</th>
              <th>赋码数量</th>
              <th>扫码次数</th>
              <th>状态</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in paged" :key="row.id">
              <td class="num cell-strong">{{ row.batchNo }}</td>
              <td>{{ plotName(row.plot) }}<span class="cell-muted">（{{ row.plot }}）</span></td>
              <td>{{ row.crop }}<span class="cell-muted"> / {{ row.variety }}</span></td>
              <td class="num">{{ row.harvestedAt }}</td>
              <td class="num">{{ formatNumber(row.weight) }} kg</td>
              <td><span class="tag" :class="`tag--${gradeTone(row.grade)}`">{{ row.grade }}</span></td>
              <td class="num">{{ formatNumber(row.qrCount) }}</td>
              <td class="num">{{ formatNumber(row.scans) }}</td>
              <td><StatusTag :text="row.status" :tone="statusTone(row.status)" dot /></td>
              <td>
                <div class="table-actions">
                  <button class="link-action" type="button" @click="openDetail(row)">详情</button>
                  <button
                    v-if="row.status !== '已召回'"
                    class="link-action"
                    type="button"
                    @click="gotoQrcode(row)"
                  >
                    生成溯源码
                  </button>
                </div>
              </td>
            </tr>
            <tr v-if="paged.length === 0">
              <td colspan="10">
                <div class="empty">
                  <div class="empty__mark">空</div>
                  <span>没有符合条件的溯源批次，请调整筛选条件</span>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <Pager :total="filtered.length" :page="page" :page-size="pageSize" @update:page="page = $event" />
    </section>

    <AppModal v-model="createOpen" title="新建溯源批次" size="lg">
      <div class="form-grid">
        <label class="field">
          <span class="field__label">批次号</span>
          <input v-model="form.batchNo" class="input" type="text" placeholder="如 B20261106-07" />
        </label>
        <label class="field">
          <span class="field__label">地块</span>
          <select v-model="form.plot" class="select">
            <option v-for="plot in plots" :key="plot.id" :value="plot.id">{{ plot.name }} · {{ plot.code }}</option>
          </select>
        </label>
        <label class="field">
          <span class="field__label">作物</span>
          <input v-model="form.crop" class="input" type="text" placeholder="如 番茄" />
        </label>
        <label class="field">
          <span class="field__label">品种</span>
          <input v-model="form.variety" class="input" type="text" placeholder="如 云粉 9 号" />
        </label>
        <label class="field">
          <span class="field__label">采收日期</span>
          <input v-model="form.harvestedAt" class="input" type="date" />
        </label>
        <label class="field">
          <span class="field__label">采收重量（kg）</span>
          <input v-model.number="form.weight" class="input" type="number" min="0" step="0.1" placeholder="请输入重量" />
        </label>
        <label class="field">
          <span class="field__label">等级</span>
          <select v-model="form.grade" class="select">
            <option value="特级">特级</option>
            <option value="一级">一级</option>
            <option value="二级">二级</option>
          </select>
        </label>
        <div class="field span-2">
          <span class="field__label">说明</span>
          <div class="notice">新建批次默认为“待赋码”状态，创建后可在溯源码生成页批量赋码。</div>
        </div>
      </div>
      <div class="form-foot">
        <button class="btn" type="button" @click="createOpen = false">取消</button>
        <button class="btn btn--primary" type="button" @click="createBatch">创建批次</button>
      </div>
    </AppModal>

    <AppModal v-model="detailOpen" title="溯源批次详情" size="lg">
      <div v-if="selected">
        <div class="kv kv--3">
          <div class="kv__item"><span>批次号</span><b>{{ selected.batchNo }}</b></div>
          <div class="kv__item"><span>地块</span><b>{{ plotName(selected.plot) }}</b></div>
          <div class="kv__item"><span>作物 / 品种</span><b>{{ selected.crop }} / {{ selected.variety }}</b></div>
          <div class="kv__item"><span>定植日期</span><b>{{ selected.plantedAt }}</b></div>
          <div class="kv__item"><span>采收日期</span><b>{{ selected.harvestedAt }}</b></div>
          <div class="kv__item"><span>采收重量</span><b>{{ formatNumber(selected.weight) }} kg</b></div>
          <div class="kv__item"><span>等级</span><b>{{ selected.grade }}</b></div>
          <div class="kv__item"><span>赋码数量</span><b>{{ formatNumber(selected.qrCount) }} 枚</b></div>
          <div class="kv__item"><span>扫码次数</span><b>{{ formatNumber(selected.scans) }} 次</b></div>
        </div>
        <div class="row row--between" style="margin: 18px 0 12px">
          <div class="card__title" style="padding-left: 2px">全程追溯时间线</div>
          <StatusTag :text="selected.status" :tone="statusTone(selected.status)" dot />
        </div>
        <div class="timeline">
          <div
            v-for="(item, index) in traceTimeline"
            :key="`${item.date}-${index}`"
            class="timeline__item"
            :class="{
              'timeline__item--done': index < traceTimeline.length - 1,
              'timeline__item--active': index === traceTimeline.length - 1,
            }"
          >
            <div class="timeline__title">
              {{ item.title }}
              <span class="cell-muted" style="font-family: var(--font-num); font-size: 11px">{{ item.date }}</span>
            </div>
            <div class="timeline__desc">{{ item.desc }}</div>
          </div>
        </div>
        <div class="notice notice--brand" style="margin-top: 16px">
          追溯记录覆盖定植、水肥、植保、环境监测、采收分级与质量检测，消费者扫码可查看完整链路。
        </div>
      </div>
      <div class="form-foot">
        <button class="btn" type="button" @click="detailOpen = false">关闭</button>
        <button
          v-if="selected && selected.status !== '已召回'"
          class="btn btn--primary"
          type="button"
          @click="selected && gotoQrcode(selected)"
        >
          前往生成溯源码
        </button>
      </div>
    </AppModal>
  </div>
</template>
