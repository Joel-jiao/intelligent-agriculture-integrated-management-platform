<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import Pager from '@/components/ui/Pager.vue'
import { useToast } from '@/composables/useToast'
import { findPlot, plots, workOrders as seedWorkOrders } from '@/data/mock'
import type { WorkOrder } from '@/data/types'
import { buildCsv, downloadText, nowDateTime, pad } from '@/utils/format'

const toast = useToast()

const plotsForForm = plots
const orderList = ref<WorkOrder[]>(seedWorkOrders.map((item) => ({ ...item })))

const keyword = ref('')
const statusFilter = ref('全部')
const priorityFilter = ref('全部')
const assigneeFilter = ref('全部')
const plotFilter = ref('全部')

const statusTabs = ['全部', '待接单', '进行中', '待验收', '已完成']

const page = ref(1)
const pageSize = 8

const farmers = [
  { name: '王强', phone: '139****8832' },
  { name: '赵敏', phone: '137****4109' },
  { name: '陈刚', phone: '138****6210' },
  { name: '刘洋', phone: '136****7521' },
  { name: '周涛', phone: '135****3390' },
]
const orderTypes = ['采收作业', '植株管理', '设备巡检', '水肥管理', '植保作业', '设施维护']

const assigneeOptions = computed(() => Array.from(new Set(orderList.value.map((item) => item.assignee))))
const plotOptions = computed(() => Array.from(new Set(orderList.value.map((item) => item.plot))))

watch([keyword, statusFilter, priorityFilter, assigneeFilter, plotFilter], () => {
  page.value = 1
})

const filteredOrders = computed(() =>
  orderList.value.filter((order) => {
    if (statusFilter.value !== '全部' && order.status !== statusFilter.value) return false
    if (priorityFilter.value !== '全部' && order.priority !== priorityFilter.value) return false
    if (assigneeFilter.value !== '全部' && order.assignee !== assigneeFilter.value) return false
    if (plotFilter.value !== '全部' && order.plot !== plotFilter.value) return false
    if (!keyword.value.trim()) return true
    const key = keyword.value.trim()
    return order.id.includes(key) || order.title.includes(key) || order.type.includes(key) || order.assignee.includes(key)
  }),
)

const pagedOrders = computed(() => {
  const start = (page.value - 1) * pageSize
  return filteredOrders.value.slice(start, start + pageSize)
})

const statusCounts = computed(() => ({
  total: orderList.value.length,
  pending: orderList.value.filter((item) => item.status === '待接单').length,
  doing: orderList.value.filter((item) => item.status === '进行中').length,
  reviewing: orderList.value.filter((item) => item.status === '待验收').length,
  done: orderList.value.filter((item) => item.status === '已完成').length,
}))

function statusTone(status: WorkOrder['status']): 'ok' | 'warn' | 'brand' | 'info' {
  if (status === '待接单') return 'warn'
  if (status === '进行中') return 'brand'
  if (status === '待验收') return 'info'
  return 'ok'
}

function priorityTone(priority: WorkOrder['priority']): 'danger' | 'warn' | 'mute' {
  if (priority === '高') return 'danger'
  if (priority === '中') return 'warn'
  return 'mute'
}

const modalOpen = ref(false)
const form = ref({
  title: '',
  plot: 'P-01',
  type: '植株管理',
  assignee: '王强',
  deadline: '2026-11-07 18:00',
  priority: '中',
  requirement: '',
})

function nextOrderId(): string {
  const prefix = 'WO-20261106-'
  const max = orderList.value.reduce((acc, order) => {
    if (!order.id.startsWith(prefix)) return acc
    const value = Number(order.id.slice(prefix.length))
    return Number.isNaN(value) ? acc : Math.max(acc, value)
  }, 0)
  return `${prefix}${pad(max + 1)}`
}

function openCreate() {
  form.value = {
    title: '',
    plot: 'P-01',
    type: '植株管理',
    assignee: '王强',
    deadline: '2026-11-07 18:00',
    priority: '中',
    requirement: '',
  }
  modalOpen.value = true
}

function submitOrder() {
  if (!form.value.title.trim()) {
    toast.warn('请填写工单任务标题')
    return
  }
  if (!form.value.deadline.trim()) {
    toast.warn('请填写截止时间')
    return
  }
  const plot = findPlot(form.value.plot)
  const phone = farmers.find((item) => item.name === form.value.assignee)?.phone ?? '—'
  const created: WorkOrder = {
    id: nextOrderId(),
    title: form.value.title.trim(),
    plot: form.value.plot,
    crop: plot?.crop ?? '未指定',
    type: form.value.type,
    assignee: form.value.assignee,
    phone,
    createdAt: nowDateTime(),
    deadline: form.value.deadline.trim(),
    status: '待接单',
    priority: form.value.priority as WorkOrder['priority'],
    progress: 0,
    requirement: form.value.requirement.trim() || '按现场实际情况执行，作业完成后上传照片并提交验收。',
  }
  orderList.value.unshift(created)
  page.value = 1
  modalOpen.value = false
  toast.success(`工单 ${created.id} 已创建并派发给 ${created.assignee}`)
}

