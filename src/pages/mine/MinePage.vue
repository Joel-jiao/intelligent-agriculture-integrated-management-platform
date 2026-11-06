<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import AppModal from '@/components/ui/AppModal.vue'
import { useAuth } from '@/composables/useAuth'
import { useToast } from '@/composables/useToast'
import { park, plots, sysInfo, users } from '@/data/mock'

const auth = useAuth()
const session = auth.session('app')
const profile = computed(() => session.value)
const accountUser = computed(() => users.find((item) => item.account === profile.value.account))
const router = useRouter()
const toast = useToast()

const completedCount = 46
const totalHours = 128.5
const plotCount = computed(() => plots.filter((item) => item.manager === profile.value.name).length)

interface NavRow {
  label: string
  desc: string
  to: string
  icon: string
}

const navRows: NavRow[] = [
  { label: '我的任务', desc: '查看待接单与进行中任务', to: '/app/tasks', icon: '务' },
  { label: '消息中心', desc: '告警与工单通知', to: '/app/messages', icon: '信' },
  { label: '环境查看', desc: '地块环境与设备在线状态', to: '/app/env', icon: '环' },
  { label: '设备控制', desc: '远程启停水泵与风机', to: '/app/devices', icon: '控' },
  { label: '扫码录入', desc: '采收批次溯源录入', to: '/app/trace-scan', icon: '码' },
]

const accountOpen = ref(false)
const aboutOpen = ref(false)
const logoutOpen = ref(false)

function confirmLogout() {
  logoutOpen.value = false
  auth.logout('app')
  toast.success('已退出农户移动端')
  router.push('/app/login')
}
</script>

<template>
  <div class="mobile-page">
    <header class="page-head">
      <div>
        <h2>个人中心</h2>
        <p>账号与常用功能</p>
      </div>
      <span class="tag tag--brand">{{ profile.role }}</span>
    </header>

    <section class="mobile-card profile-card">
      <span class="avatar avatar--xl">{{ profile.name.slice(0, 1) }}</span>
      <div class="profile-main">
        <div class="profile-name">{{ profile.name }}</div>
        <div class="profile-role">{{ profile.role }} · 负责 {{ plotCount }} 个地块</div>
        <div class="profile-account font-num">账号 {{ profile.account }}</div>
      </div>
    </section>

    <div class="mine-stats">
      <div class="mobile-stat">
        <div class="mobile-stat__label">完成任务</div>
        <div class="mobile-stat__value font-num">{{ completedCount }}<small>项</small></div>
      </div>
      <div class="mobile-stat">
        <div class="mobile-stat__label">累计工时</div>
        <div class="mobile-stat__value font-num">{{ totalHours }}<small>h</small></div>
      </div>
      <div class="mobile-stat">
        <div class="mobile-stat__label">负责地块</div>
        <div class="mobile-stat__value font-num">{{ plotCount }}<small>个</small></div>
      </div>
    </div>

    <section class="mobile-section">
      <div class="mobile-section__head">
        <h3>功能菜单</h3>
        <span>{{ navRows.length + 2 }} 项</span>
      </div>
      <div class="mobile-card menu-card">
        <RouterLink v-for="row in navRows" :key="row.to" :to="row.to" class="mobile-list-item menu-row">
          <span class="mobile-icon">{{ row.icon }}</span>
          <span class="menu-main">
            <span class="menu-label">{{ row.label }}</span>
            <span class="menu-desc">{{ row.desc }}</span>
          </span>
          <span class="menu-arrow">›</span>
        </RouterLink>

        <button class="mobile-list-item menu-row menu-row--button" type="button" @click="accountOpen = true">
          <span class="mobile-icon">我</span>
          <span class="menu-main">
            <span class="menu-label">账号资料</span>
            <span class="menu-desc">姓名、角色与联系方式</span>
          </span>
          <span class="menu-arrow">›</span>
        </button>
        <button class="mobile-list-item menu-row menu-row--button" type="button" @click="aboutOpen = true">
          <span class="mobile-icon">介</span>
          <span class="menu-main">
            <span class="menu-label">关于平台</span>
            <span class="menu-desc">版本信息与运行环境</span>
          </span>
          <span class="menu-arrow">›</span>
        </button>
      </div>
    </section>

    <section class="mobile-section">
      <button class="mobile-btn mobile-btn--danger mobile-btn--full" type="button" @click="logoutOpen = true">
        退出登录
      </button>
      <div class="version-info">
        <span class="font-num">{{ sysInfo.version }}</span>
        <span>{{ park.name }} · 农户移动端</span>
      </div>
    </section>

    <div class="page-spacer" />

    <AppModal v-model="accountOpen" title="账号资料">
      <div class="detail-row"><span>姓名</span><b>{{ profile.name }}</b></div>
      <div class="detail-row"><span>角色</span><b>{{ profile.role }}</b></div>
      <div class="detail-row"><span>登录账号</span><b class="font-num">{{ profile.account }}</b></div>
      <div class="detail-row"><span>联系电话</span><b class="font-num">{{ accountUser?.phone ?? '139****8832' }}</b></div>
      <div class="detail-row"><span>负责地块</span><b>{{ accountUser?.plotScope ?? 'P-01' }}</b></div>
      <div class="detail-row"><span>最近登录</span><b class="font-num">{{ accountUser?.lastLogin ?? '2026-11-06 08:12' }}</b></div>
      <template #footer>
        <button class="mobile-btn mobile-btn--ghost" type="button" @click="accountOpen = false">关闭</button>
      </template>
    </AppModal>

    <AppModal v-model="aboutOpen" title="关于平台">
      <div class="about-title">{{ park.name }}</div>
      <p class="about-desc">面向农户的移动端作业入口，覆盖任务执行、环境查看、设备控制与溯源录入。</p>
      <div class="detail-row"><span>版本号</span><b class="font-num">{{ sysInfo.version }}</b></div>
      <div class="detail-row"><span>运行环境</span><b>{{ sysInfo.env }}</b></div>
      <div class="detail-row"><span>数据库</span><b class="font-num">{{ sysInfo.db }}</b></div>
      <div class="detail-row"><span>接口框架</span><b class="font-num">{{ sysInfo.api }}</b></div>
      <div class="detail-row"><span>已运行</span><b>{{ sysInfo.uptime }}</b></div>
      <template #footer>
        <button class="mobile-btn mobile-btn--ghost" type="button" @click="aboutOpen = false">关闭</button>
      </template>
    </AppModal>

    <AppModal v-model="logoutOpen" title="退出登录">
      <p class="logout-text">退出后将返回农户移动端登录页，未提交的作业记录不会被保存。</p>
      <template #footer>
        <button class="mobile-btn mobile-btn--ghost" type="button" @click="logoutOpen = false">取消</button>
        <button class="mobile-btn mobile-btn--danger" type="button" @click="confirmLogout">确认退出</button>
      </template>
    </AppModal>
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

