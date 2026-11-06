<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { supWarnings } from '@/data/mock'
import type { SupWarning } from '@/data/types'
import { buildCsv, downloadText } from '@/utils/format'

type Tone = 'ok' | 'warn' | 'danger' | 'info' | 'brand' | 'mute'
type WarningStatus = SupWarning['status']

const toast = useToast()
const warnings = reactive<SupWarning[]>(supWarnings.map((item) => ({ ...item })))

const typeFilter = ref('')
const levelFilter = ref('')
const statusFilter = ref('')
const keyword = ref('')

const pendingCount = computed(() => warnings.filter((item) => item.status === '待处理').length)
const handlingCount = computed(() => warnings.filter((item) => item.status === '处理中').length)
const closedCount = computed(() => warnings.filter((item) => item.status === '已办结').length)
const highCount = computed(() => warnings.filter((item) => item.level === '高').length)

const filteredRows = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  return warnings.filter((item) => {
    const matchType = !typeFilter.value || item.type === typeFilter.value
    const matchLevel = !levelFilter.value || item.level === levelFilter.value
    const matchStatus = !statusFilter.value || item.status === statusFilter.value
    const matchKeyword =
      !kw || [item.title, item.entity, item.type].some((value) => value.toLowerCase().includes(kw))
    return matchType && matchLevel && matchStatus && matchKeyword
  })
})

const detailOpen = ref(false)
const selectedId = ref('')
const selected = computed(() => warnings.find((item) => item.id === selectedId.value) ?? null)

const handleOpen = ref(false)
const handleId = ref('')
const handleComment = ref('')
const handleTarget = computed(() => warnings.find((item) => item.id === handleId.value) ?? null)

function openDetail(row: SupWarning) {
  selectedId.value = row.id
  detailOpen.value = true
}

function openHandle(row: SupWarning) {
  handleId.value = row.id
  handleComment.value = ''
  handleOpen.value = true
}

function handleFromDetail() {
  const row = selected.value
  if (!row) return
  detailOpen.value = false
  openHandle(row)
}

function submitHandle(next: WarningStatus) {
  const target = handleTarget.value
  if (!target) return
  const comment = handleComment.value.trim()
  if (!comment) {
    toast.warn('请填写处置意见后再提交')
    return
  }
  target.status = next
  handleOpen.value = false
  toast.success(`预警 ${target.id} 已${next === '已办结' ? '办结' : '转入处理中'}`)
}

function resetFilters() {
  typeFilter.value = ''
  levelFilter.value = ''
  statusFilter.value = ''
  keyword.value = ''
  toast.info('筛选条件已重置')
}

function exportCsv() {
  const rows = filteredRows.value.map((item) => [
    item.id,
    item.title,
    item.type,
    item.entity,
    item.level,
    item.createdAt,
    item.status,
  ])
  downloadText(
    '辖区监管预警_20261106.csv',
    buildCsv(['预警编号', '预警内容', '类型', '主体', '等级', '时间', '状态'], rows),
  )
  toast.success(`已导出 ${rows.length} 条监管预警`)
}

function levelTone(level: string): Tone {
  if (level === '高') return 'danger'
  if (level === '中') return 'warn'
  return 'info'
}

function statusTone(status: string): Tone {
  if (status === '待处理') return 'warn'
  if (status === '处理中') return 'brand'
  return 'ok'
}
</script>

