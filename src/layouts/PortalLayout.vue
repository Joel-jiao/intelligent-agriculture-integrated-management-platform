<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import type { MenuGroup } from '@/config/menus'
import { useAuth, portalNames, type Portal } from '@/composables/useAuth'
import { useTheme } from '@/composables/useTheme'
import { park, sysInfo } from '@/api/store'

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
const chips: Record<string, string> = {
  admin: '网关在线 19 / 20',
  ops: `MQTT 吞吐 ${sysInfo.mqttMessages.toLocaleString()} 条`,
  sup: '辖区覆盖 12 个园区',
}
const alertCount: Record<string, number> = { admin: 3, ops: 1, sup: 3 }

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
        <div v-for="group in menu" :key="group.title" class="sidebar__group">
          <div class="sidebar__group-title">{{ group.title }}</div>
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
            <span class="topbar__badge">{{ alertCount[portal] }}</span>
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
