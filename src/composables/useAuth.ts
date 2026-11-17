import { reactive, computed, ref } from 'vue'
import { apiPost, ApiError } from '@/api/http'

export type Portal = 'admin' | 'ops' | 'sup' | 'app'

export interface SessionUser {
  portal: Portal
  account: string
  name: string
  role: string
}

export const portalNames: Record<Portal, string> = {
  admin: '管理员端',
  ops: '运维端',
  sup: '监管端',
  app: '农户移动端',
}

export const demoUsers: Record<Portal, SessionUser> = {
  admin: { portal: 'admin', account: 'admin', name: '李明', role: '园区管理员' },
  ops: { portal: 'ops', account: 'ops', name: '张运维', role: '系统运维' },
  sup: { portal: 'sup', account: 'sup01', name: '黄洁', role: '监管人员' },
  app: { portal: 'app', account: 'wangq', name: '王强', role: '农户' },
}

/** 演示环境统一登录密码（最终校验以后端为准） */
export const DEMO_PASSWORD = '123456'

const STORAGE_KEY = 'agri_platform_sessions'
const sessions = reactive<Partial<Record<Portal, SessionUser>>>(load())

function load(): Partial<Record<Portal, SessionUser>> {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    return raw ? (JSON.parse(raw) as Partial<Record<Portal, SessionUser>>) : {}
  } catch {
    return {}
  }
}

function persist() {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(sessions))
  } catch {
    // ignore storage failures
  }
}

/** 当前持有的访问令牌，登录后由后端签发 */
const token = ref<string>(readToken())

function readToken(): string {
  try {
    return localStorage.getItem('agri_platform_token') ?? ''
  } catch {
    return ''
  }
}

// 脏数据清理：旧版本只存 session 不存 token，升级后 session 残留但无 token。
// 此时视为未登录，清空 session，避免 hasSession 误判导致接口 401 循环。
if (token.value === '' && Object.values(sessions).some(Boolean)) {
  for (const key of Object.keys(sessions)) {
    delete sessions[key as Portal]
  }
  persist()
}

export interface LoginResult {
  ok: boolean
  error?: string
}

export function useAuth() {
  /** 任一业务端已登录且持有令牌，才视为「已认证」（避免旧 session 无 token 的脏数据误判） */
  const hasSession = computed(() => token.value !== '' && Object.values(sessions).some(Boolean))

  /** 调用后端登录接口，成功则写入令牌与会话 */
  async function login(portal: Portal, account: string, password: string): Promise<LoginResult> {
    try {
      const data = await apiPost<{ token: string; user: SessionUser }>('/auth/login', {
        portal,
        account,
        password,
      })
      token.value = data.token
      try {
        localStorage.setItem('agri_platform_token', data.token)
      } catch {
        // ignore
      }
      sessions[portal] = data.user
      persist()
      return { ok: true }
    } catch (error) {
      if (error instanceof ApiError && error.status === 401) {
        return { ok: false, error: '账号或密码错误' }
      }
      const message = error instanceof Error ? error.message : '登录失败，请稍后重试'
      return { ok: false, error: message }
    }
  }

  function logout(portal: Portal) {
    delete sessions[portal]
    persist()
    // 所有业务端都退出后，清空访问令牌
    if (!Object.values(sessions).some(Boolean)) {
      token.value = ''
      try {
        localStorage.removeItem('agri_platform_token')
      } catch {
        // ignore
      }
    }
  }

  function session(portal: Portal) {
    // 未登录时返回 undefined，不再回退演示用户（避免掩盖未登录态）
    return computed(() => sessions[portal])
  }

  function isLoggedIn(portal: Portal) {
    return computed(() => token.value !== '' && Boolean(sessions[portal]))
  }

  return { sessions, login, logout, session, isLoggedIn, hasSession }
}
