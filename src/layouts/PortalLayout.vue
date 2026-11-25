<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import type { MenuGroup } from '@/config/menus'
import { useAuth, portalNames, type Portal } from '@/composables/useAuth'
import { useTheme } from '@/composables/useTheme'
import { alarms, devices, park, plots, serviceHealth, supWarnings, sysInfo } from '@/api/store'

const props = defineProps<{
  portal: Extract<Portal, 'admin' | 'ops' | 'sup'>
  menu: MenuGroup[]
}>()

const route = useRoute()
const router = useRouter()
const { session, logout } = useAuth()
const { theme, toggle } = useTheme()
// 路由守卫保证进入布局时已登录，当前用户来自后端登录态
const user = computed(() => session(props.portal).value)
const menuOpen = ref(false)

const marks: Record<string, string> = { admin: '农', ops: '运', sup: '监' }
const loginPaths: Record<string, string> = { admin: '/login', ops: '/ops/login', sup: '/sup/login' }
const alertPaths: Record<string, string> = { admin: '/alarms', ops: '/ops/logs/operation', sup: '/sup/warnings' }
const chips = computed<Record<string, string>>(() => {
  const gateways = devices.filter((item) => item.type === '网关')
  const gatewayOnline = gateways.filter((item) => item.status === '在线').length
  return {
    admin: `网关在线 ${gatewayOnline} / ${gateways.length}`,
    ops: `MQTT 吞吐 ${sysInfo.mqttMessages.toLocaleString()} 条`,
    sup: `辖区覆盖 ${plots.length} 个地块`,
  }
})
const alertCount = computed<Record<string, number>>(() => ({
  admin: alarms.filter((item) => item.status !== '已归档').length,
  ops: (serviceHealth as Array<{ status: string }>).filter((item) => item.status === '告警').length,
  sup: supWarnings.filter((item) => item.status !== '已办结').length,
}))

/* ---------- 菜单分组折叠 ---------- */
const COLLAPSE_KEY = 'agri_platform_sidebar_collapsed'

// 分组键带门户前缀，避免三个门户出现同名分组时状态互相污染
function groupKey(title: string) {
  return `${props.portal}:${title}`
}

function readCollapsed(): Set<string> {
  try {
    const raw = localStorage.getItem(COLLAPSE_KEY)
    const parsed: unknown = raw ? JSON.parse(raw) : []
    return new Set(Array.isArray(parsed) ? parsed.filter((item): item is string => typeof item === 'string') : [])
  } catch {
    return new Set()
  }
}

const collapsedGroups = ref<Set<string>>(readCollapsed())

function persistCollapsed() {
  try {
    localStorage.setItem(COLLAPSE_KEY, JSON.stringify([...collapsedGroups.value]))
  } catch {
    /* 隐私模式等场景忽略持久化失败 */
  }
}

function isCollapsed(title: string) {
  return collapsedGroups.value.has(groupKey(title))
}

function toggleGroup(title: string) {
  const key = groupKey(title)
  const next = new Set(collapsedGroups.value)
  if (next.has(key)) next.delete(key)
  else next.add(key)
  collapsedGroups.value = next
  persistCollapsed()
}

function isItemActive(to: string) {
  return route.path === to || route.path.startsWith(`${to}/`)
}

const activeGroupTitles = computed(() =>
  props.menu.filter((group) => group.items.some((item) => isItemActive(item.to))).map((group) => group.title),
)

function isActiveGroup(title: string) {
  return activeGroupTitles.value.includes(title)
}

// 切到某页时，自动展开它所在的分组，避免折叠状态导致"找不到当前页"
watch(
  activeGroupTitles,
  (titles) => {
    if (!titles.length) return
    const next = new Set(collapsedGroups.value)
    let changed = false
    for (const title of titles) {
      if (next.delete(groupKey(title))) changed = true
    }
    if (changed) {
      collapsedGroups.value = next
      persistCollapsed()
    }
  },
  { immediate: true },
)

const pageTitle = computed(() => String(route.meta.title ?? '工作台'))
const portalLabel = computed(() => portalNames[props.portal])
const flush = computed(() => route.meta.flush === true)

function doLogout() {
  logout(props.portal)
  router.push(loginPaths[props.portal] ?? '/login')
}
</script>