function acceptOrder(order: WorkOrder) {
  order.status = '进行中'
  order.progress = Math.max(order.progress, 10)
  toast.success(`工单 ${order.id} 已接单，请按作业要求执行`)
}

function urgeOrder(order: WorkOrder) {
  toast.info(`已向 ${order.assignee} 发送催办提醒，截止 ${order.deadline}`)
}

function submitOrderForReview(order: WorkOrder) {
  order.status = '待验收'
  order.progress = 100
  toast.success(`工单 ${order.id} 已提交验收，等待管理员确认`)
}

function approveOrder(order: WorkOrder) {
  order.status = '已完成'
  order.progress = 100
  toast.success(`工单 ${order.id} 验收通过，已归档`)
}

function exportOrders() {
  const rows = filteredOrders.value.map((order) => [
    order.id,
    order.title,
    findPlot(order.plot)?.name ?? order.plot,
    order.crop,
    order.type,
    order.assignee,
    order.deadline,
    order.priority,
    order.status,
    `${order.progress}%`,
  ])
  downloadText(
    '农事工单_20261106.csv',
    buildCsv(['工单编号', '任务', '地块', '作物', '类型', '负责人', '截止时间', '优先级', '状态', '进度'], rows),
  )
  toast.success(`已导出 ${rows.length} 条工单记录`)
}
</script>

