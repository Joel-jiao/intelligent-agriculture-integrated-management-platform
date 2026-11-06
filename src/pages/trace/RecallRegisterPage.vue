<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { batches, recalls } from '@/data/mock'
import type { RecallRecord } from '@/data/types'
import { buildCsv, downloadText, formatNumber, nowDateTime, today } from '@/utils/format'

const toast = useToast()

const rows = ref<RecallRecord[]>(recalls.map((item) => ({ ...item })))

const statusFilter = ref('全部')
const levelFilter = ref('全部')
const statusOptions = ['全部', '通知中', '召回中', '已完成']
const levelOptions = ['全部', '一级', '二级']

const filtered = computed(() =>
  rows.value.filter((row) => {
    const matchStatus = statusFilter.value === '全部' || row.status === statusFilter.value
    const matchLevel = levelFilter.value === '全部' || row.level === levelFilter.value
    return matchStatus && matchLevel
  }),
)

const affectedTotal = computed(() => rows.value.reduce((sum, item) => sum + item.affected, 0))
const recoveredTotal = computed(() => rows.value.reduce((sum, item) => sum + item.recovered, 0))
const recoveryRate = computed(() =>
  affectedTotal.value === 0 ? 0 : (recoveredTotal.value / affectedTotal.value) * 100,
)

const createOpen = ref(false)
const form = reactive({
  batchNo: batches[0]?.batchNo ?? '',
  reason: '',
  level: '二级',
})
const selectedBatch = computed(() => batches.find((item) => item.batchNo === form.batchNo))

const detailOpen = ref(false)
const selected = ref<RecallRecord | null>(null)

function levelTone(level: RecallRecord['level']): 'danger' | 'warn' {
  return level === '一级' ? 'danger' : 'warn'
}

function statusTone(status: RecallRecord['status']): 'warn' | 'info' | 'ok' {
  if (status === '通知中') return 'warn'
  if (status === '召回中') return 'info'
  return 'ok'
}

function recoveryPercent(row: RecallRecord): number {
  if (row.affected <= 0) return 0
  return Math.min(100, Math.round((row.recovered / row.affected) * 100))
}

function openDetail(row: RecallRecord) {
  selected.value = row
  detailOpen.value = true
}

function createRecall() {
  if (!form.batchNo) {
    toast.error('请选择召回批次')
    return
  }
  if (!form.reason.trim()) {
    toast.error('请填写召回原因')
    return
  }
  if (rows.value.some((item) => item.batchNo === form.batchNo && item.status !== '已完成')) {
    toast.error('该批次已存在进行中的召回记录')
    return
  }
  const batch = selectedBatch.value
  rows.value.unshift({
    id: `RC-${String(rows.value.length + 1).padStart(2, '0')}`,
    batchNo: form.batchNo,
    crop: batch?.crop ?? '未知作物',
    reason: form.reason.trim(),
    level: form.level === '一级' ? '一级' : '二级',
    createdAt: nowDateTime(),
    affected: batch?.weight ?? 0,
    recovered: 0,
    status: '通知中',
  })
  createOpen.value = false
  form.reason = ''
  toast.success(`批次 ${form.batchNo} 召回登记已创建`)
}

function sendNotice(row: RecallRecord) {
  toast.success(`召回通知已发送：${row.batchNo} · ${formatNumber(row.affected)} 件，正在等待销售终端确认`)
}

function completeRecall(row: RecallRecord) {
  row.recovered = row.affected
  row.status = '已完成'
  toast.success(`批次 ${row.batchNo} 召回已完成，回收率 100%`)
}

function exportCsv() {
  const data = filtered.value.map((row) => [
    row.batchNo,
    row.crop,
    row.reason,
    row.level,
    row.createdAt,
    row.affected,
    row.recovered,
    `${recoveryPercent(row)}%`,
    row.status,
  ])
  downloadText(
    `产品召回登记_${today()}.csv`,
    buildCsv(['批次号', '作物', '召回原因', '等级', '登记时间', '受影响数量', '已回收数量', '回收进度', '状态'], data),
  )
  toast.success(`已导出 ${data.length} 条召回记录`)
}
</script>

