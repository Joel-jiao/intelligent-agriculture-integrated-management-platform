<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuth, portalNames, type Portal } from '@/composables/useAuth'
import { park } from '@/data/mock'

const props = defineProps<{
  portal: Extract<Portal, 'admin' | 'ops' | 'sup'>
  title: string
  subtitle: string
  redirect: string
  features: string[]
}>()

const router = useRouter()
const route = useRoute()
const { login } = useAuth()

const account = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')

const marks: Record<string, string> = {
  admin: '管',
  ops: '运',
  sup: '监',
}

const otherPortals = computed(() => {
  const list: { label: string; path: string; desc: string }[] = [
    { label: '管理员端', path: '/login', desc: '园区业务管理' },
    { label: '运维端', path: '/ops/login', desc: '系统底层运维' },
    { label: '监管端', path: '/sup/login', desc: '辖区质量监管' },
    { label: '农户移动端', path: '/app/login', desc: '任务与打卡' },
  ]
  return list.filter((item) => !(item.path === '/login' && props.portal === 'admin'))
})

async function submit() {
  error.value = ''
  if (!account.value.trim()) {
    error.value = '请输入登录账号'
    return
  }
  if (password.value.length < 6) {
    error.value = '密码长度不能少于 6 位'
    return
  }
  loading.value = true
  window.setTimeout(() => {
    login(props.portal, account.value.trim())
    loading.value = false
    const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : props.redirect
    router.push(redirect)
  }, 700)
}
</script>

<template>
  <div class="login-page" :class="`portal--${portal}`">
    <div class="login-card">
      <aside class="login-brand">
        <div>
          <div class="login-brand__mark">农</div>
          <h1>
            {{ park.name }}
            <span>INTELLIGENT AGRICULTURE PLATFORM</span>
          </h1>
          <p>集物联网感知、远程控制、生产农事、质量溯源与 GIS 分析于一体的农业综合管控平台。</p>
          <div class="login-brand__points">
            <div v-for="item in features" :key="item" class="login-brand__point">
              <i>✓</i>
              <span>{{ item }}</span>
            </div>
          </div>
        </div>
        <div class="login-brand__foot">© 2026 云岭智慧农业示范园 · {{ portalNames[portal] }}</div>
      </aside>

      <section class="login-form">
        <div class="login-form__head">
          <span class="tag tag--brand" style="margin-bottom: 10px">{{ marks[portal] }} · {{ portalNames[portal] }}</span>
          <h2>{{ title }}</h2>
          <p>{{ subtitle }}</p>
        </div>

        <div v-if="error" class="login-error">{{ error }}</div>

        <form @submit.prevent="submit">
          <label class="field">
            <span class="field__label">登录账号</span>
            <input v-model="account" class="input" type="text" placeholder="请输入账号" autocomplete="username" />
          </label>
          <label class="field">
            <span class="field__label">登录密码</span>
            <input v-model="password" class="input" type="password" placeholder="请输入密码（不少于 6 位）" autocomplete="current-password" />
          </label>
          <button class="btn btn--primary btn--full" type="submit" :disabled="loading">
            {{ loading ? '正在登录…' : '登录系统' }}
          </button>
        </form>

        <div class="login-demo">
          演示账号：<b>{{ portal === 'sup' ? 'sup01' : portal }}</b> / 密码：<b>123456</b><br />
          系统采用 RBAC 权限控制，不同角色仅可访问授权范围内的数据。
        </div>

        <div class="login-links">
          <span>其他业务端入口</span>
          <div style="display: flex; gap: 10px; flex-wrap: wrap">
            <RouterLink v-for="item in otherPortals" :key="item.path" :to="item.path">{{ item.label }}</RouterLink>
          </div>
        </div>
      </section>
    </div>
    <div class="login-foot">智慧农业综合管理平台 · 重庆工程学院 计算机科学与技术 24计科2班 · 吴鸿宇</div>
  </div>
</template>
