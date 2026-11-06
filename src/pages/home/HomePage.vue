<script setup lang="ts">
import { computed } from 'vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import { alarms, envSeries, park, plotName, plots, weather, workOrders } from '@/data/mock'
import type { WorkOrder } from '@/data/types'
import { today } from '@/utils/format'

const farmerName = '王强'
const farmerPlot = plots.find((item) => item.manager === farmerName)

const todoTasks = computed(() => workOrders.filter((item) => item.status !== '已完成').slice(0, 3))
const todayTaskCount = computed(() => workOrders.filter((item) => item.status !== '已完成').length)
const pendingCheckin = computed(
  () => workOrders.filter((item) => item.status === '进行中' && item.assignee === farmerName).length,
)
const unreadAlarms = computed(() => alarms.filter((item) => item.status !== '已归档').length)
const latestAlarm = computed(() => alarms[0])

function lastValue(list: number[], fallback: number): number {
  return list[list.length - 1] ?? fallback
}

const envSummary = computed(() => [
  { label: '空气温度', value: lastValue(envSeries.temperature, 26), unit: '℃' },
  { label: '空气湿度', value: lastValue(envSeries.humidity, 68), unit: '%' },
  { label: '土壤湿度', value: lastValue(envSeries.soilMoisture, 50), unit: '%' },
])

interface QuickLink {
  label: string
  to: string
  icon: string
}

const quickLinks: QuickLink[] = [
  { label: '任务列表', to: '/app/tasks', icon: '务' },
  { label: '环境查看', to: '/app/env', icon: '环' },
  { label: '设备控制', to: '/app/devices', icon: '控' },
  { label: '扫码录入', to: '/app/trace-scan', icon: '码' },
  { label: '消息中心', to: '/app/messages', icon: '信' },
  { label: '个人中心', to: '/app/mine', icon: '我' },
]

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

function levelTone(level: string): 'danger' | 'warn' | 'info' {
  if (level === '紧急') return 'danger'
  if (level === '重要') return 'warn'
  return 'info'
}
</script>

