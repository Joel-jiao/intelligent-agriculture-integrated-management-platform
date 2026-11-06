<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { alarms, plotName } from '@/data/mock'
import type { Alarm, AlarmLevel, AlarmStatus } from '@/data/types'
import { buildCsv, downloadText, today } from '@/utils/format'

interface AlarmRow extends Alarm {
  started: boolean
  remark: string
}

const toast = useToast()

const alarmRows = reactive<AlarmRow[]>(
  alarms.map((item) => ({
    ...item,
    started: item.status === '处置中',
    remark: item.status === '已归档' ? '现场已恢复，告警闭环归档。' : '',
  })),
)

const tab = ref<'current' | 'history'>('current')
const levelFilter = ref('全部')
const statusFilter = ref('全部')
const keyword = ref('')
const dateFilter = ref('')

const levelOptions = ['全部', '紧急', '重要', '一般']
const statusOptions = ['全部', '待确认', '处置中', '已归档']

const currentRows = computed(() => alarmRows.filter((item) => item.status !== '已归档'))
const historyRows = computed(() => alarmRows.filter((item) => item.status === '已归档'))

const filtered = computed(() => {
  const source = tab.value === 'current' ? currentRows.value : historyRows.value
  const text = keyword.value.trim().toLowerCase()
  return source.filter((row) => {
    const matchLevel = levelFilter.value === '全部' || row.level === levelFilter.value
    const matchStatus = statusFilter.value === '全部' || row.status === statusFilter.value
    const matchDate = !dateFilter.value || row.createdAt.slice(0, 10) === dateFilter.value
    const matchKeyword =
      !text ||
      [row.id, row.title, row.source, row.plot, plotName(row.plot), row.device].some((value) =>
        value.toLowerCase().includes(text),
      )
    return matchLevel && matchStatus && matchDate && matchKeyword
  })
})

const urgentCount = computed(() => currentRows.value.filter((item) => item.level === '紧急').length)
const importantCount = computed(() => currentRows.value.filter((item) => item.level === '重要').length)
const waitingCount = computed(() => alarmRows.filter((item) => item.status === '待确认').length)
const archivedCount = computed(() => alarmRows.filter((item) => item.status === '已归档').length)

const detailOpen = ref(false)
const selectedId = ref('')
const selected = computed(() => alarmRows.find((item) => item.id === selectedId.value))
const remarkDraft = ref('')

function levelTone(level: AlarmLevel): 'danger' | 'warn' | 'info' {
  if (level === '紧急') return 'danger'
  if (level === '重要') return 'warn'
  return 'info'
}

function statusTone(status: AlarmStatus): 'warn' | 'brand' | 'ok' {
  if (status === '待确认') return 'warn'
  if (status === '处置中') return 'brand'
  return 'ok'
}

function openDetail(row: AlarmRow) {
  selectedId.value = row.id
  remarkDraft.value = row.remark
  detailOpen.value = true
}

function saveRemark() {
  if (!selected.value) return
  selected.value.remark = remarkDraft.value.trim()
  toast.success('处置备注已保存')
}

function confirmAlarm() {
  const row = selected.value
  if (!row) return
  row.status = '处置中'
  row.started = false
  row.handler = '李明'
  row.remark = remarkDraft.value.trim() || '已确认告警，转入现场处置。'
  toast.success(`告警 ${row.id} 已确认，转入处置中`)
}

function startAlarm() {
  const row = selected.value
  if (!row) return
  row.started = true
  row.handler = '李明'
  row.remark = remarkDraft.value.trim() || '已开始现场处置，等待设备恢复。'
  toast.success(`告警 ${row.id} 已开始处置，处置人李明`)
}

function archiveAlarm() {
  const row = selected.value
  if (!row) return
  row.status = '已归档'
  row.started = true
  row.remark = remarkDraft.value.trim() || row.remark
  detailOpen.value = false
  toast.success(`告警 ${row.id} 已归档，闭环完成`)
}

function resetFilters() {
  levelFilter.value = '全部'
  statusFilter.value = '全部'
  keyword.value = ''
  dateFilter.value = ''
  toast.info('筛选条件已重置')
}

function exportCsv() {
  const data = filtered.value.map((row) => [
    row.id,
    row.level,
    row.title,
    row.source,
    plotName(row.plot),
    row.createdAt,
    row.status,
    row.handler,
    row.value,
    row.threshold,
  ])
  downloadText(
    `告警处理_${today()}.csv`,
    buildCsv(['告警编号', '级别', '标题', '来源', '地块', '发生时间', '状态', '处置人', '当前值', '阈值'], data),
  )
  toast.success(`已导出 ${data.length} 条告警记录`)
}
</script>