<template>
  <div>
    <PageHeader eyebrow="FARM WORK ORDER" title="农事工单" description="工单派发、执行跟踪与验收闭环管理 · 今日新增 4 单">
      <template #actions>
        <button class="btn" type="button" @click="exportOrders">导出工单</button>
        <button class="btn btn--primary" type="button" @click="openCreate">新建工单</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="工单总数" :value="statusCounts.total" unit="单" icon="单" note="本月累计派发 9 单" trend="+12.5% 环比" />
      <StatCard label="待接单" :value="statusCounts.pending" unit="单" icon="待" note="超时未接单将自动提醒" trend="需关注" :trend-up="false" accent />
      <StatCard label="进行中" :value="statusCounts.doing" unit="单" icon="行" note="田间作业执行中" trend="按时率 96%" />
      <StatCard label="待验收" :value="statusCounts.reviewing" unit="单" icon="验" note="等待管理员确认" trend="平均 2.4 小时" />
      <StatCard label="已完成" :value="statusCounts.done" unit="单" icon="毕" note="已完成并归档的工单" trend="完成率 25%" />
    </div>

    <section class="card">
      <div class="card__head">
        <div class="card__title">工单列表 <span class="card__sub">共 {{ filteredOrders.length }} 条符合条件的记录</span></div>
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
            <input v-model="keyword" class="input" type="text" placeholder="工单编号 / 任务 / 负责人" />
          </label>
          <label class="field" style="width: 120px">
            <span class="field__label">优先级</span>
            <select v-model="priorityFilter" class="select">
              <option value="全部">全部</option>
              <option value="高">高</option>
              <option value="中">中</option>
              <option value="低">低</option>
            </select>
          </label>
          <label class="field" style="width: 140px">
            <span class="field__label">负责人</span>
            <select v-model="assigneeFilter" class="select">
              <option value="全部">全部负责人</option>
              <option v-for="name in assigneeOptions" :key="name" :value="name">{{ name }}</option>
            </select>
          </label>
          <label class="field" style="width: 150px">
            <span class="field__label">地块</span>
            <select v-model="plotFilter" class="select">
              <option value="全部">全部地块</option>
              <option v-for="plot in plotOptions" :key="plot" :value="plot">{{ plot }}</option>
            </select>
          </label>
          <div class="toolbar__spacer" />
          <span class="tag tag--outline">已筛选 {{ filteredOrders.length }} 单</span>
        </div>

        <div class="table-wrap">
          <table class="data-table">
            <thead>
              <tr>
                <th>工单编号</th>
                <th>任务</th>
                <th>地块</th>
                <th>负责人</th>
                <th>截止时间</th>
                <th>优先级</th>
                <th>状态</th>
                <th>进度</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="pagedOrders.length === 0">
                <td colspan="9">
                  <div class="empty">
                    <span class="empty__mark">空</span>
                    当前筛选条件下没有工单
                  </div>
                </td>
              </tr>
              <tr v-for="order in pagedOrders" :key="order.id">
                <td><RouterLink class="cell-strong" :to="`/farm/work-orders/${order.id}`">{{ order.id }}</RouterLink></td>
                <td>
                  <div class="cell-strong">{{ order.title }}</div>
                  <div class="cell-sub">{{ order.type }} · {{ order.crop }}</div>
                </td>
                <td>{{ findPlot(order.plot)?.name ?? order.plot }}</td>
                <td>{{ order.assignee }}</td>
                <td class="num">{{ order.deadline }}</td>
                <td><StatusTag :text="order.priority" :tone="priorityTone(order.priority)" /></td>
                <td><StatusTag :text="order.status" :tone="statusTone(order.status)" dot /></td>
                <td>
                  <div class="row" style="gap: 7px">
                    <div class="progress" style="width: 74px">
                      <div class="progress__bar" :class="{ 'progress__bar--warn': order.progress < 40 }" :style="{ width: `${order.progress}%` }" />
                    </div>
                    <span class="num">{{ order.progress }}%</span>
                  </div>
                </td>
                <td>
                  <div class="table-actions">
                    <RouterLink class="btn btn--sm" :to="`/farm/work-orders/${order.id}`">详情</RouterLink>
                    <button v-if="order.status === '待接单'" class="btn btn--sm btn--primary" type="button" @click="acceptOrder(order)">接单</button>
                    <template v-if="order.status === '进行中'">
                      <button class="btn btn--sm" type="button" @click="urgeOrder(order)">催办</button>
                      <button class="btn btn--sm btn--primary" type="button" @click="submitOrderForReview(order)">提交验收</button>
                    </template>
                    <button v-if="order.status === '待验收'" class="btn btn--sm btn--primary" type="button" @click="approveOrder(order)">验收通过</button>
                    <span v-if="order.status === '已完成'" class="tag tag--ok">已归档</span>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <Pager :total="filteredOrders.length" :page="page" :page-size="pageSize" @update:page="page = $event" />
      </div>
    </section>

    <AppModal v-model="modalOpen" title="新建农事工单" size="lg">
      <div class="form-grid">
        <label class="field span-2">
          <span class="field__label">任务标题</span>
          <input v-model="form.title" class="input" type="text" placeholder="如：4号棚番茄整枝打杈" />
        </label>
        <label class="field">
          <span class="field__label">作业地块</span>
          <select v-model="form.plot" class="select">
            <option v-for="item in plotsForForm" :key="item.id" :value="item.id">{{ item.name }}（{{ item.crop }}）</option>
          </select>
        </label>
        <label class="field">
          <span class="field__label">作业类型</span>
          <select v-model="form.type" class="select">
            <option v-for="type in orderTypes" :key="type" :value="type">{{ type }}</option>
          </select>
        </label>
        <label class="field">
          <span class="field__label">负责人</span>
          <select v-model="form.assignee" class="select">
            <option v-for="farmer in farmers" :key="farmer.name" :value="farmer.name">{{ farmer.name }}（{{ farmer.phone }}）</option>
          </select>
        </label>
        <label class="field">
          <span class="field__label">截止时间</span>
          <input v-model="form.deadline" class="input" type="text" placeholder="2026-11-07 18:00" />
        </label>
        <label class="field">
          <span class="field__label">优先级</span>
          <select v-model="form.priority" class="select">
            <option value="高">高</option>
            <option value="中">中</option>
            <option value="低">低</option>
          </select>
        </label>
        <label class="field">
          <span class="field__label">作物</span>
          <input class="input" type="text" :value="findPlot(form.plot)?.crop ?? '未指定'" disabled />
        </label>
        <label class="field span-2">
          <span class="field__label">作业要求</span>
          <textarea v-model="form.requirement" class="textarea" placeholder="填写作业标准、验收依据与注意事项"></textarea>
        </label>
      </div>
      <div class="notice" style="margin-top: 14px">工单创建后将立即派发给负责人，可在移动端接单并打卡上报。</div>
      <template #footer>
        <button class="btn" type="button" @click="modalOpen = false">取消</button>
        <button class="btn btn--primary" type="button" @click="submitOrder">创建并派发</button>
      </template>
    </AppModal>
  </div>
</template>

<style scoped>
.stat-grid {
  grid-template-columns: repeat(5, minmax(0, 1fr));
}

.cell-sub {
  margin-top: 1px;
  font-size: 10.5px;
  color: var(--faint);
}

@media (max-width: 1280px) {
  .stat-grid {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}

@media (max-width: 720px) {
  .stat-grid {
    grid-template-columns: 1fr;
  }
}
</style>
