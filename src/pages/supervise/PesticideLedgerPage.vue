<script setup lang="ts">
import { computed, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { pesticideLedger, plotName, plots } from '@/data/mock'
import { buildCsv, downloadText } from '@/utils/format'

interface LedgerRow {
  id: string
  date: string
  plot: string
  crop: string
  name: string
  amount: string
  operator: string
  method: string
  safetyDays: number
  compliant: boolean
  note?: string
}

const toast = useToast()
const ledger: LedgerRow[] = pesticideLedger

const plotFilter = ref('')
const cropFilter = ref('')
const compliantFilter = ref('')
const keyword = ref('')

const cropOptions = computed(() => Array.from(new Set(ledger.map((item) => item.crop))))
const compliantCount = computed(() => ledger.filter((item) => item.compliant).length)
const violatedCount = computed(() => ledger.filter((item) => !item.compliant).length)
const plotCount = computed(() => new Set(ledger.map((item) => item.plot)).size)

const filteredRows = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  return ledger.filter((item) => {
    const matchPlot = !plotFilter.value || item.plot === plotFilter.value
    const matchCrop = !cropFilter.value || item.crop === cropFilter.value
    const matchCompliant =
      !compliantFilter.value ||
      (compliantFilter.value === '合规' ? item.compliant : !item.compliant)
    const matchKeyword =
      !kw || [item.name, item.operator, item.crop, item.method].some((value) => value.toLowerCase().includes(kw))
    return matchPlot && matchCrop && matchCompliant && matchKeyword
  })
})

const detailOpen = ref(false)
const detail = ref<LedgerRow | null>(null)

function openDetail(row: LedgerRow) {
  detail.value = row
  detailOpen.value = true
}

function resetFilters() {
  plotFilter.value = ''
  cropFilter.value = ''
  compliantFilter.value = ''
  keyword.value = ''
  toast.info('筛选条件已重置')
}

function exportCsv() {
  const rows = filteredRows.value.map((item) => [
    item.date,
    plotName(item.plot),
    item.crop,
    item.name,
    item.amount,
    item.operator,
    item.method,
    item.safetyDays,
    item.compliant ? '合规' : '违规',
    item.note ?? '—',
  ])
  downloadText(
    '辖区农药使用台账_20261106.csv',
    buildCsv(['日期', '地块', '作物', '农药名称', '用量', '操作人', '施用方式', '安全间隔期(天)', '合规性', '违规原因'], rows),
  )
  toast.success(`已导出 ${rows.length} 条农药使用记录`)
}
</script>

