import { reactive, computed } from 'vue'

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

export function useAuth() {
  function login(portal: Portal, account: string, role?: string) {
    const base = demoUsers[portal]
    sessions[portal] = {
      portal,
      account,
      name: base.name,
      role: role ?? base.role,
    }
    persist()
    return sessions[portal]
  }

  function logout(portal: Portal) {
    delete sessions[portal]
    persist()
  }

  function session(portal: Portal) {
    return computed(() => sessions[portal] ?? demoUsers[portal])
  }

  function isLoggedIn(portal: Portal) {
    return computed(() => Boolean(sessions[portal]))
  }

  return { sessions, login, logout, session, isLoggedIn }
}