<template>
  <div class="mobile-page">
    <section class="mobile-hero">
      <div class="mobile-hero__row">
        <div>
          <h2>早上好，王强</h2>
          <p>{{ today() }} · {{ park.name }}</p>
          <p>{{ farmerPlot?.name ?? '园区地块' }} · {{ farmerPlot?.crop ?? '番茄' }}种植管理</p>
        </div>
        <div class="mobile-hero__weather">
          <b class="font-num">{{ weather.temperature }}℃</b>
          <span>{{ weather.condition }}</span>
          <span>{{ weather.wind }}</span>
        </div>
      </div>
    </section>

    <div class="mobile-stat-grid">
      <div class="mobile-stat">
        <div class="mobile-stat__label">今日任务<span class="stat-mark">待处理</span></div>
        <div class="mobile-stat__value font-num">{{ todayTaskCount }}<small>项</small></div>
      </div>
      <div class="mobile-stat">
        <div class="mobile-stat__label">待打卡<span class="stat-mark">现场</span></div>
        <div class="mobile-stat__value font-num">{{ pendingCheckin }}<small>次</small></div>
      </div>
      <div class="mobile-stat">
        <div class="mobile-stat__label">未读告警<span class="stat-mark stat-mark--danger">优先</span></div>
        <div class="mobile-stat__value font-num">{{ unreadAlarms }}<small>条</small></div>
      </div>
    </div>

    <section class="mobile-section">
      <div class="mobile-section__head">
        <h3>快捷入口</h3>
        <span>常用功能</span>
      </div>
      <nav class="quick-grid">
        <RouterLink v-for="link in quickLinks" :key="link.to" :to="link.to" class="quick-item">
          <span class="mobile-icon">{{ link.icon }}</span>
          <span class="quick-label">{{ link.label }}</span>
        </RouterLink>
      </nav>
    </section>

    <section class="mobile-section">
      <div class="mobile-section__head">
        <h3>今日待办</h3>
        <RouterLink to="/app/tasks">全部任务</RouterLink>
      </div>
      <RouterLink
        v-for="task in todoTasks"
        :key="task.id"
        class="mobile-task"
        :to="`/app/tasks/${task.id}`"
      >
        <div class="mobile-task__top">
          <span class="mobile-task__title">{{ task.title }}</span>
          <StatusTag :text="task.status" :tone="statusTone(task.status)" />
        </div>
        <div class="mobile-task__meta">
          <span>{{ plotName(task.plot) }}</span>
          <span>截止 {{ task.deadline }}</span>
        </div>
        <div class="task-foot">
          <span class="tag" :class="priorityClass(task.priority)">优先级 {{ task.priority }}</span>
          <div class="progress">
            <div class="progress__bar" :style="{ width: `${task.progress}%` }" />
          </div>
          <span class="task-progress font-num">{{ task.progress }}%</span>
        </div>
      </RouterLink>
    </section>

    <section class="mobile-section">
      <div class="mobile-section__head">
        <h3>最新告警</h3>
        <RouterLink to="/app/messages">消息中心</RouterLink>
      </div>
      <div v-if="latestAlarm" class="mobile-card alarm-card">
        <div class="alarm-card__top">
          <StatusTag :text="latestAlarm.level" :tone="levelTone(latestAlarm.level)" dot />
          <span class="alarm-time font-num">{{ latestAlarm.createdAt }}</span>
        </div>
        <div class="alarm-card__title">{{ latestAlarm.title }}</div>
        <div class="alarm-card__meta">
          {{ plotName(latestAlarm.plot) }} · {{ latestAlarm.source }} · {{ latestAlarm.status }}
        </div>
        <RouterLink class="mobile-btn mobile-btn--ghost mobile-btn--full" to="/app/messages">
          查看告警详情
        </RouterLink>
      </div>
      <div v-else class="mobile-card alarm-card">
        <div class="alarm-card__title">当前暂无未处理告警</div>
        <div class="alarm-card__meta">园区设备与环境运行正常</div>
      </div>
    </section>

    <section class="mobile-section">
      <div class="mobile-section__head">
        <h3>环境摘要</h3>
        <RouterLink to="/app/env">查看详情</RouterLink>
      </div>
      <div class="mobile-card env-summary">
        <div v-for="item in envSummary" :key="item.label" class="env-item">
          <span>{{ item.label }}</span>
          <b class="font-num">{{ item.value }}<small>{{ item.unit }}</small></b>
        </div>
      </div>
      <p class="env-note">数据来源：{{ farmerPlot?.name ?? '1号智能大棚' }}环境传感器 · 每小时更新</p>
    </section>

    <div class="page-spacer" />
  </div>
</template>

<style scoped>
.font-num {
  font-family: var(--font-num);
}

.mobile-stat-grid {
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 8px;
}

.mobile-stat {
  padding: 12px 10px;
}

.mobile-stat__value {
  font-size: 19px;
}

.stat-mark {
  font-size: 10px;
  color: var(--brand);
}

.stat-mark--danger {
  color: var(--danger);
}

.quick-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 10px;
}

.quick-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 7px;
  padding: 13px 6px;
  border: 1px solid var(--line);
  border-radius: 14px;
  background: #fff;
  box-shadow: 0 3px 10px rgba(24, 68, 44, 0.04);
}

.quick-item:active {
  border-color: var(--brand);
}

.quick-label {
  font-size: 11.5px;
  color: var(--ink-2);
}

.task-foot {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 10px;
}

.task-foot .progress {
  flex: 1;
}

.task-progress {
  width: 34px;
  text-align: right;
  font-size: 10.5px;
  color: var(--muted);
}

.alarm-card__top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.alarm-time {
  font-size: 10.5px;
  color: var(--faint);
}

.alarm-card__title {
  margin-top: 8px;
  font-size: 13.5px;
  font-weight: 650;
  color: var(--ink);
}

.alarm-card__meta {
  margin-top: 4px;
  font-size: 11px;
  color: var(--muted);
}

.alarm-card .mobile-btn {
  margin-top: 12px;
}

.env-summary {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 10px;
}

.env-item {
  text-align: center;
}

.env-item span {
  display: block;
  font-size: 11px;
  color: var(--muted);
}

.env-item b {
  display: block;
  margin-top: 3px;
  font-size: 19px;
  color: var(--brand-dark);
}

.env-item small {
  margin-left: 2px;
  font-size: 10.5px;
  color: var(--muted);
}

.env-note {
  margin-top: 7px;
  font-size: 10.5px;
  color: var(--faint);
}

.page-spacer {
  height: 24px;
}
</style>