<template>
  <div>
    <PageHeader
      eyebrow="RECALL"
      title="产品召回登记"
      description="登记问题批次召回信息，跟踪受影响数量与回收进度，保障食品安全闭环"
    >
      <template #actions>
        <button class="btn" type="button" @click="exportCsv">导出 CSV</button>
        <button class="btn btn--primary" type="button" @click="createOpen = true">新建召回</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="召回批次" :value="rows.length" unit="批" icon="召" note="一级召回 1 批 · 二级 2 批" accent />
      <StatCard label="受影响产品数量" :value="formatNumber(affectedTotal)" unit="件" icon="量" note="含在售与仓储数量" />
      <StatCard label="已回收数量" :value="formatNumber(recoveredTotal)" unit="件" icon="收" note="销售终端已确认回收" />
      <StatCard
        label="整体回收率"
        :value="formatNumber(recoveryRate, 1)"
        unit="%"
        icon="率"
        note="目标回收率 ≥ 95%"
        trend="较上周 +6.2%"
      />
    </div>

    <div class="toolbar">
      <div class="field field--inline">
        <span class="field__label">状态</span>
        <select v-model="statusFilter" class="select" style="width: 128px">
          <option v-for="item in statusOptions" :key="item" :value="item">{{ item }}</option>
        </select>
      </div>
      <div class="field field--inline">
        <span class="field__label">等级</span>
        <select v-model="levelFilter" class="select" style="width: 118px">
          <option v-for="item in levelOptions" :key="item" :value="item">{{ item }}</option>
        </select>
      </div>
      <div class="toolbar__spacer" />
      <span class="tag tag--brand">共 {{ filtered.length }} 条召回记录</span>
    </div>

    <section class="card">
      <div class="card__head">
        <div class="card__title">召回记录 <span class="card__sub">按登记时间倒序</span></div>
        <button class="link-action" type="button" @click="createOpen = true">登记新召回</button>
      </div>
      <div class="table-wrap" style="border: 0; border-radius: 0; margin-top: 14px">
        <table class="data-table">
          <thead>
            <tr>
              <th>批次号</th>
              <th>作物</th>
              <th>召回原因</th>
              <th>等级</th>
              <th>登记时间</th>
              <th>受影响</th>
              <th>已回收</th>
              <th>进度</th>
              <th>状态</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in filtered" :key="row.id">
              <td class="num cell-strong">{{ row.batchNo }}</td>
              <td>{{ row.crop }}</td>
              <td style="max-width: 300px; white-space: normal">{{ row.reason }}</td>
              <td><span class="tag" :class="`tag--${levelTone(row.level)}`">{{ row.level }}</span></td>
              <td class="num">{{ row.createdAt }}</td>
              <td class="num">{{ formatNumber(row.affected) }}</td>
              <td class="num">{{ formatNumber(row.recovered) }}</td>
              <td>
                <div class="progress-cell">
                  <div class="progress" style="flex: 1">
                    <div
                      class="progress__bar"
                      :class="{ 'progress__bar--warn': recoveryPercent(row) < 80 }"
                      :style="{ width: `${recoveryPercent(row)}%` }"
                    />
                  </div>
                  <b class="num">{{ recoveryPercent(row) }}%</b>
                </div>
              </td>
              <td><StatusTag :text="row.status" :tone="statusTone(row.status)" dot /></td>
              <td>
                <div class="table-actions">
                  <button class="link-action" type="button" @click="openDetail(row)">详情</button>
                  <button
                    v-if="row.status !== '已完成'"
                    class="link-action"
                    type="button"
                    @click="sendNotice(row)"
                  >
                    发送通知
                  </button>
                  <button
                    v-if="row.status !== '已完成'"
                    class="link-action"
                    type="button"
                    @click="completeRecall(row)"
                  >
                    完成召回
                  </button>
                </div>
              </td>
            </tr>
            <tr v-if="filtered.length === 0">
              <td colspan="10">
                <div class="empty">
                  <div class="empty__mark">空</div>
                  <span>没有符合筛选条件的召回记录</span>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <AppModal v-model="createOpen" title="新建产品召回" size="lg">
      <div class="form-grid">
        <label class="field">
          <span class="field__label">召回批次</span>
          <select v-model="form.batchNo" class="select">
            <option v-for="batch in batches" :key="batch.id" :value="batch.batchNo">
              {{ batch.batchNo }} · {{ batch.crop }} {{ batch.variety }}
            </option>
          </select>
        </label>
        <label class="field">
          <span class="field__label">召回等级</span>
          <select v-model="form.level" class="select">
            <option value="一级">一级（严重健康风险）</option>
            <option value="二级">二级（一般质量风险）</option>
          </select>
        </label>
        <div v-if="selectedBatch" class="field span-2">
          <div class="kv kv--3">
            <div class="kv__item"><span>作物 / 品种</span><b>{{ selectedBatch.crop }} / {{ selectedBatch.variety }}</b></div>
            <div class="kv__item"><span>采收日期</span><b>{{ selectedBatch.harvestedAt }}</b></div>
            <div class="kv__item"><span>受影响数量</span><b>{{ formatNumber(selectedBatch.weight) }} 件</b></div>
          </div>
        </div>
        <label class="field span-2">
          <span class="field__label">召回原因</span>
          <textarea
            v-model="form.reason"
            class="textarea"
            placeholder="说明质量问题、检测结果或运输异常情况，以及召回范围"
          />
        </label>
        <div class="field span-2">
          <div class="notice notice--warn">提交后将向销售终端发送召回通知，并自动建立回收进度台账。</div>
        </div>
      </div>
      <div class="form-foot">
        <button class="btn" type="button" @click="createOpen = false">取消</button>
        <button class="btn btn--primary" type="button" @click="createRecall">提交召回登记</button>
      </div>
    </AppModal>

    <AppModal v-model="detailOpen" title="召回详情" size="lg">
      <div v-if="selected">
        <div class="row row--between" style="margin-bottom: 14px">
          <div class="num" style="font-size: 15px; font-weight: 700">{{ selected.batchNo }}</div>
          <div class="row" style="gap: 6px">
            <span class="tag" :class="`tag--${levelTone(selected.level)}`">{{ selected.level }}</span>
            <StatusTag :text="selected.status" :tone="statusTone(selected.status)" dot />
          </div>
        </div>
        <div class="kv kv--3">
          <div class="kv__item"><span>作物</span><b>{{ selected.crop }}</b></div>
          <div class="kv__item"><span>登记时间</span><b>{{ selected.createdAt }}</b></div>
          <div class="kv__item"><span>受影响数量</span><b>{{ formatNumber(selected.affected) }} 件</b></div>
          <div class="kv__item"><span>已回收数量</span><b>{{ formatNumber(selected.recovered) }} 件</b></div>
          <div class="kv__item"><span>回收率</span><b>{{ formatNumber(recoveryPercent(selected), 1) }}%</b></div>
          <div class="kv__item"><span>召回等级</span><b>{{ selected.level }}召回</b></div>
        </div>
        <div style="margin-top: 16px">
          <div class="row row--between">
            <span class="field__label">回收进度</span>
            <b class="num">{{ recoveryPercent(selected) }}%</b>
          </div>
          <div class="progress" style="margin-top: 6px">
            <div
              class="progress__bar"
              :class="{ 'progress__bar--warn': recoveryPercent(selected) < 80 }"
              :style="{ width: `${recoveryPercent(selected)}%` }"
            />
          </div>
        </div>
        <div class="notice notice--warn" style="margin-top: 16px">
          <div>
            <b>召回原因</b>
            <div style="margin-top: 3px">{{ selected.reason }}</div>
          </div>
        </div>
      </div>
      <div class="form-foot">
        <button class="btn" type="button" @click="detailOpen = false">关闭</button>
        <button
          v-if="selected && selected.status !== '已完成'"
          class="btn"
          type="button"
          @click="selected && sendNotice(selected)"
        >
          发送召回通知
        </button>
        <button
          v-if="selected && selected.status !== '已完成'"
          class="btn btn--primary"
          type="button"
          @click="selected && completeRecall(selected)"
        >
          完成召回
        </button>
      </div>
    </AppModal>
  </div>
</template>

<style scoped>
.progress-cell {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 120px;
}

.progress-cell b {
  width: 34px;
  text-align: right;
  font-size: 11.5px;
}
</style>
