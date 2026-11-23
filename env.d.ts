/// <reference types="vite/client" />

interface ImportMetaEnv {
  /** 后端接口前缀，默认 /api/v1，可通过 .env 文件指向真实后端 */
  readonly VITE_API_BASE_URL?: string
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}