<template>
  <div class="app-shell" :class="`portal--${props.portal}`">
    <div v-if="menuOpen" class="sidebar-backdrop" @click="menuOpen = false" />
    <aside class="sidebar" :class="{ 'is-open': menuOpen }">
      <div class="sidebar__brand">
        <div class="sidebar__mark">{{ marks[portal] }}</div>
        <div class="sidebar__brand-text">
          <strong>{{ park.shortName }}</strong>
          <span>{{ portalLabel }}</span>
        </div>
      </div>

      <nav class="sidebar__nav">
        <div
          v-for="group in menu"
          :key="group.title"
          class="sidebar__group"
          :class="{ 'is-collapsed': isCollapsed(group.title), 'is-active': isActiveGroup(group.title) }"
        >
          <button
            class="sidebar__group-title"
            type="button"
            :aria-expanded="!isCollapsed(group.title)"
            :title="isCollapsed(group.title) ? `展开「${group.title}」` : `收起「${group.title}」`"
            @click="toggleGroup(group.title)"
          >
            <span>{{ group.title }}</span>
            <svg class="sidebar__group-arrow" viewBox="0 0 24 24" aria-hidden="true">
              <path d="M6 9l6 6 6-6" />
            </svg>
          </button>
          <div class="sidebar__items" :inert="isCollapsed(group.title)">
            <div class="sidebar__items-inner">
              <RouterLink
                v-for="item in group.items"
                :key="item.to"
                :to="item.to"
                class="sidebar__link"
                @click="menuOpen = false"
              >
                <span>{{ item.label }}</span>
              </RouterLink>
            </div>
          </div>
        </div>
      </nav>

      <div class="sidebar__footer">
        <b>{{ sysInfo.version }} · {{ sysInfo.env }}</b>
        服务运行 {{ sysInfo.uptime }}
        <div style="margin-top: 8px; display: flex; gap: 12px; flex-wrap: wrap">
          <RouterLink to="/portals">业务端总览</RouterLink>
          <RouterLink to="/screen">指挥大屏</RouterLink>
        </div>
      </div>
    </aside>

    <div class="workspace">
      <header class="topbar">
        <div class="topbar__left">
          <button class="icon-btn topbar__menu" type="button" aria-label="打开菜单" @click="menuOpen = true">
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path d="M4 7h16M4 12h16M4 17h16" />
            </svg>
          </button>
          <div class="topbar__title-group">
            <div class="breadcrumb">
              <span>智慧农业</span>
              <span aria-hidden="true">/</span>
              <b>{{ portalLabel }}</b>
            </div>
            <div class="topbar__page">{{ pageTitle }}</div>
          </div>
        </div>

        <div class="topbar__right">
          <span class="topbar__chip"><i class="dot dot--ok" />{{ chips[portal] }}</span>
          <RouterLink class="portal-switch" to="/portals">切换业务端</RouterLink>

          <button
            class="icon-btn"
            type="button"
            :aria-label="theme === 'dark' ? '切换浅色模式' : '切换深色模式'"
            :title="theme === 'dark' ? '浅色模式' : '深色模式'"
            @click="toggle"
          >
            <svg v-if="theme === 'dark'" viewBox="0 0 24 24" aria-hidden="true">
              <circle cx="12" cy="12" r="4" />
              <path d="M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M19.1 4.9l-1.4 1.4M6.3 17.7l-1.4 1.4" />
            </svg>
            <svg v-else viewBox="0 0 24 24" aria-hidden="true">
              <path d="M20 14.5A8.5 8.5 0 0 1 9.5 4a8.5 8.5 0 1 0 10.5 10.5Z" />
            </svg>
          </button>

          <button class="icon-btn" type="button" aria-label="告警消息" @click="router.push(alertPaths[portal] ?? '/')">
            <svg viewBox="0 0 24 24" aria-hidden="true">
              <path d="M18 8a6 6 0 0 0-12 0c0 5-2 6-2 6h16s-2-1-2-6" />
              <path d="M10.3 20a2 2 0 0 0 3.4 0" />
            </svg>
            <span v-if="(alertCount[portal] ?? 0) > 0" class="topbar__badge">{{ alertCount[portal] }}</span>
          </button>

          <div class="topbar__user">
            <div class="avatar">{{ (user?.name ?? '').slice(0, 1) }}</div>
            <div class="topbar__user-text">
              <b>{{ user?.name ?? '' }}</b>
              {{ user?.role ?? '' }}
            </div>
            <button class="topbar__logout" type="button" @click="doLogout">退出</button>
          </div>
        </div>
      </header>

      <main class="content" :class="{ 'content--flush': flush }">
        <RouterView />
      </main>
    </div>
  </div>
</template>

<style scoped>
.sidebar__group-title {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  width: 100%;
  margin: 0 0 2px;
  padding: 5px 10px;
  border: 0;
  border-radius: var(--radius-sm);
  font-family: inherit;
  font-size: 11px;
  font-weight: 600;
  letter-spacing: 0.6px;
  line-height: 1.5;
  color: var(--text-tertiary);
  text-align: left;
  background: transparent;
  cursor: pointer;
  transition: color 0.18s var(--ease), background 0.18s var(--ease);
}

.sidebar__group-title:hover {
  color: var(--text-secondary);
  background: var(--bg-subtle);
}

.sidebar__group-title:focus-visible {
  outline: 2px solid var(--primary);
  outline-offset: 1px;
}

.sidebar__group.is-active > .sidebar__group-title {
  color: var(--primary);
}

.sidebar__group-arrow {
  flex: 0 0 auto;
  width: 12px;
  height: 12px;
  fill: none;
  stroke: currentColor;
  stroke-width: 2.2;
  stroke-linecap: round;
  stroke-linejoin: round;
  opacity: 0.7;
  transition: transform 0.22s var(--ease), opacity 0.18s var(--ease);
}

.sidebar__group.is-collapsed .sidebar__group-arrow {
  transform: rotate(-90deg);
  opacity: 1;
}

/* 0fr → 1fr：纯 CSS 高度过渡，无需测量内容高度 */
.sidebar__items {
  display: grid;
  grid-template-rows: 1fr;
  transition: grid-template-rows 0.22s var(--ease);
}

.sidebar__group.is-collapsed .sidebar__items {
  grid-template-rows: 0fr;
}

.sidebar__items-inner {
  min-height: 0;
  overflow: hidden;
}

.sidebar-backdrop {
  position: fixed;
  inset: 0;
  z-index: 45;
  background: rgba(0, 0, 0, 0.24);
  backdrop-filter: blur(2px);
  animation: fade-in 0.2s ease;
}

.topbar__title-group {
  display: flex;
  flex-direction: column;
  gap: 1px;
  min-width: 0;
}

.topbar__menu {
  display: none;
}

@keyframes fade-in {
  from {
    opacity: 0;
  }
}

@media (max-width: 1024px) {
  .topbar__menu {
    display: grid;
  }
}
</style>