<template>
  <div>
    <PageHeader
      eyebrow="ALARM CENTER"
      title="告警信息处理"
      description="统一接收设备、环境、视频与能耗告警，按级别分级处置并形成闭环记录"
    >
      <template #actions>
        <button class="btn" type="button" @click="resetFilters">重置筛选</button>
        <button class="btn btn--primary" type="button" @click="exportCsv">导出 CSV</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="紧急告警待处置" :value="urgentCount" unit="条" icon="急" note="需 30 分钟内响应" accent />
      <StatCard label="重要告警待处置" :value="importantCount" unit="条" icon="重" note="需 2 小时内响应" />
      <StatCard label="待确认告警" :value="waitingCount" unit="条" icon="确" note="尚未指派处置人" />
      <StatCard label="已归档告警" :value="archivedCount" unit="条" icon="档" note="本月闭环记录" trend="闭环率 62%" />
    </div>

    <div class="toolbar">
      <div class="tabs">
        <button class="tab" :class="{ 'tab--active': tab === 'current' }" type="button" @click="tab = 'current'">
          待处置告警 {{ currentRows.length }}
        </button>
        <button class="tab" :class="{ 'tab--active': tab === 'history' }" type="button" @click="tab = 'history'">
          历史告警 {{ historyRows.length }}
        </button>
      </div>
      <div class="field field--inline">
        <span class="field__label">级别</span>
        <select v-model="levelFilter" class="select" style="width: 108px">
          <option v-for="item in levelOptions" :key="item" :value="item">{{ item }}</option>
        </select>
      </div>
      <div class="field field--inline">
        <span class="field__label">状态</span>
        <select v-model="statusFilter" class="select" style="width: 108px">
          <option v-for="item in statusOptions" :key="item" :value="item">{{ item }}</option>
        </select>
      </div>
      <div class="field field--inline">
        <span class="field__label">日期</span>
        <input v-model="dateFilter" class="input" type="date" style="width: 148px" />
      </div>
      <div class="field field--inline" style="flex: 1; min-width: 190px">
        <span class="field__label">关键词</span>
        <input v-model="keyword" class="input" type="search" placeholder="搜索标题、来源、地块或设备" />
      </div>
      <div class="toolbar__spacer" />
      <span class="tag tag--brand">共 {{ filtered.length }} 条</span>
    </div>

    <section class="card">
      <div class="card__head">
        <div class="card__title">
          {{ tab === 'current' ? '待处置告警' : '历史告警' }}
          <span class="card__sub">按发生时间倒序</span>
        </div>
        <div class="legend">
          <span><i style="background: #c93e3e" />紧急</span>
          <span><i style="background: #c47f17" />重要</span>
          <span><i style="background: #2f6fae" />一般</span>
        </div>
      </div>
      <div class="table-wrap" style="border: 0; border-radius: 0; margin-top: 14px">
        <table class="data-table">
          <thead>
            <tr>
              <th>级别</th>
              <th>告警标题</th>
              <th>来源</th>
              <th>地块</th>
              <th>发生时间</th>
              <th>状态</th>
              <th>处置人</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in filtered" :key="row.id">
              <td><span class="tag" :class="`tag--${levelTone(row.level)}`">{{ row.level }}</span></td>
              <td>
                <div class="cell-strong">{{ row.title }}</div>
                <div class="cell-muted" style="font-size: 10.5px">{{ row.id }} · {{ row.device }}</div>
              </td>
              <td>{{ row.source }}</td>
              <td>{{ plotName(row.plot) }}<span class="cell-muted">（{{ row.plot }}）</span></td>
              <td class="num">{{ row.createdAt }}</td>
              <td><StatusTag :text="row.status" :tone="statusTone(row.status)" dot /></td>
              <td>{{ row.handler }}</td>
              <td>
                <button class="link-action" type="button" @click="openDetail(row)">
                  {{ row.status === '已归档' ? '查看' : '处理' }}
                </button>
              </td>
            </tr>
            <tr v-if="filtered.length === 0">
              <td colspan="8">
                <div class="empty">
                  <div class="empty__mark">空</div>
                  <span>没有符合筛选条件的告警记录</span>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <AppModal v-model="detailOpen" title="告警处置" size="lg">
      <div v-if="selected">
        <div class="row row--between" style="margin-bottom: 14px; align-items: flex-start">
          <div>
            <div style="font-size: 15px; font-weight: 700">{{ selected.title }}</div>
            <div class="cell-muted" style="font-size: 11.5px">{{ selected.id }} · {{ selected.source }} · {{ selected.createdAt }}</div>
          </div>
          <div class="row" style="gap: 6px">
            <span class="tag" :class="`tag--${levelTone(selected.level)}`">{{ selected.level }}</span>
            <StatusTag :text="selected.status" :tone="statusTone(selected.status)" dot />
          </div>
        </div>

        <div class="alarm-compare">
          <div class="alarm-compare__item">
            <span>当前值</span>
            <b>{{ selected.value }}</b>
          </div>
          <div class="alarm-compare__arrow">对比</div>
          <div class="alarm-compare__item alarm-compare__item--threshold">
            <span>告警阈值</span>
            <b>{{ selected.threshold }}</b>
          </div>
        </div>

        <div class="kv kv--3" style="margin-top: 16px">
          <div class="kv__item"><span>来源</span><b>{{ selected.source }}</b></div>
          <div class="kv__item"><span>关联设备</span><b>{{ selected.device }}</b></div>
          <div class="kv__item"><span>地块</span><b>{{ plotName(selected.plot) }}</b></div>
          <div class="kv__item"><span>发生时间</span><b>{{ selected.createdAt }}</b></div>
          <div class="kv__item"><span>处置人</span><b>{{ selected.handler }}</b></div>
          <div class="kv__item"><span>当前状态</span><b>{{ selected.status }}</b></div>
        </div>

        <div class="card__title" style="margin: 18px 0 10px; padding-left: 2px">处置流程</div>
        <div class="timeline">
          <div class="timeline__item timeline__item--done">
            <div class="timeline__title">告警触发</div>
            <div class="timeline__desc">{{ selected.value }}，触发规则「{{ selected.threshold }}」</div>
          </div>
          <div
            class="timeline__item"
            :class="{
              'timeline__item--done': selected.status !== '待确认',
              'timeline__item--active': selected.status === '待确认',
            }"
          >
            <div class="timeline__title">确认告警</div>
            <div class="timeline__desc">{{ selected.status === '待确认' ? '等待管理员确认' : `已由 ${selected.handler} 确认` }}</div>
          </div>
          <div
            class="timeline__item"
            :class="{
              'timeline__item--done': selected.started || selected.status === '已归档',
              'timeline__item--active': selected.status === '处置中' && !selected.started,
            }"
          >
            <div class="timeline__title">开始处置</div>
            <div class="timeline__desc">{{ selected.started ? '现场处置已开始' : '等待开始现场处置' }}</div>
          </div>
          <div
            class="timeline__item"
            :class="{
              'timeline__item--done': selected.status === '已归档',
              'timeline__item--active': selected.status === '处置中' && selected.started,
            }"
          >
            <div class="timeline__title">归档闭环</div>
            <div class="timeline__desc">{{ selected.status === '已归档' ? '告警已归档，记录已留档' : '处置完成后归档' }}</div>
          </div>
        </div>

        <label class="field" style="margin-top: 16px">
          <span class="field__label">处置备注</span>
          <textarea
            v-model="remarkDraft"
            class="textarea"
            placeholder="记录现场排查过程、处理措施与结果"
            :disabled="selected.status === '已归档'"
          />
        </label>
        <div class="notice notice--brand" style="margin-top: 10px">
          已归档告警保留完整处置记录，可在历史告警中查询。
        </div>
      </div>
      <div class="form-foot">
        <button class="btn" type="button" @click="detailOpen = false">关闭</button>
        <button v-if="selected && selected.status !== '已归档'" class="btn" type="button" @click="saveRemark">
          保存备注
        </button>
        <button
          v-if="selected && selected.status === '待确认'"
          class="btn btn--primary"
          type="button"
          @click="confirmAlarm"
        >
          确认告警
        </button>
        <button
          v-if="selected && selected.status === '处置中' && !selected.started"
          class="btn btn--primary"
          type="button"
          @click="startAlarm"
        >
          开始处置
        </button>
        <button
          v-if="selected && selected.status === '处置中' && selected.started"
          class="btn btn--primary"
          type="button"
          @click="archiveAlarm"
        >
          归档
        </button>
      </div>
    </AppModal>
  </div>
</template>

<style scoped>
.alarm-compare {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: var(--surface-2);
}

.alarm-compare__item {
  flex: 1;
  min-width: 0;
}

.alarm-compare__item span {
  display: block;
  font-size: 11px;
  color: var(--muted);
}

.alarm-compare__item b {
  display: block;
  margin-top: 2px;
  font-size: 17px;
  color: var(--danger);
  font-family: var(--font-num);
}

.alarm-compare__item--threshold b {
  color: var(--ink);
  font-size: 14px;
}

.alarm-compare__arrow {
  flex: 0 0 auto;
  padding: 3px 8px;
  border-radius: 12px;
  background: #fff;
  border: 1px solid var(--line);
  font-size: 10.5px;
  color: var(--muted);
}
</style>
