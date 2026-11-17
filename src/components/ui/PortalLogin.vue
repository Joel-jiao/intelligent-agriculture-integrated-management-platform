<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuth, portalNames, DEMO_PASSWORD, type Portal } from '@/composables/useAuth'
import { useTheme } from '@/composables/useTheme'
import { loadAllData } from '@/api/store'

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

const loading = ref(false)
const error = ref('')
const captchaCode = ref(createCode())

const formState = reactive({
  account: '',
  password: '',
  captcha: '',
})

const rules = {
  account: [{ required: true, whitespace: true, message: '请输入登录账号', trigger: 'blur' }],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码长度不能少于 6 位', trigger: 'blur' },
    {
      validator: (_rule: unknown, value: string) =>
        value === DEMO_PASSWORD
          ? Promise.resolve()
          : Promise.reject(new Error('密码错误，请重新输入')),
      trigger: 'blur',
    },
  ],
  captcha: [
    { required: true, whitespace: true, message: '请输入验证码', trigger: 'blur' },
    {
      validator: (_rule: unknown, value: string) =>
        value.trim().toUpperCase() === captchaCode.value
          ? Promise.resolve()
          : Promise.reject(new Error('验证码不正确，请重新输入')),
      trigger: 'blur',
    },
  ],
}

function createCode(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
  return Array.from({ length: 4 }, () => chars[Math.floor(Math.random() * chars.length)]).join('')
}

function refreshCaptcha() {
  captchaCode.value = createCode()
  formState.captcha = ''
}

const portalPath: Record<Portal, string> = {
  admin: '/login',
  ops: '/ops/login',
  sup: '/sup/login',
  app: '/app/login',
}

const otherPortals = computed(() => {
  const list: { label: string; path: string; desc: string }[] = [
    { label: '管理员端', path: '/login', desc: '园区业务管理' },
    { label: '运维端', path: '/ops/login', desc: '系统底层运维' },
    { label: '监管端', path: '/sup/login', desc: '辖区质量监管' },
    { label: '农户移动端', path: '/app/login', desc: '任务与打卡' },
  ]
  return list.filter((item) => item.path !== portalPath[props.portal])
})

/**
 * antd-vue Form 内部会拦截原生 submit、自动执行 rules 校验，
 * 只有校验通过才触发 @finish，失败则触发 @finish-failed。
 * 因此登录逻辑挂在 @finish 上即可，无需再手动 validateFields。
 */
async function onFinish() {
  error.value = ''
  loading.value = true
  const result = await login(props.portal, formState.account.trim(), formState.password)
  if (!result.ok) {
    error.value = result.error ?? '登录失败'
    loading.value = false
    return
  }
  await loadAllData()
  loading.value = false
  const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : props.redirect
  router.push(redirect)
}

function onFinishFailed(info: { errorFields?: { name: (string | number)[] }[] }) {
  // 保持旧行为：验证码输错时自动换一张
  if ((info.errorFields ?? []).some((item) => item.name.includes('captcha'))) refreshCaptcha()
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

        <a-alert
          v-if="error"
          class="login-error"
          type="info"
          show-icon
          closable
          :message="error"
          @close="error = ''"
        />

        <a-form
          :model="formState"
          :rules="rules"
          layout="vertical"
          class="login-antd-form"
          @finish="onFinish"
          @finish-failed="onFinishFailed"
        >
          <a-form-item name="account" label="账号">
            <a-input
              v-model:value="formState.account"
              placeholder="请输入账号"
              size="large"
              autocomplete="username"
            />
          </a-form-item>
          <a-form-item name="password" label="密码">
            <a-input
              v-model:value="formState.password"
              type="password"
              placeholder="请输入密码（不少于 6 位）"
              size="large"
              autocomplete="current-password"
            />
          </a-form-item>
          <a-form-item name="captcha" label="验证码">
            <div class="captcha-field">
              <a-input
                v-model:value="formState.captcha"
                :maxlength="4"
                placeholder="请输入验证码"
                size="large"
              />
              <button class="captcha-box" type="button" title="点击刷新验证码" @click="refreshCaptcha">
                {{ captchaCode }}
              </button>
            </div>
          </a-form-item>

          <a-button type="primary" html-type="submit" block size="large" :loading="loading">
            登录
          </a-button>
        </a-form>

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

.login-error {
  margin-bottom: 16px;
  border-radius: 10px;
}
</style>
