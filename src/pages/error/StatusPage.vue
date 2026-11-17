<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useToast } from '@/composables/useToast'
import { park, sysInfo } from '@/api/store'

const route = useRoute()
const router = useRouter()
const toast = useToast()

const code = computed(() => {
  const raw = route.query.code
  const value = Array.isArray(raw) ? raw[0] : raw
  if (value === '401' || value === '403' || value === '500') return value
  return '404'
})

const traceId = computed(() => {
  const raw = route.query.traceId
  const value = Array.isArray(raw) ? raw[0] : raw
  return value ?? 'TRC-20261106-094215-8f3a'
})

const redirect = computed(() => {
  const raw = route.query.redirect
  const value = Array.isArray(raw) ? raw[0] : raw
  return value ?? ''
})

interface StatusMeta {
  mark: string
  title: string
  desc: string
}

const meta = computed<StatusMeta>(() => {
  switch (code.value) {
    case '401':
      return { mark: '锁', title: '登录已失效，请重新登录', desc: '当前登录状态已过期或未登录，请重新登录后继续访问。' }
    case '403':
      return { mark: '禁', title: '无访问权限', desc: '当前账号无权访问该资源，农户仅能查看归属本人地块的数据。' }
    case '500':
      return { mark: '障', title: '系统繁忙，请稍后重试', desc: '服务暂时不可用，请稍后重试；可复制错误追踪码便于运维定位问题。' }
    default:
      return { mark: '404', title: '页面不存在', desc: '您访问的页面已下线或地址输入有误。' }
  }
})

const menuEntries = [
  { label: '业务端总览', to: '/portals' },
  { label: '管理员登录', to: '/login' },
  { label: '运维端登录', to: '/ops/login' },
  { label: '监管端登录', to: '/sup/login' },
  { label: '农户移动端', to: '/app/login' },
  { label: '溯源查询示例', to: '/trace/h5/B20261105-03' },
]

function copyTrace() {
  navigator.clipboard?.writeText(traceId.value).then(
    () => toast.success('错误追踪码已复制'),
    () => toast.error('复制失败，请手动选择复制'),
  )
}

function retry() {
  router.go(0)
}
</script>

<template>
  <div class="status-page">
    <div class="status-card">
      <div class="status-card__brand">
        <span class="status-card__mark">{{ park.shortName.slice(0, 1) }}</span>
        <span>{{ park.name }}</span>
      </div>

      <div class="status-illustration" :class="`status-illustration--${code}`">
        <span>{{ meta.mark }}</span>
      </div>
      <h1>{{ meta.title }}</h1>
      <p class="status-desc">{{ meta.desc }}</p>

      <div v-if="code === '500'" class="trace-box">
        <span>错误追踪码</span>
        <code>{{ traceId }}</code>
        <button class="link-action" type="button" @click="copyTrace">复制</button>
      </div>

      <div v-if="code === '403'" class="notice notice--warn" style="text-align: left">
        <span>数据权限范围：农户账号仅可查看、操作归属本人地块的档案与设备。</span>
      </div>

      <div v-if="code === '404'" class="menu-entries">
        <div class="menu-entries__title">可用入口推荐</div>
        <RouterLink v-for="entry in menuEntries" :key="entry.to" :to="entry.to" class="menu-entry">
          <span>{{ entry.label }}</span>
          <span class="menu-entry__arrow">›</span>
        </RouterLink>
      </div>

      <div class="status-actions">
        <button v-if="code === '500'" class="btn btn--primary" type="button" @click="retry">重试</button>
        <button v-if="code === '401'" class="btn btn--primary" type="button" @click="router.push('/portals')">重新登录</button>
        <button v-if="code === '403'" class="btn btn--primary" type="button" @click="router.push('/portals')">返回工作台</button>
        <button v-if="code === '404'" class="btn btn--primary" type="button" @click="router.push('/portals')">返回首页</button>
        <button class="btn" type="button" @click="router.back()">返回上一页</button>
      </div>

      <div class="status-foot">
        <span>如问题持续存在，请联系运维：023-6888-0000</span>
        <span>{{ sysInfo.version }} · {{ sysInfo.env }}</span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.status-page {
  display: grid;
  place-items: center;
  min-height: 100vh;
  padding: 32px 16px;
  background:
    radial-gradient(800px 400px at 50% 0%, rgba(90, 200, 140, 0.16), transparent 60%),
    linear-gradient(150deg, #eef6f0, #f6f9f7);
}

.status-card {
  width: 100%;
  max-width: 460px;
  padding: 30px 28px 22px;
  border: 1px solid var(--line);
  border-radius: 18px;
  background: var(--bg-card-solid);
  box-shadow: 0 22px 60px rgba(24, 68, 44, 0.1);
  text-align: center;
}

.status-card__brand {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  font-size: 12px;
  color: var(--muted);
}

.status-card__mark {
  display: grid;
  place-items: center;
  width: 22px;
  height: 22px;
  border-radius: 6px;
  background: var(--brand);
  color: #fff;
  font-size: 12px;
  font-weight: 700;
}

.status-illustration {
  display: grid;
  place-items: center;
  width: 84px;
  height: 84px;
  margin: 22px auto 14px;
  border-radius: 50%;
  font-size: 28px;
  font-weight: 800;
}

.status-illustration--404 {
  background: var(--brand-soft);
  color: var(--brand);
}

.status-illustration--403 {
  background: var(--warning-soft);
  color: var(--warn);
}

.status-illustration--401 {
  background: #eaf2ff;
  color: #2f5fa8;
}

.status-illustration--500 {
  background: var(--danger-soft);
  color: var(--danger);
}

.status-card h1 {
  font-size: 20px;
  font-weight: 750;
  color: var(--ink);
}

.status-desc {
  margin-top: 8px;
  font-size: 12.5px;
  line-height: 1.7;
  color: var(--muted);
}

.trace-box {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 16px;
  padding: 10px 12px;
  border: 1px dashed var(--line-strong);
  border-radius: 9px;
  background: var(--brand-soft);
  font-size: 11px;
  color: var(--muted);
  text-align: left;
}

.trace-box code {
  flex: 1;
  font-family: var(--font-num);
  color: var(--ink-2);
}

.menu-entries {
  margin-top: 16px;
  text-align: left;
}

.menu-entries__title {
  margin-bottom: 6px;
  font-size: 11px;
  color: var(--faint);
}

.menu-entry {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 10px 12px;
  border: 1px solid var(--line);
  border-radius: 8px;
  font-size: 12.5px;
  color: var(--ink-2);
  transition: 0.16s;
}

.menu-entry:hover {
  border-color: var(--brand);
  color: var(--brand);
}

.menu-entry + .menu-entry {
  margin-top: 6px;
}

.menu-entry__arrow {
  color: var(--faint);
}

.status-actions {
  display: flex;
  justify-content: center;
  gap: 8px;
  margin-top: 20px;
}

.status-foot {
  display: flex;
  flex-direction: column;
  gap: 3px;
  margin-top: 20px;
  padding-top: 14px;
  border-top: 1px solid var(--line);
  font-size: 10.5px;
  color: var(--faint);
}
</style>