<template>
  <div>
    <PageHeader
      eyebrow="PESTICIDE LEDGER"
      title="农药农资使用记录"
      description="辖区农药使用台账合规核查 · 重点监控安全间隔期与施药记录完整性"
    >
      <template #actions>
        <RouterLink class="btn" to="/sup/trace">溯源台账</RouterLink>
        <button class="btn btn--primary" type="button" @click="exportCsv">导出 CSV</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="用药记录" :value="ledger.length" unit="条" icon="药" note="近 30 天累计登记" />
      <StatCard label="合规记录" :value="compliantCount" unit="条" icon="合" note="安全间隔期符合规定" trend="合规率 83.3%" />
      <StatCard label="违规记录" :value="violatedCount" unit="条" icon="违" note="需整改并复检" trend="待整改 1" trend-up accent />
      <StatCard label="涉及地块" :value="plotCount" unit="个" icon="地" note="覆盖蔬菜、水果与粮油" />
    </div>

    <div class="notice notice--warn" style="margin-bottom: 16px">
      合规提醒：农药使用必须严格执行安全间隔期规定，施药记录应包含农药名称、用量、操作人与施用方式；违规记录需在 3 个工作日内完成整改并接受复检。
    </div>

    <section class="card">
      <div class="card__head">
        <div class="card__title">农药使用台账 <span class="card__sub">共 {{ filteredRows.length }} 条</span></div>
        <button class="link-action" type="button" @click="exportCsv">导出当前结果</button>
      </div>
      <div class="card__body">
        <div class="toolbar">
          <div class="field field--inline">
            <span class="field__label">地块</span>
            <select v-model="plotFilter" class="select" style="width: 150px">
              <option value="">全部地块</option>
              <option v-for="item in plots" :key="item.id" :value="item.id">{{ item.name }}</option>
            </select>
          </div>
          <div class="field field--inline">
            <span class="field__label">作物</span>
            <select v-model="cropFilter" class="select" style="width: 120px">
              <option value="">全部作物</option>
              <option v-for="item in cropOptions" :key="item" :value="item">{{ item }}</option>
            </select>
          </div>
          <div class="field field--inline">
            <span class="field__label">合规性</span>
            <select v-model="compliantFilter" class="select" style="width: 120px">
              <option value="">全部</option>
              <option value="合规">合规</option>
              <option value="违规">违规</option>
            </select>
          </div>
          <div class="field field--inline" style="flex: 1; min-width: 200px">
            <span class="field__label">关键词</span>
            <input v-model="keyword" class="input" style="flex: 1" placeholder="农药名称 / 操作人 / 施用方式" />
          </div>
          <button class="btn btn--sm" type="button" @click="resetFilters">重置</button>
        </div>

        <div v-if="filteredRows.length === 0" class="empty">
          <div class="empty__mark">药</div>
          未找到符合条件的农药使用记录
        </div>
        <div v-else class="table-wrap">
          <table class="data-table">
            <thead>
              <tr>
                <th>日期</th>
                <th>地块</th>
                <th>作物</th>
                <th>农药名称</th>
                <th>用量</th>
                <th>操作人</th>
                <th>施用方式</th>
                <th>安全间隔期</th>
                <th>合规性</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <template v-for="item in filteredRows" :key="item.id">
                <tr :class="{ 'row--violation': !item.compliant }">
                  <td class="num">{{ item.date }}</td>
                  <td>{{ plotName(item.plot) }}</td>
                  <td>{{ item.crop }}</td>
                  <td class="cell-strong">{{ item.name }}</td>
                  <td class="num">{{ item.amount }}</td>
                  <td>{{ item.operator }}</td>
                  <td>{{ item.method }}</td>
                  <td class="num">{{ item.safetyDays }} 天</td>
                  <td><StatusTag :text="item.compliant ? '合规' : '违规'" :tone="item.compliant ? 'ok' : 'danger'" dot /></td>
                  <td><button class="link-action" type="button" @click="openDetail(item)">查看详情</button></td>
                </tr>
                <tr v-if="!item.compliant && item.note" class="row-note">
                  <td colspan="10">违规原因：{{ item.note }}</td>
                </tr>
              </template>
            </tbody>
          </table>
        </div>
      </div>
    </section>

    <AppModal v-model="detailOpen" title="农药使用记录详情" size="lg">
      <template v-if="detail">
        <div class="kv kv--3">
          <div class="kv__item"><span>记录编号</span><b>{{ detail.id }}</b></div>
          <div class="kv__item"><span>施用日期</span><b>{{ detail.date }}</b></div>
          <div class="kv__item"><span>地块</span><b>{{ plotName(detail.plot) }}</b></div>
          <div class="kv__item"><span>作物</span><b>{{ detail.crop }}</b></div>
          <div class="kv__item"><span>农药名称</span><b>{{ detail.name }}</b></div>
          <div class="kv__item"><span>使用量</span><b>{{ detail.amount }}</b></div>
          <div class="kv__item"><span>操作人</span><b>{{ detail.operator }}</b></div>
          <div class="kv__item"><span>施用方式</span><b>{{ detail.method }}</b></div>
          <div class="kv__item"><span>安全间隔期</span><b>{{ detail.safetyDays }} 天</b></div>
        </div>
        <div v-if="detail.compliant" class="notice notice--brand" style="margin-top: 16px">
          该记录符合农药安全间隔期与台账登记要求，无需整改。
        </div>
        <div v-else class="notice notice--danger" style="margin-top: 16px">
          该记录存在违规：{{ detail.note }}。请督促责任农户限期整改，并提交整改说明与复检申请。
        </div>
      </template>
      <template #footer>
        <button class="btn btn--primary" type="button" @click="detailOpen = false">关闭</button>
      </template>
    </AppModal>
  </div>
</template>

<style scoped>
.row--violation td {
  background: rgba(201, 62, 62, 0.05);
}

.row--violation td:first-child {
  box-shadow: inset 3px 0 0 var(--danger);
}

.row-note td {
  padding-top: 0;
  padding-bottom: 10px;
  border-bottom: 1px solid var(--line);
  color: var(--danger);
  font-size: 11.5px;
}

.row-note:hover td {
  background: transparent;
}
</style>
