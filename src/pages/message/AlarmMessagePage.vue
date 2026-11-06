<script setup lang="ts">
import { computed, ref } from 'vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import { useToast } from '@/composables/useToast'
import { messages as seedMessages } from '@/data/mock'
import type { MessageItem } from '@/data/types'
import { today } from '@/utils/format'

type TabKey = 'all' | 'unread' | 'alarm'

const toast = useToast()
const items = ref<MessageItem[]>(seedMessages.map((item) => ({ ...item })))
const activeTab = ref<TabKey>('all')
const expandedId = ref('')

const tabs: Array<{ key: TabKey; label: string }> = [
  { key: 'all', label: '全部' },
  { key: 'unread', label: '未读' },
  { key: 'alarm', label: '告警' },
]

const unreadCount = computed(() => items.value.filter((item) => !item.read).length)
const alarmCount = computed(() => items.value.filter((item) => item.level === '紧急' || item.level === '重要').length)

function tabCount(key: TabKey): number {
  if (key === 'unread') return unreadCount.value
  if (key === 'alarm') return alarmCount.value
  return items.value.length
}

const filteredMessages = computed(() => {
  if (activeTab.value === 'unread') return items.value.filter((item) => !item.read)
  if (activeTab.value === 'alarm') return items.value.filter((item) => item.level === '紧急' || item.level === '重要')
  return items.value
})

function levelTone(level: MessageItem['level']): 'danger' | 'warn' | 'info' {
  if (level === '紧急') return 'danger'
  if (level === '重要') return 'warn'
  return 'info'
}

function toggle(item: MessageItem) {
  expandedId.value = expandedId.value === item.id ? '' : item.id
  if (!item.read) {
    item.read = true
    toast.info('消息已标记为已读')
  }
}

function markAllRead() {
  const unread = items.value.filter((item) => !item.read)
  if (unread.length === 0) {
    toast.info('当前没有未读消息')
    return
  }
  unread.forEach((item) => {
    item.read = true
  })
  toast.success(`已将 ${unread.length} 条消息标记为已读`)
}
</script>

<template>
  <div class="mobile-page">
    <header class="page-head">
      <div>
        <h2>消息中心</h2>
        <p>{{ today() }} · 共 {{ items.length }} 条 · 未读 {{ unreadCount }} 条</p>
      </div>
      <span class="mobile-stat__value font-num unread-value">{{ unreadCount }}<small>未读</small></span>
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
        <span
          class="tab-count font-num"
          :class="{ 'tab-count--badge': tab.key === 'unread' && unreadCount > 0 }"
        >
          {{ tabCount(tab.key) }}
        </span>
      </button>
    </div>

    <button class="mobile-btn mobile-btn--ghost mobile-btn--full mark-btn" type="button" @click="markAllRead">
      全部标为已读
    </button>

    <div class="message-list">
      <div
        v-for="item in filteredMessages"
        :key="item.id"
        class="mobile-card message-card"
        :class="{ 'message-card--unread': !item.read }"
        @click="toggle(item)"
      >
        <div class="message-card__top">
          <div class="message-level">
            <StatusTag :text="item.level" :tone="levelTone(item.level)" dot />
            <span v-if="!item.read" class="unread-dot" />
          </div>
          <span class="message-time font-num">{{ item.time }}</span>
        </div>
        <div class="message-title">{{ item.title }}</div>
        <div v-if="expandedId === item.id" class="message-body">{{ item.body }}</div>
        <div class="message-foot">
          <span>来源：{{ item.from }}</span>
          <span class="message-toggle">{{ expandedId === item.id ? '收起详情' : '展开详情' }}</span>
        </div>
      </div>

      <div v-if="filteredMessages.length === 0" class="mobile-card empty-card">
        <span class="empty-mark">空</span>
        <p>{{ activeTab === 'unread' ? '暂无未读消息' : '暂无告警类消息' }}</p>
        <button class="mobile-btn mobile-btn--ghost" type="button" @click="activeTab = 'all'">查看全部消息</button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.font-num {
  font-family: var(--font-num);
}

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

.unread-value {
  margin-top: 0;
  font-size: 22px;
  color: var(--danger);
}

.mobile-tabs {
  margin-bottom: 10px;
}

.tab-count {
  margin-left: 4px;
  font-size: 10px;
  opacity: 0.8;
}

.tab-count--badge {
  display: inline-grid;
  place-items: center;
  min-width: 15px;
  height: 15px;
  margin-left: 4px;
  padding: 0 3px;
  border-radius: 8px;
  background: var(--danger);
  color: #fff;
  font-size: 9px;
  opacity: 1;
}

.mark-btn {
  margin-bottom: 12px;
}

.message-list {
  display: block;
}

.message-card {
  cursor: pointer;
}

.message-card--unread {
  border-left: 3px solid var(--danger);
}

.message-card__top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.message-level {
  display: flex;
  align-items: center;
  gap: 6px;
}

.unread-dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--danger);
  box-shadow: 0 0 0 3px var(--danger-soft);
}

.message-time {
  font-size: 10.5px;
  color: var(--faint);
}

.message-title {
  margin-top: 8px;
  font-size: 13px;
  font-weight: 650;
  line-height: 1.45;
  color: var(--ink);
}

.message-body {
  margin-top: 8px;
  padding: 10px;
  border-radius: 9px;
  background: var(--surface-2);
  font-size: 11.5px;
  line-height: 1.7;
  color: var(--ink-2);
}

.message-foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  margin-top: 9px;
  font-size: 10.5px;
  color: var(--muted);
}

.message-toggle {
  color: var(--brand);
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
