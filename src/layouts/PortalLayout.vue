<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import type { MenuGroup } from '@/config/menus'
import { useAuth, portalNames, type Portal } from '@/composables/useAuth'
import { park, sysInfo } from '@/data/mock'

const props = defineProps<{
  portal: Extract<Portal, 'admin' | 'ops' | 'sup'>
  menu: MenuGroup[]
}>()

const route = useRoute()
const router = useRouter()
const { session, logout } = useAuth()
const user = session(props.portal)
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

function doLogout() {
  logout(props.portal)
  router.push(loginPaths[props.portal] ?? '/login')
}
</script>

<template>
  <div class="app-shell" :class="`portal--${portal}`">
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
            <span class="sidebar__link-icon">{{ item.icon }}</span>
            <span>{{ item.label }}</span>
          </RouterLink>
        </div>
      </nav>

      <div class="sidebar__footer">
        <b>{{ sysInfo.version }} · {{ sysInfo.env }}</b>
        服务运行 {{ sysInfo.uptime }}
        <div style="margin-top: 8px; display: flex; gap: 10px; flex-wrap: wrap">
          <RouterLink to="/portals" style="color: #b5ecc7">业务端总览</RouterLink>
          <RouterLink to="/screen" style="color: #b5ecc7">指挥大屏</RouterLink>
        </div>
      </div>
    </aside>

    <div class="workspace">
      <header class="topbar">
        <div class="topbar__left">
          <button class="topbar__icon" type="button" style="display: none" aria-label="打开菜单" @click="menuOpen = true">≡</button>
          <div>
            <div class="breadcrumb">
              <span>智慧农业</span>
              <span>/</span>
              <b>{{ portalLabel }}</b>
            </div>
            <div class="topbar__page">{{ pageTitle }}</div>
          </div>
        </div>
        <div class="topbar__right">
          <span class="topbar__chip"><i class="dot" />{{ chips[portal] }}</span>
          <RouterLink class="portal-switch" to="/portals">切换业务端</RouterLink>
          <button class="topbar__icon" type="button" aria-label="告警消息" @click="router.push(alertPaths[portal] ?? '/')">
            <span>铃</span>
            <span class="topbar__badge">{{ alertCount[portal] }}</span>
          </button>
          <div class="topbar__user">
            <div class="avatar">{{ user.name.slice(0, 1) }}</div>
            <div class="topbar__user-text">
              <b>{{ user.name }}</b>
              {{ user.role }} · {{ user.account }}
            </div>
            <button class="link-action" type="button" @click="doLogout">退出</button>
          </div>
        </div>
      </header>

      <main class="content">
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
  background: rgba(10, 25, 16, 0.36);
}

@media (max-width: 1024px) {
  .topbar__left .topbar__icon {
    display: grid !important;
  }
}
</style>
