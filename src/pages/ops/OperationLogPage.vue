<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import Pager from '@/components/ui/Pager.vue'
import { useToast } from '@/composables/useToast'
import { operationLogs } from '@/data/mock'
import type { LogRecord } from '@/data/types'
import { buildCsv, downloadText } from '@/utils/format'

const toast = useToast()
const todayKey = '2026-11-06'

const rows = ref<LogRecord[]>(operationLogs.map((item) => ({ ...item })))
const moduleFilter = ref('')
const resultFilter = ref('')
const keyword = ref('')
const dateFilter = ref('')
const page = ref(1)
const pageSize = 6

const moduleOptions = computed(() => Array.from(new Set(rows.value.map((item) => item.module))))

const filtered = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  return rows.value.filter((item) => {
    if (moduleFilter.value && item.module !== moduleFilter.value) return false
    if (resultFilter.value && item.result !== resultFilter.value) return false
    if (dateFilter.value && !item.time.startsWith(dateFilter.value)) return false
    if (!kw) return true
    return [item.account, item.name, item.action, item.detail ?? '', item.ip].some((field) => field.toLowerCase().includes(kw))
  })
})

const paged = computed(() => {
  const start = (page.value - 1) * pageSize
  return filtered.value.slice(start, start + pageSize)
})

watch([moduleFilter, resultFilter, keyword, dateFilter], () => {
  page.value = 1
})

const todayLogs = computed(() => rows.value.filter((item) => item.time.startsWith(todayKey)))
const todaySuccess = computed(() => todayLogs.value.filter((item) => item.result === '成功').length)
const todayFail = computed(() => todayLogs.value.filter((item) => item.result === '失败').length)

const detailTarget = ref<LogRecord | null>(null)
const detailOpen = computed({
  get: () => detailTarget.value !== null,
  set: (value: boolean) => {
    if (!value) detailTarget.value = null
  },
})

function openDetail(log: LogRecord) {
  detailTarget.value = log
}

function exportLogs() {
  const list = filtered.value.map((item) => [item.account, item.name, item.action, item.module, item.ip, item.time, item.result, item.detail ?? ''])
  downloadText('操作审计日志_20261106.csv', buildCsv(['账号', '姓名', '动作', '模块', 'IP', '时间', '结果', '详情'], list))
  toast.success(`已导出 ${list.length} 条操作日志`)
}

function auditDetail(log: LogRecord | null): string {
  if (!log) return ''
  return log.detail ?? '本次操作未记录扩展详情，可在服务端审计存储中查询完整上下文。'
}
</script>

<template>
  <div>
    <PageHeader eyebrow="OPERATION AUDIT" title="操作审计日志" description="记录关键业务与运维操作，支持按模块、结果与时间追溯责任人">
      <template #actions>
        <button class="btn" type="button" @click="moduleFilter = ''; resultFilter = ''; keyword = ''; dateFilter = ''">重置筛选</button>
        <button class="btn btn--primary" type="button" @click="exportLogs">导出审计日志</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="今日操作" :value="todayLogs.length" unit="次" icon="审" note="覆盖 5 个业务模块" trend="较昨日 +2" trend-up />
      <StatCard label="成功操作" :value="todaySuccess" unit="次" icon="成" note="指令执行与数据写入正常" trend="成功率 100%" trend-up />
      <StatCard label="失败操作" :value="todayFail" unit="次" icon="败" note="暂无失败记录" trend="无异常" />
      <StatCard label="审计留存" :value="180" unit="天" icon="留" note="满足等保合规要求" trend="自动归档" accent />
    </div>

    <section class="card">
      <div class="card__body" style="padding-bottom: 0">
        <div class="toolbar">
          <div class="field">
            <span class="field__label">模块</span>
            <select v-model="moduleFilter" class="select" style="width: 128px">
              <option value="">全部模块</option>
              <option v-for="module in moduleOptions" :key="module" :value="module">{{ module }}</option>
            </select>
          </div>
          <div class="field">
            <span class="field__label">结果</span>
            <select v-model="resultFilter" class="select" style="width: 108px">
              <option value="">全部结果</option>
              <option value="成功">成功</option>
              <option value="失败">失败</option>
            </select>
          </div>
          <div class="field" style="flex: 1; min-width: 180px">
            <span class="field__label">关键词</span>
            <input v-model="keyword" class="input" placeholder="搜索账号 / 动作 / 详情 / IP" />
          </div>
          <div class="field">
            <span class="field__label">日期</span>
            <input v-model="dateFilter" class="input" type="date" style="width: 168px" />
          </div>
          <div class="toolbar__spacer" />
          <span class="tag tag--brand" style="margin-top: 18px">{{ filtered.length }} 条</span>
        </div>

        <div class="table-wrap">
          <table class="data-table">
            <thead>
              <tr>
                <th>账号</th>
                <th>姓名</th>
                <th>动作</th>
                <th>模块</th>
                <th>IP 地址</th>
                <th>时间</th>
                <th>结果</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="log in paged" :key="log.id">
                <td class="cell-strong">{{ log.account }}</td>
                <td>{{ log.name }}</td>
                <td>{{ log.action }}</td>
                <td><span class="tag tag--info">{{ log.module }}</span></td>
                <td class="num">{{ log.ip }}</td>
                <td class="num">{{ log.time }}</td>
                <td><StatusTag :text="log.result" :tone="log.result === '成功' ? 'ok' : 'danger'" dot /></td>
                <td><button class="link-action" type="button" @click="openDetail(log)">详情</button></td>
              </tr>
              <tr v-if="paged.length === 0">
                <td colspan="8">
                  <div class="empty"><span class="empty__mark">空</span>没有符合条件的操作日志</div>
                </td>
              </tr>
            </tbody>
          </table>
          <Pager :total="filtered.length" :page="page" :page-size="pageSize" @update:page="page = $event" />
        </div>
      </div>
    </section>

    <AppModal v-model="detailOpen" title="操作审计详情" size="lg">
      <div v-if="detailTarget" class="kv kv--3">
        <div class="kv__item"><span>日志编号</span><b>{{ detailTarget.id }}</b></div>
        <div class="kv__item"><span>操作人</span><b>{{ detailTarget.name }}（{{ detailTarget.account }}）</b></div>
        <div class="kv__item"><span>操作模块</span><b>{{ detailTarget.module }}</b></div>
        <div class="kv__item"><span>操作动作</span><b>{{ detailTarget.action }}</b></div>
        <div class="kv__item"><span>来源 IP</span><b>{{ detailTarget.ip }}</b></div>
        <div class="kv__item"><span>操作时间</span><b>{{ detailTarget.time }}</b></div>
        <div class="kv__item"><span>执行结果</span><b>{{ detailTarget.result }}</b></div>
        <div class="kv__item"><span>操作耗时</span><b>0.42 s</b></div>
        <div class="kv__item"><span>会话编号</span><b>SES-8F2A-019</b></div>
      </div>
      <div class="field" style="margin-top: 16px">
        <span class="field__label">详情记录</span>
        <div class="notice notice--brand" style="display: block">
          <span>{{ auditDetail(detailTarget) }}</span>
        </div>
      </div>
      <div class="notice" style="margin-top: 12px">
        <span>审计日志仅允许追加，不支持修改与删除；如需取证可申请导出原始归档文件。</span>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="detailTarget = null">关闭</button>
      </template>
    </AppModal>
  </div>
</template>
