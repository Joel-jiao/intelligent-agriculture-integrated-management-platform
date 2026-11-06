<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuth } from '@/composables/useAuth'
import { park } from '@/data/mock'

const router = useRouter()
const { login } = useAuth()
const account = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')

function submit() {
  error.value = ''
  if (!account.value.trim()) {
    error.value = '请输入手机号或账号'
    return
  }
  if (password.value.length < 6) {
    error.value = '密码长度不能少于 6 位'
    return
  }
  loading.value = true
  window.setTimeout(() => {
    login('app', account.value.trim())
    loading.value = false
    router.push('/app/home')
  }, 600)
}

function demoLogin() {
  account.value = 'wangq'
  password.value = '123456'
  submit()
}
</script>

<template>
  <div class="mobile-login">
    <div class="mobile-login__card">
      <div class="mobile-login__mark">农</div>
      <h1>{{ park.shortName }}</h1>
      <p>农户移动端 · 农事任务与现场作业</p>

      <div v-if="error" class="login-error">{{ error }}</div>
      <label class="mobile-field">
        <span>手机号 / 账号</span>
        <input v-model="account" type="text" placeholder="请输入手机号或账号" />
      </label>
      <label class="mobile-field">
        <span>登录密码</span>
        <input v-model="password" type="password" placeholder="请输入密码" @keyup.enter="submit" />
      </label>
      <button class="mobile-btn mobile-btn--full" type="button" :disabled="loading" @click="submit">
        {{ loading ? '登录中…' : '登录' }}
      </button>
      <button class="mobile-btn mobile-btn--ghost mobile-btn--full" type="button" style="margin-top: 10px" @click="demoLogin">
        使用演示账号登录
      </button>
      <div class="mobile-login__hint">演示账号 wangq / 密码 123456</div>
      <RouterLink to="/portals" class="mobile-login__link">返回业务端总览</RouterLink>
    </div>
  </div>
</template>

<style scoped>
.mobile-login {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  padding: 26px 20px;
  background:
    radial-gradient(500px 360px at 20% 0%, rgba(120, 210, 155, 0.28), transparent 62%),
    linear-gradient(160deg, #0e3d26, #071f14);
}

.mobile-login__card {
  width: 100%;
  max-width: 360px;
  padding: 30px 24px 24px;
  border-radius: 26px;
  background: #fff;
  box-shadow: 0 30px 70px rgba(0, 0, 0, 0.3);
}

.mobile-login__mark {
  display: grid;
  place-items: center;
  width: 52px;
  height: 52px;
  margin: 0 auto 12px;
  border-radius: 16px;
  background: linear-gradient(135deg, #bce9cb, #5bbd80);
  color: #10442a;
  font-size: 24px;
  font-weight: 800;
}

.mobile-login__card h1 {
  text-align: center;
  font-size: 21px;
  font-weight: 750;
  color: var(--ink);
}

.mobile-login__card > p {
  margin: 3px 0 22px;
  text-align: center;
  font-size: 11.5px;
  color: var(--muted);
}

.mobile-login__hint {
  margin-top: 12px;
  text-align: center;
  font-size: 11px;
  color: var(--faint);
}

.mobile-login__link {
  display: block;
  margin-top: 16px;
  text-align: center;
  font-size: 11.5px;
  color: var(--brand);
}
</style>
