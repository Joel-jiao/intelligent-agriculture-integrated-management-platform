/// <reference types="vite/client" />

interface ImportMetaEnv {
  /** 后端接口前缀，默认 /api/v1（开发环境由 Vite 代理转发） */
  readonly VITE_API_BASE_URL?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
