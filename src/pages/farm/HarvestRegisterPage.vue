<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import DonutChart from '@/components/ui/DonutChart.vue'
import Pager from '@/components/ui/Pager.vue'
import { useToast } from '@/composables/useToast'
import { harvests as seedHarvests, plots, plotName } from '@/data/mock'
import type { HarvestRecord } from '@/data/types'
import { buildCsv, downloadText, formatNumber, pad, today } from '@/utils/format'

const toast = useToast()

const harvestList = ref<HarvestRecord[]>(seedHarvests.map((item) => ({ ...item })))
const seq = ref(7)

const operators = ['王强', '赵敏', '陈刚', '刘洋', '周涛']
const grades: Array<HarvestRecord['grade']> = ['特级', '一级', '二级']

const batchNo = computed(() => `B${today().replace(/-/g, '')}-${pad(seq.value)}`)

const form = ref({
  plot: plots[0]?.id ?? '',
  weight: '',
  grade: '一级',
  harvestedAt: '2026-11-06 10:30',
  operator: '陈刚',
  note: '',
})

const crop = computed(() => plots.find((item) => item.id === form.value.plot)?.crop ?? '—')

const statusFilter = ref('全部')
const plotFilter = ref('全部')
const keyword = ref('')
const page = ref(1)
const pageSize = 6
const statusTabs = ['全部', '待入库', '已入库']

watch([statusFilter, plotFilter, keyword], () => {
  page.value = 1
})

const filteredRecords = computed(() =>
  harvestList.value.filter((item) => {
    if (statusFilter.value !== '全部' && item.status !== statusFilter.value) return false
    if (plotFilter.value !== '全部' && item.plot !== plotFilter.value) return false
    if (!keyword.value.trim()) return true
    const key = keyword.value.trim()
    return item.batchNo.includes(key) || item.crop.includes(key) || item.operator.includes(key)
  }),
)

const pagedRecords = computed(() => {
  const start = (page.value - 1) * pageSize
  return filteredRecords.value.slice(start, start + pageSize)
})

const todayWeight = computed(() =>
  harvestList.value.filter((item) => item.harvestedAt.startsWith(today())).reduce((sum, item) => sum + item.weight, 0),
)
const pendingCount = computed(() => harvestList.value.filter((item) => item.status === '待入库').length)
const storedCount = computed(() => harvestList.value.filter((item) => item.status === '已入库').length)
const totalWeight = computed(() => harvestList.value.reduce((sum, item) => sum + item.weight, 0))

const gradeSegments = computed(() => [
  { label: '特级', value: harvestList.value.filter((item) => item.grade === '特级').length, color: '#2f9e5a' },
  { label: '一级', value: harvestList.value.filter((item) => item.grade === '一级').length, color: '#b8862f' },
  { label: '二级', value: harvestList.value.filter((item) => item.grade === '二级').length, color: '#7ba6d9' },
])

function submitHarvest() {
  const weight = Number(form.value.weight)
  if (!form.value.plot) {
    toast.warn('请选择采收地块')
    return
  }
  if (Number.isNaN(weight) || weight <= 0) {
    toast.warn('采收重量需为大于 0 的数字')
    return
  }
  if (!form.value.harvestedAt.trim()) {
    toast.warn('请填写采收时间')
    return
  }
  const record: HarvestRecord = {
    id: `HR-${pad(harvestList.value.length + 1)}`,
    batchNo: batchNo.value,
    plot: form.value.plot,
    crop: crop.value,
    weight,
    grade: form.value.grade as HarvestRecord['grade'],
    harvestedAt: form.value.harvestedAt.trim(),
    operator: form.value.operator,
    status: '待入库',
  }
  harvestList.value.unshift(record)
  seq.value += 1
  page.value = 1
  toast.success(`批次 ${record.batchNo} 登记成功，采收 ${formatNumber(weight)} kg`)
  form.value.weight = ''
  form.value.note = ''
}