.profile-card {
  display: flex;
  align-items: center;
  gap: 14px;
  background: linear-gradient(160deg, var(--brand-softer), #fff 70%);
}

.profile-main {
  min-width: 0;
}

.profile-name {
  font-size: 17px;
  font-weight: 700;
  color: var(--ink);
}

.profile-role {
  margin-top: 2px;
  font-size: 11.5px;
  color: var(--muted);
}

.profile-account {
  margin-top: 3px;
  font-size: 10.5px;
  color: var(--faint);
}

.mine-stats {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 8px;
  margin-top: 12px;
}

.mine-stats .mobile-stat {
  padding: 12px 10px;
}

.mine-stats .mobile-stat__value {
  font-size: 19px;
}

.menu-card {
  padding: 2px 14px;
}

.menu-row {
  width: 100%;
  padding: 12px 0;
}

.menu-row--button {
  border: 0;
  border-bottom: 1px solid var(--line);
  background: none;
  text-align: left;
}

.menu-row--button:last-child {
  border-bottom: 0;
}

.menu-main {
  display: flex;
  flex: 1;
  flex-direction: column;
  min-width: 0;
}

.menu-label {
  font-size: 12.5px;
  font-weight: 550;
  color: var(--ink);
}

.menu-desc {
  margin-top: 1px;
  font-size: 10px;
  color: var(--faint);
}

.menu-arrow {
  color: var(--faint);
  font-size: 16px;
  line-height: 1;
}

.version-info {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 2px;
  margin-top: 14px;
  font-size: 10.5px;
  color: var(--faint);
}

.version-info span:first-child {
  color: var(--muted);
}

.detail-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 8px 0;
  border-bottom: 1px dashed var(--line);
  font-size: 12px;
  color: var(--muted);
}

.detail-row b {
  font-weight: 600;
  color: var(--ink-2);
}

.about-title {
  font-size: 16px;
  font-weight: 700;
  color: var(--ink);
}

.about-desc {
  margin: 4px 0 8px;
  font-size: 11.5px;
  line-height: 1.7;
  color: var(--muted);
}

.logout-text {
  font-size: 12.5px;
  line-height: 1.7;
  color: var(--ink-2);
}

.page-spacer {
  height: 24px;
}
</style>