<template>
  <div>
    <PageHeader
      eyebrow="SUPERVISION WARNING"
      title="监管预警管理"
      description="质量异常、农事违规、设备告警与台账缺失预警的受理与闭环处置"
    >
      <template #actions>
        <button class="btn" type="button" @click="resetFilters">重置筛选</button>
        <button class="btn btn--primary" type="button" @click="exportCsv">导出 CSV</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="待处理" :value="pendingCount" unit="条" icon="待" note="需在 24 小时内响应" trend="较昨日 -1" trend-up />
      <StatCard label="处理中" :value="handlingCount" unit="条" icon="中" note="已指派处置责任人" />
      <StatCard label="已办结" :value="closedCount" unit="条" icon="结" note="本月累计办结" trend="办结率 33%" />
      <StatCard label="高危预警" :value="highCount" unit="条" icon="危" note="质量异常类占比最高" accent />
    </div>

    <section class="card">
      <div class="card__head">
        <div class="card__title">预警列表 <span class="card__sub">共 {{ filteredRows.length }} 条</span></div>
        <span class="tag tag--outline">本地处置状态实时联动</span>
      </div>
      <div class="card__body">
        <div class="toolbar">
          <div class="field field--inline">
            <span class="field__label">类型</span>
            <select v-model="typeFilter" class="select" style="width: 130px">
              <option value="">全部类型</option>
              <option value="质量异常">质量异常</option>
              <option value="农事违规">农事违规</option>
              <option value="设备告警">设备告警</option>
              <option value="台账缺失">台账缺失</option>
            </select>
          </div>
          <div class="field field--inline">
            <span class="field__label">等级</span>
            <select v-model="levelFilter" class="select" style="width: 110px">
              <option value="">全部等级</option>
              <option value="高">高</option>
              <option value="中">中</option>
              <option value="低">低</option>
            </select>
          </div>
          <div class="field field--inline">
            <span class="field__label">状态</span>
            <select v-model="statusFilter" class="select" style="width: 120px">
              <option value="">全部状态</option>
              <option value="待处理">待处理</option>
              <option value="处理中">处理中</option>
              <option value="已办结">已办结</option>
            </select>
          </div>
          <div class="field field--inline" style="flex: 1; min-width: 190px">
            <span class="field__label">关键词</span>
            <input v-model="keyword" class="input" style="flex: 1" placeholder="预警内容 / 主体" />
          </div>
          <button class="btn btn--sm" type="button" @click="resetFilters">重置</button>
        </div>

        <div v-if="filteredRows.length === 0" class="empty">
          <div class="empty__mark">警</div>
          当前筛选条件下没有预警记录
        </div>
        <div v-else class="table-wrap">
          <table class="data-table">
            <thead>
              <tr>
                <th>预警内容</th>
                <th>类型</th>
                <th>主体</th>
                <th>等级</th>
                <th>时间</th>
                <th>状态</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in filteredRows" :key="item.id">
                <td class="cell-strong">{{ item.title }}</td>
                <td>{{ item.type }}</td>
                <td class="cell-muted">{{ item.entity }}</td>
                <td><StatusTag :text="item.level" :tone="levelTone(item.level)" dot /></td>
                <td class="num cell-muted">{{ item.createdAt }}</td>
                <td><StatusTag :text="item.status" :tone="statusTone(item.status)" /></td>
                <td>
                  <div class="table-actions">
                    <button class="link-action" type="button" @click="openHandle(item)">
                      {{ item.status === '已办结' ? '补充处置' : '处置' }}
                    </button>
                    <button class="link-action" type="button" @click="openDetail(item)">详情</button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>

    <AppModal v-model="handleOpen" :title="`预警处置 · ${handleTarget?.id ?? ''}`">
      <template v-if="handleTarget">
        <div class="kv" style="margin-bottom: 14px">
          <div class="kv__item"><span>预警内容</span><b>{{ handleTarget.title }}</b></div>
          <div class="kv__item"><span>预警类型</span><b>{{ handleTarget.type }}</b></div>
          <div class="kv__item"><span>预警等级</span><b>{{ handleTarget.level }}</b></div>
          <div class="kv__item"><span>当前状态</span><b>{{ handleTarget.status }}</b></div>
        </div>
        <div class="notice notice--warn" style="margin-bottom: 14px">
          处置意见将记入监管台账，办结后预警不可再次退回待处理状态，请确认处置措施已落实。
        </div>
        <div class="field">
          <span class="field__label">处置意见</span>
          <textarea
            v-model="handleComment"
            class="textarea"
            placeholder="请填写现场核查情况、整改要求与处置结果"
          />
        </div>
      </template>
      <template #footer>
        <button class="btn" type="button" @click="handleOpen = false">取消</button>
        <button class="btn" type="button" @click="submitHandle('处理中')">转处理中</button>
        <button class="btn btn--primary" type="button" @click="submitHandle('已办结')">标记已办结</button>
      </template>
    </AppModal>

    <AppModal v-model="detailOpen" title="预警详情" size="lg">
      <template v-if="selected">
        <div class="kv kv--3">
          <div class="kv__item"><span>预警编号</span><b>{{ selected.id }}</b></div>
          <div class="kv__item"><span>预警类型</span><b>{{ selected.type }}</b></div>
          <div class="kv__item"><span>预警等级</span><b>{{ selected.level }}</b></div>
          <div class="kv__item span-2"><span>预警内容</span><b>{{ selected.title }}</b></div>
          <div class="kv__item"><span>当前状态</span><b>{{ selected.status }}</b></div>
          <div class="kv__item span-2"><span>监管主体</span><b>{{ selected.entity }}</b></div>
          <div class="kv__item"><span>产生时间</span><b>{{ selected.createdAt }}</b></div>
        </div>
        <div
          class="notice"
          :class="selected.level === '高' ? 'notice--danger' : 'notice--warn'"
          style="margin-top: 16px"
        >
          {{ selected.level === '高'
            ? '该预警为高危级别，需监管人员现场核查并留存整改证据，处置完成后及时办结。'
            : '该预警需按辖区监管要求跟进处置，并在规定时限内完成闭环。' }}
        </div>
      </template>
      <template #footer>
        <button class="btn" type="button" @click="detailOpen = false">关闭</button>
        <button v-if="selected" class="btn btn--primary" type="button" @click="handleFromDetail">立即处置</button>
      </template>
    </AppModal>
  </div>
</template>
