/**
 * json-server 启动入口
 *
 * 为什么不用官方 CLI 的 --routes？
 *   json-server 0.17 的 rewriter 依赖 express-urlrewrite@1.4.0，
 *   它用「完整 URL（含 ?查询串）」去匹配锚定正则，导致任何带查询参数
 *   的请求（?plotId=P-01、?_limit=10 …）都无法命中 routes.json 的映射。
 *   此处改为自实现重写器：只匹配 pathname，查询串原样透传。
 *
 * 鉴权（登录门禁）：
 *   POST /api/v1/auth/login 校验演示账号并签发 HMAC token；
 *   除公开白名单外，所有 /api/v1/* 请求都必须携带
 *   `Authorization: Bearer <token>`，否则返回 401。
 *   公开白名单仅含：登录接口、园区/系统基础信息、溯源公开查询
 *   （扫码溯源「无需登录」场景）与地块地理信息。
 *
 * 用法：
 *   node src/route/server.cjs            # 默认 127.0.0.1:3001
 *   PORT=4000 HOST=0.0.0.0 node src/route/server.cjs
 */
'use strict'

const path = require('node:path')
const fs = require('node:fs')
const crypto = require('node:crypto')
const JSON5 = require('json5') // json-server 0.17 自带依赖，支持带 // 注释的 routes.json
const jsonServer = require('json-server')
const routes = JSON5.parse(fs.readFileSync(path.join(__dirname, 'routes.json'), 'utf8'))

// ---------- 演示账号（与前端 useAuth.demoUsers 对齐） ----------
const ACCOUNTS = {
  admin: { portal: 'admin', account: 'admin', password: '123456', name: '李明', role: '园区管理员' },
  ops: { portal: 'ops', account: 'ops', password: '123456', name: '张运维', role: '系统运维' },
  sup: { portal: 'sup', account: 'sup01', password: '123456', name: '黄洁', role: '监管人员' },
  app: { portal: 'app', account: 'wangq', password: '123456', name: '王强', role: '农户' },
}

const TOKEN_SECRET = process.env.AUTH_SECRET || 'agri-platform-demo-secret-2026'
const TOKEN_TTL = 12 * 60 * 60 * 1000 // 12 小时

function signToken(payload) {
  const header = Buffer.from(JSON.stringify({ alg: 'HS256', typ: 'JWT' })).toString('base64url')
  const body = Buffer.from(JSON.stringify(payload)).toString('base64url')
  const signature = crypto
    .createHmac('sha256', TOKEN_SECRET)
    .update(`${header}.${body}`)
    .digest('base64url')
  return `${header}.${body}.${signature}`
}

function verifyToken(token) {
  try {
    const [header, body, signature] = token.split('.')
    if (!header || !body || !signature) return null
    const expected = crypto
      .createHmac('sha256', TOKEN_SECRET)
      .update(`${header}.${body}`)
      .digest('base64url')
    if (signature !== expected) return null
    const payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'))
    if (payload.exp && Date.now() > payload.exp) return null
    return payload
  } catch {
    return null
  }
}

// ---------- 登录接口 ----------
function loginHandler(req, res) {
  const { portal, account, password } = req.body || {}
  const entry = ACCOUNTS[portal]
  if (!entry || entry.account !== String(account ?? '').trim() || entry.password !== password) {
    return res.status(401).json({ error: '账号或密码错误' })
  }
  const token = signToken({
    portal: entry.portal,
    account: entry.account,
    name: entry.name,
    role: entry.role,
    exp: Date.now() + TOKEN_TTL,
  })
  res.json({
    token,
    user: { portal: entry.portal, account: entry.account, name: entry.name, role: entry.role },
  })
}

// ---------- 公开白名单（无需登录） ----------
const PUBLIC_PATTERNS = [
  /^\/api\/v1\/auth\/login$/,
  /^\/api\/v1\/park\/overview$/,
  /^\/api\/v1\/system\/info$/,
  /^\/api\/v1\/trace\/detail$/,
  /^\/api\/v1\/trace\/timeline$/,
  /^\/api\/v1\/trace\/batches(\/[^/]+)?$/, // 溯源批次档案（扫码公开查询）
  /^\/api\/v1\/trace\/inspections$/, // 检测报告（扫码公开查询）
  /^\/api\/v1\/trace\/recalls$/, // 召回记录（扫码公开查询）
  /^\/api\/v1\/trace\/[^/]+\/(detail|timeline)$/, // :batchNo 溯源详情/时间线
  /^\/api\/v1\/farm\/plots(\/[^/]+)?$/, // 地块地理信息（溯源 H5 / GIS 公开）
]

function authMiddleware(req, res, next) {
  const pathname = req.path || req.url.split('?')[0]
  if (PUBLIC_PATTERNS.some((re) => re.test(pathname))) return next()

  const auth = req.headers.authorization || ''
  const token = auth.startsWith('Bearer ') ? auth.slice(7) : ''
  const payload = verifyToken(token)
  if (!payload) {
    return res.status(401).json({ error: '未登录或登录已过期' })
  }
  req.user = payload
  next()
}

// ---------- routes.json -> 路径重写器 ----------
// 将 '/api/v1/farm/plots/:id' 编译为 /^\/api\/v1\/farm\/plots\/([^/]+)\/?$/
function compile(pattern) {
  const keys = []
  const source = pattern
    .split('/')
    .map((seg) => {
      if (seg.startsWith(':')) {
        keys.push(seg.slice(1))
        return '([^/]+)'
      }
      return seg.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')
    })
    .join('/')
  return { regex: new RegExp(`^${source}/?$`), keys }
}

const compiled = Object.entries(routes).map(([from, to]) => ({
  from: compile(from),
  to,
}))

// pathname 与查询串分离匹配；目标中的 :param 用捕获组回填
function rewrite(req, _res, next) {
  const qIndex = req.url.indexOf('?')
  const pathname = qIndex === -1 ? req.url : req.url.slice(0, qIndex)
  const search = qIndex === -1 ? '' : req.url.slice(qIndex)

  for (const { from, to } of compiled) {
    const m = from.regex.exec(pathname)
    if (!m) continue
    const target = to.replace(/:(\w+)/g, (raw, name) => {
      const i = from.keys.indexOf(name)
      return i >= 0 ? decodeURIComponent(m[i + 1]) : raw
    })
    req.url = target + search
    break
  }
  next()
}

// ---------- 启动服务 ----------
const PORT = Number(process.env.PORT || 3001)
const HOST = process.env.HOST || '127.0.0.1'
const dbFile = path.join(__dirname, 'db.json')

const server = jsonServer.create()

// 顺序：CORS/bodyParser 等基础中间件 → 鉴权 → 登录 → 路径重写 → 数据路由
// 注意：鉴权与登录必须在 rewrite 之前，基于原始 /api/v1 路径判断
server.use(jsonServer.defaults({ bodyParser: true }))
server.use(authMiddleware)
server.post('/api/v1/auth/login', loginHandler)
server.use(rewrite)
server.use(jsonServer.router(dbFile))

server.listen(PORT, HOST, () => {
  console.log(`\n  JSON Server (custom routes) is running at http://${HOST}:${PORT}/`)
  console.log('  Auth: POST /api/v1/auth/login  (Bearer token required for protected endpoints)')
  console.log('  Route mappings:')
  for (const [from, to] of Object.entries(routes)) {
    console.log(`    ${from}  ->  ${to}`)
  }
  console.log(`  DB file: ${dbFile}\n`)
})
