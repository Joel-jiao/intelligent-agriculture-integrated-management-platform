/**
 * 统一 HTTP 客户端
 *
 * 原则：前端不再内置任何业务数据，所有数据只能来自后端接口。
 * 请求失败时直接抛错，由调用方（数据层 / 页面）显式处理，
 * 绝不做「静默回退到本地假数据」这类兜底。
 */

/** 接口前缀，开发环境经 Vite 代理转发到 json-server（见 vite.config.ts） */
export const API_BASE_URL = (import.meta.env.VITE_API_BASE_URL as string | undefined) || '/api/v1'

/** 单次请求超时时间（毫秒） */
const DEFAULT_TIMEOUT = 8000

/** 登录后由后端签发的访问令牌（登录接口写入，受保护接口请求时携带） */
export const TOKEN_KEY = 'agri_platform_token'

function getToken(): string {
  try {
    return localStorage.getItem(TOKEN_KEY) ?? ''
  } catch {
    return ''
  }
}

export class ApiError extends Error {
  /** HTTP 状态码；网络不可达 / 超时为 null */
  readonly status: number | null
  /** 出错的请求地址 */
  readonly url: string

  constructor(message: string, options: { status?: number | null; url: string }) {
    super(message)
    this.name = 'ApiError'
    this.status = options.status ?? null
    this.url = options.url
  }
}

type QueryValue = string | number | boolean | null | undefined

function buildUrl(path: string, query?: Record<string, QueryValue>): string {
  const base = `${API_BASE_URL.replace(/\/$/, '')}${path.startsWith('/') ? path : `/${path}`}`
  if (!query) return base
  const search = new URLSearchParams()
  for (const [key, value] of Object.entries(query)) {
    if (value !== undefined && value !== null) search.append(key, String(value))
  }
  const qs = search.toString()
  return qs ? `${base}?${qs}` : base
}

export interface RequestOptions {
  query?: Record<string, QueryValue>
  body?: unknown
  method?: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE'
  timeout?: number
  signal?: AbortSignal
}

export async function request<T>(path: string, options: RequestOptions = {}): Promise<T> {
  const { query, body, method = 'GET', timeout = DEFAULT_TIMEOUT, signal } = options
  const url = buildUrl(path, query)
  const controller = new AbortController()
  const timer = window.setTimeout(() => controller.abort(), timeout)
  const abortByCaller = () => controller.abort()
  signal?.addEventListener('abort', abortByCaller)

  // 仅将 fetch 网络层纳入 try/catch：网络不可达 / 超时在此统一转成 ApiError；
  // 响应状态与解析产生的 ApiError 在 try 之外抛出、直接向上穿透，避免「本地捕获后重抛」。
  let response: Response
  try {
    response = await fetch(url, {
      method,
      signal: controller.signal,
      headers: {
        Accept: 'application/json',
        ...(body === undefined ? {} : { 'Content-Type': 'application/json' }),
        ...(getToken() ? { Authorization: `Bearer ${getToken()}` } : {}),
      },
      body: body === undefined ? undefined : JSON.stringify(body),
    })
  } catch (error) {
    if ((error as Error)?.name === 'AbortError') {
      throw new ApiError(`接口 ${path} 请求超时（${timeout}ms）`, { url })
    }
    throw new ApiError(`无法连接后端服务（${path}）`, { url })
  } finally {
    window.clearTimeout(timer)
    signal?.removeEventListener('abort', abortByCaller)
  }

  if (!response.ok) {
    throw new ApiError(`接口 ${path} 响应异常（HTTP ${response.status}）`, {
      status: response.status,
      url,
    })
  }

  if (response.status === 204) return undefined as T

  const text = await response.text()
  if (!text) return undefined as T

  try {
    return JSON.parse(text) as T
  } catch {
    throw new ApiError(`接口 ${path} 返回内容不是合法 JSON`, { status: response.status, url })
  }
}

export const apiGet = <T>(path: string, query?: Record<string, QueryValue>) =>
  request<T>(path, { query })

export const apiPost = <T>(path: string, body: unknown) =>
  request<T>(path, { method: 'POST', body })

export const apiPut = <T>(path: string, body: unknown) =>
  request<T>(path, { method: 'PUT', body })

export const apiPatch = <T>(path: string, body: unknown) =>
  request<T>(path, { method: 'PATCH', body })

export const apiDelete = <T>(path: string) => request<T>(path, { method: 'DELETE' })
