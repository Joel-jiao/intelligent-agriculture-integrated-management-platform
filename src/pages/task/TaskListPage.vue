<script setup lang="ts">
import { computed, ref } from 'vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import { useToast } from '@/composables/useToast'
import { plotName, workOrders as seedOrders } from '@/data/mock'
import type { WorkOrder, WorkStatus } from '@/data/types'
import { today } from '@/utils/format'

type TabKey = 'all' | WorkStatus

const toast = useToast()
const orders = ref<WorkOrder[]>(seedOrders.map((item) => ({ ...item })))
const activeTab = ref<TabKey>('all')

const tabs: Array<{ key: TabKey; label: string }> = [
  { key: 'all', label: '全部' },
  { key: '待接单', label: '待接单' },
  { key: '进行中', label: '进行中' },
  { key: '待验收', label: '待验收' },
  { key: '已完成', label: '已完成' },
]

function countFor(key: TabKey): number {
  if (key === 'all') return orders.value.length
  return orders.value.filter((item) => item.status === key).length
}

const filteredOrders = computed(() =>
  activeTab.value === 'all'
    ? orders.value
    : orders.value.filter((item) => item.status === activeTab.value),
)

function statusTone(status: WorkOrder['status']): 'ok' | 'warn' | 'brand' | 'info' {
  if (status === '待接单') return 'warn'
  if (status === '进行中') return 'brand'
  if (status === '待验收') return 'info'
  return 'ok'
}

function priorityClass(priority: WorkOrder['priority']): string {
  if (priority === '高') return 'tag--danger'
  if (priority === '中') return 'tag--warn'
  return 'tag--info'
}

function refresh() {
  toast.success('任务列表已刷新，数据更新至最新时刻')
}
</script>

<template>
  <div class="mobile-page">
    <header class="page-head">
      <div>
        <h2>农事任务</h2>
        <p>{{ today() }} · 共 {{ orders.length }} 项任务</p>
      </div>
      <button class="mobile-btn mobile-btn--ghost refresh-btn" type="button" @click="refresh">刷新</button>
    </header>

    <div class="mobile-tabs">
      <button
        v-for="tab in tabs"
        :key="tab.key"
        class="mobile-tab"
        :class="{ 'is-active': activeTab === tab.key }"
        type="button"
        @click="activeTab = tab.key"
      >
        {{ tab.label }}
        <span class="tab-count font-num">{{ countFor(tab.key) }}</span>
      </button>
    </div>

    <div class="task-list">
      <RouterLink
        v-for="order in filteredOrders"
        :key="order.id"
        class="mobile-task"
        :to="`/app/tasks/${order.id}`"
      >
        <div class="mobile-task__top">
          <span class="mobile-task__title">{{ order.title }}</span>
          <StatusTag :text="order.status" :tone="statusTone(order.status)" dot />
        </div>
        <div class="mobile-task__meta">
          <span>{{ plotName(order.plot) }}</span>
          <span>截止 {{ order.deadline }}</span>
        </div>
        <div class="task-foot">
          <span class="tag" :class="priorityClass(order.priority)">优先级 {{ order.priority }}</span>
          <span class="tag tag--outline">{{ order.type }}</span>
          <span class="task-owner">{{ order.assignee }}</span>
        </div>
        <div class="progress-row">
          <span class="progress-label">作业进度</span>
          <div class="progress">
            <div class="progress__bar" :style="{ width: `${order.progress}%` }" />
          </div>
          <b class="font-num">{{ order.progress }}%</b>
        </div>
      </RouterLink>

      <div v-if="filteredOrders.length === 0" class="mobile-card empty-card">
        <span class="empty-mark">空</span>
        <p>当前筛选条件下暂无任务</p>
        <button class="mobile-btn mobile-btn--ghost" type="button" @click="activeTab = 'all'">查看全部任务</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.page-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  margin: 6px 0 14px;
  padding: 0 2px;
}

.page-head h2 {
  font-size: 20px;
  font-weight: 700;
  color: var(--ink);
}

.page-head p {
  margin-top: 3px;
  font-size: 11.5px;
  color: var(--muted);
}

.refresh-btn {
  height: 44px;
  padding: 0 14px;
  font-size: 12.5px;
}

.mobile-tabs {
  margin-bottom: 14px;
}

.tab-count {
  margin-left: 4px;
  font-size: 10px;
  opacity: 0.8;
}

.task-list {
  display: block;
}

.task-foot {
  display: flex;
  align-items: center;
  gap: 7px;
  margin-top: 9px;
}

.task-owner {
  margin-left: auto;
  font-size: 11px;
  color: var(--muted);
}

.progress-row {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 10px;
  font-size: 11px;
  color: var(--muted);
}

.progress-label {
  flex: 0 0 auto;
}

.progress-row .progress {
  flex: 1;
}

.progress-row b {
  width: 36px;
  text-align: right;
  color: var(--ink-2);
}

.font-num {
  font-family: var(--font-num);
}

.empty-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 9px;
  padding: 30px 16px;
}

.empty-card p {
  font-size: 12px;
  color: var(--muted);
}

.empty-mark {
  display: grid;
  place-items: center;
  width: 46px;
  height: 46px;
  border-radius: 50%;
  background: var(--surface-2);
  color: var(--faint);
  font-size: 14px;
}
</style>
