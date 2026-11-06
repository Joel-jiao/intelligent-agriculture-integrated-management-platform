<script setup lang="ts">
import { computed, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { loginLogs } from '@/data/mock'
import type { LogRecord } from '@/data/types'
import { buildCsv, downloadText, nowDateTime } from '@/utils/format'

const toast = useToast()
const todayKey = '2026-11-06'

const rows = ref<LogRecord[]>(loginLogs.map((item) => ({ ...item })))
const keyword = ref('')
const resultFilter = ref('')
const dateFilter = ref('')
const lastRefresh = ref('2026-11-06 09:42')

const filtered = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  return rows.value.filter((item) => {
    if (resultFilter.value && item.result !== resultFilter.value) return false
    if (dateFilter.value && !item.time.startsWith(dateFilter.value)) return false
    if (!kw) return true
    return [item.account, item.name, item.ip, item.module].some((field) => field.toLowerCase().includes(kw))
  })
})

const todayLogs = computed(() => rows.value.filter((item) => item.time.startsWith(todayKey)))
const todayLogin = computed(() => todayLogs.value.filter((item) => item.action.includes('登录')).length)
const todayFail = computed(() => todayLogs.value.filter((item) => item.result === '失败').length)
const uniqueAccounts = computed(() => new Set(todayLogs.value.map((item) => item.account)).size)

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

function failureReason(log: LogRecord | null): string {
  if (!log || log.result !== '失败') return '登录校验通过，会话令牌已正常签发'
  if (log.module === '接口') return '请求携带的令牌已过期或签名无效，系统已拦截并记录来源 IP'
  return '账号或密码校验失败，已计入风控失败次数，连续 5 次将锁定账号 30 分钟'
}

function refresh() {
  lastRefresh.value = nowDateTime()
  toast.success('登录日志已刷新至最新记录')
}

function exportLogs() {
  const list = filtered.value.map((item) => [item.account, item.name, item.action, item.module, item.ip, item.time, item.result])
  downloadText('登录日志_20261106.csv', buildCsv(['账号', '姓名', '动作', '模块', 'IP', '时间', '结果'], list))
  toast.success(`已导出 ${list.length} 条登录日志`)
}
</script>

<template>
  <div>
    <PageHeader eyebrow="LOGIN AUDIT" title="登录日志" description="记录各业务端的登录、退出与失败尝试，用于账号安全排查与合规审计">
      <template #actions>
        <button class="btn" type="button" @click="refresh">刷新日志</button>
        <button class="btn btn--primary" type="button" @click="exportLogs">导出 CSV</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="今日登录" :value="todayLogin" unit="次" icon="登" note="管理员端 2 · 运维端 1" trend="较昨日 +1" trend-up />
      <StatCard label="失败次数" :value="todayFail" unit="次" icon="败" note="密码错误 1 次" trend="风控已记录" />
      <StatCard label="独立账号" :value="uniqueAccounts" unit="个" icon="账" note="覆盖 4 个业务端" trend="全部实名" />
      <StatCard label="最近刷新" :value="lastRefresh.slice(11)" icon="时" note="日志实时写入" trend="自动同步" accent />
    </div>

    <section class="card">
      <div class="card__body" style="padding-bottom: 0">
        <div class="toolbar">
          <div class="field" style="flex: 1; min-width: 180px">
            <span class="field__label">关键词</span>
            <input v-model="keyword" class="input" placeholder="搜索账号 / 姓名 / IP / 模块" />
          </div>
          <div class="field">
            <span class="field__label">结果</span>
            <select v-model="resultFilter" class="select" style="width: 108px">
              <option value="">全部结果</option>
              <option value="成功">成功</option>
              <option value="失败">失败</option>
            </select>
          </div>
          <div class="field">
            <span class="field__label">日期</span>
            <input v-model="dateFilter" class="input" type="date" style="width: 168px" />
          </div>
          <button class="btn btn--sm" type="button" style="margin-top: 18px" @click="keyword = ''; resultFilter = ''; dateFilter = ''">重置</button>
          <div class="toolbar__spacer" />
          <span class="tag tag--brand" style="margin-top: 18px">{{ filtered.length }} 条记录</span>
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
              <tr v-for="log in filtered" :key="log.id" :class="{ 'row--danger': log.result === '失败' }">
                <td class="cell-strong">{{ log.account }}</td>
                <td>{{ log.name }}</td>
                <td>{{ log.action }}</td>
                <td><span class="tag">{{ log.module }}</span></td>
                <td class="num">{{ log.ip }}</td>
                <td class="num">{{ log.time }}</td>
                <td><StatusTag :text="log.result" :tone="log.result === '成功' ? 'ok' : 'danger'" dot /></td>
                <td><button class="link-action" type="button" @click="openDetail(log)">查看详情</button></td>
              </tr>
              <tr v-if="filtered.length === 0">
                <td colspan="8">
                  <div class="empty"><span class="empty__mark">空</span>没有匹配的登录日志</div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>

    <AppModal v-model="detailOpen" title="登录日志详情" size="lg">
      <div v-if="detailTarget" class="kv kv--3">
        <div class="kv__item"><span>日志编号</span><b>{{ detailTarget.id }}</b></div>
        <div class="kv__item"><span>账号</span><b>{{ detailTarget.account }}</b></div>
        <div class="kv__item"><span>姓名</span><b>{{ detailTarget.name }}</b></div>
        <div class="kv__item"><span>动作</span><b>{{ detailTarget.action }}</b></div>
        <div class="kv__item"><span>模块</span><b>{{ detailTarget.module }}</b></div>
        <div class="kv__item"><span>结果</span><b>{{ detailTarget.result }}</b></div>
        <div class="kv__item"><span>IP 地址</span><b>{{ detailTarget.ip }}</b></div>
        <div class="kv__item"><span>时间</span><b>{{ detailTarget.time }}</b></div>
        <div class="kv__item"><span>客户端</span><b>Chrome 130 · Windows 11</b></div>
      </div>
      <div class="notice" :class="detailTarget?.result === '失败' ? 'notice--danger' : 'notice--brand'" style="margin-top: 16px">
        <span>{{ failureReason(detailTarget) }}</span>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="detailTarget = null">关闭</button>
      </template>
    </AppModal>
  </div>
</template>

<style scoped>
.row--danger td {
  background: #fdf4f4;
}

.row--danger td:first-child {
  box-shadow: inset 3px 0 0 var(--danger);
}

.row--danger:hover td {
  background: #fbeaea;
}
</style>