function resetForm() {
  form.value.weight = ''
  form.value.note = ''
  form.value.grade = '一级'
}

function storeRecord(record: HarvestRecord) {
  record.status = '已入库'
  toast.success(`批次 ${record.batchNo} 已标记入库`)
}

function exportRecords() {
  const rows = filteredRecords.value.map((item) => [
    item.batchNo,
    plotName(item.plot),
    item.crop,
    item.weight,
    item.grade,
    item.harvestedAt,
    item.operator,
    item.status,
  ])
  downloadText(
    '采收登记_20261106.csv',
    buildCsv(['批次号', '地块', '作物', '重量(kg)', '等级', '采收时间', '操作人', '状态'], rows),
  )
  toast.success(`已导出 ${rows.length} 条采收记录`)
}
</script>

<template>
  <div>
    <PageHeader eyebrow="FARM HARVEST" title="采收登记" description="按批次记录采收重量与等级，登记后可同步生成溯源批次">
      <template #actions>
        <button class="btn" type="button" @click="exportRecords">导出记录</button>
        <RouterLink class="btn" to="/farm/work-orders">查看采收工单</RouterLink>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="今日采收重量" :value="formatNumber(todayWeight)" unit="kg" icon="收" note="按采收时间统计今日累计" trend="较昨日 +12%" />
      <StatCard label="待入库批次" :value="pendingCount" unit="批" icon="待" note="需尽快完成冷库入库" trend="需处理" :trend-up="false" accent />
      <StatCard label="已入库批次" :value="storedCount" unit="批" icon="库" :note="`累计采收 ${formatNumber(totalWeight)} kg`" trend="入库率 92%" />
    </div>

    <div class="grid grid--main">
      <section class="card">
        <div class="card__head">
          <div class="card__title">采收登记表单 <span class="card__sub">批次号自动生成</span></div>
          <StatusTag :text="batchNo" tone="brand" />
        </div>
        <div class="card__body">
          <div class="form-grid">
            <label class="field">
              <span class="field__label">批次号</span>
              <input class="input" type="text" :value="batchNo" readonly />
            </label>
            <label class="field">
              <span class="field__label">采收地块</span>
              <select v-model="form.plot" class="select">
                <option v-for="item in plots" :key="item.id" :value="item.id">{{ item.name }}（{{ item.crop }}）</option>
              </select>
            </label>
            <label class="field">
              <span class="field__label">作物</span>
              <input class="input" type="text" :value="crop" readonly />
            </label>
            <label class="field">
              <span class="field__label">重量（kg）</span>
              <input v-model="form.weight" class="input" type="number" min="0" step="0.1" placeholder="请输入采收重量" />
            </label>
            <label class="field">
              <span class="field__label">等级</span>
              <select v-model="form.grade" class="select">
                <option v-for="item in grades" :key="item" :value="item">{{ item }}</option>
              </select>
            </label>
            <label class="field">
              <span class="field__label">采收时间</span>
              <input v-model="form.harvestedAt" class="input" type="text" placeholder="2026-11-06 10:30" />
            </label>
            <label class="field">
              <span class="field__label">操作人</span>
              <select v-model="form.operator" class="select">
                <option v-for="item in operators" :key="item" :value="item">{{ item }}</option>
              </select>
            </label>
            <label class="field">
              <span class="field__label">备注</span>
              <input v-model="form.note" class="input" type="text" placeholder="如：东侧 6 垄，单筐 12 kg" />
            </label>
          </div>
          <div class="notice notice--brand" style="margin-top: 14px">
            登记成功后自动生成批次号并进入「待入库」状态，可在溯源批次档案中赋码。
          </div>
          <div class="form-foot">
            <button class="btn" type="button" @click="resetForm">重置</button>
            <button class="btn btn--primary" type="button" @click="submitHarvest">提交登记</button>
          </div>
        </div>
      </section>

      <div class="stack">
        <section class="card">
          <div class="card__head">
            <div class="card__title">等级分布 <span class="card__sub">按批次数量</span></div>
            <span class="tag tag--outline">共 {{ harvestList.length }} 批</span>
          </div>
          <div class="card__body">
            <DonutChart :segments="gradeSegments" :size="150" :center-value="String(harvestList.length)" center-label="登记批次" />
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">登记规范</div>
          </div>
          <div class="card__body" style="display: grid; gap: 10px">
            <div class="notice">同一地块同一时段采收按单一批次登记，禁止混批。</div>
            <div class="notice notice--warn">特级、一级、二级需分筐存放，并记录单筐重量。</div>
            <div class="notice notice--brand">登记完成后 2 小时内提交冷库入库，超时将影响溯源赋码。</div>
          </div>
        </section>
      </div>
    </div>

    <section class="card" style="margin-top: 16px">
      <div class="card__head">
        <div class="card__title">采收记录 <span class="card__sub">共 {{ filteredRecords.length }} 条</span></div>
        <div class="tabs">
          <button
            v-for="item in statusTabs"
            :key="item"
            class="tab"
            :class="{ 'tab--active': statusFilter === item }"
            type="button"
            @click="statusFilter = item"
          >
            {{ item }}
          </button>
        </div>
      </div>
      <div class="card__body">
        <div class="toolbar">
          <label class="field" style="flex: 1; min-width: 190px">
            <span class="field__label">关键词</span>
            <input v-model="keyword" class="input" type="text" placeholder="批次号 / 作物 / 操作人" />
          </label>
          <label class="field" style="width: 170px">
            <span class="field__label">地块</span>
            <select v-model="plotFilter" class="select">
              <option value="全部">全部地块</option>
              <option v-for="item in plots" :key="item.id" :value="item.id">{{ item.name }}</option>
            </select>
          </label>
          <div class="toolbar__spacer" />
          <button class="link-action" type="button" @click="keyword = ''; plotFilter = '全部'; statusFilter = '全部'">重置筛选</button>
        </div>

        <div class="table-wrap">
          <table class="data-table">
            <thead>
              <tr>
                <th>批次号</th>
                <th>地块</th>
                <th>作物</th>
                <th>重量</th>
                <th>等级</th>
                <th>采收时间</th>
                <th>操作人</th>
                <th>状态</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="pagedRecords.length === 0">
                <td colspan="9">
                  <div class="empty">
                    <span class="empty__mark">空</span>
                    当前筛选条件下没有采收记录
                  </div>
                </td>
              </tr>
              <tr v-for="item in pagedRecords" :key="item.id">
                <td class="num cell-strong">{{ item.batchNo }}</td>
                <td>{{ plotName(item.plot) }}</td>
                <td>{{ item.crop }}</td>
                <td class="num">{{ formatNumber(item.weight) }} kg</td>
                <td>
                  <span class="tag" :class="item.grade === '特级' ? 'tag--ok' : item.grade === '一级' ? 'tag--brand' : 'tag--info'">{{ item.grade }}</span>
                </td>
                <td class="num">{{ item.harvestedAt }}</td>
                <td>{{ item.operator }}</td>
                <td><StatusTag :text="item.status" :tone="item.status === '已入库' ? 'ok' : 'warn'" dot /></td>
                <td>
                  <button v-if="item.status === '待入库'" class="btn btn--sm btn--primary" type="button" @click="storeRecord(item)">标记入库</button>
                  <span v-else class="tag tag--outline">已入库</span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <Pager :total="filteredRecords.length" :page="page" :page-size="pageSize" @update:page="page = $event" />
      </div>
    </section>
  </div>
</template>

<style scoped>
.stat-grid {
  grid-template-columns: repeat(3, minmax(0, 1fr));
}

@media (max-width: 720px) {
  .stat-grid {
    grid-template-columns: 1fr;
  }
}
</style>
