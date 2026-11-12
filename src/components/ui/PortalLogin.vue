<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuth, portalNames, type Portal } from '@/composables/useAuth'
import { useTheme } from '@/composables/useTheme'

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
const { theme, toggle } = useTheme()

const account = ref('')
const password = ref('')
const captcha = ref('')
const captchaCode = ref(createCode())
const loading = ref(false)
const error = ref('')

function createCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
  return Array.from({ length: 4 }, () => chars[Math.floor(Math.random() * chars.length)]).join('')
}

function refreshCaptcha() {
  captchaCode.value = createCode()
  captcha.value = ''
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
  if (captcha.value.trim().toUpperCase() !== captchaCode.value) {
    error.value = '验证码不正确，请重新输入'
    refreshCaptcha()
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
    <button
      class="login-theme icon-btn"
      type="button"
      :aria-label="theme === 'dark' ? '切换浅色模式' : '切换深色模式'"
      @click="toggle"
    >
      <svg v-if="theme === 'dark'" viewBox="0 0 24 24">
        <circle cx="12" cy="12" r="4" />
        <path d="M12 2v2M12 20v2M2 12h2M20 12h2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M19.1 4.9l-1.4 1.4M6.3 17.7l-1.4 1.4" />
      </svg>
      <svg v-else viewBox="0 0 24 24">
        <path d="M20 14.5A8.5 8.5 0 0 1 9.5 4a8.5 8.5 0 1 0 10.5 10.5Z" />
      </svg>
    </button>

    <div class="login-card">
      <section class="login-form">
        <div class="login-form__head">
          <div class="login-form__mark">农</div>
          <h1>智慧农业管理平台</h1>
          <p>账号登录 · {{ portalNames[portal] }}</p>
        </div>

        <div v-if="error" class="login-error">{{ error }}</div>

        <form @submit.prevent="submit">
          <label class="field">
            <span class="field__label">账号</span>
            <input v-model="account" class="input" type="text" placeholder="请输入账号" autocomplete="username" />
          </label>
          <label class="field">
            <span class="field__label">密码</span>
            <input
              v-model="password"
              class="input"
              type="password"
              placeholder="请输入密码（不少于 6 位）"
              autocomplete="current-password"
            />
          </label>
          <label class="field">
            <span class="field__label">验证码</span>
            <div class="captcha-field">
              <input v-model="captcha" class="input" type="text" maxlength="4" placeholder="请输入验证码" />
              <button class="captcha-box" type="button" title="点击刷新验证码" @click="refreshCaptcha">
                {{ captchaCode }}
              </button>
            </div>
          </label>

          <button class="btn btn--primary btn--full" type="submit" :disabled="loading">
            {{ loading ? '正在登录…' : '登录' }}
          </button>
        </form>

        <div class="login-links">
          <a href="#" @click.prevent="error = '请联系园区管理员重置密码（内线 8021）'">忘记密码</a>
          <a href="#" @click.prevent="error = '技术支持：service@yunling-agri.cn · 400-820-1120'">联系我们</a>
        </div>

        <div class="login-demo">
          演示账号：<b>{{ portal === 'sup' ? 'sup01' : portal }}</b> / 密码：<b>123456</b><br />
          系统采用 RBAC 权限控制，不同角色仅可访问授权范围内的数据。
        </div>

        <div class="login-portals">
          <div class="login-portals__title">其他业务端</div>
          <div class="login-portals__list">
            <RouterLink v-for="item in otherPortals" :key="item.path" :to="item.path">{{ item.label }}</RouterLink>
          </div>
        </div>
      </section>
    </div>

    <div class="login-foot">智慧农业综合管理平台 · 重庆工程学院 计算机科学与技术 24计科2班 · 吴鸿宇</div>
  </div>
</template>

<style scoped>
.login-theme {
  position: absolute;
  top: 18px;
  right: 18px;
  z-index: 2;
}

@media (max-width: 720px) {
  .login-theme {
    top: 12px;
    right: 12px;
  }
}
</style>
