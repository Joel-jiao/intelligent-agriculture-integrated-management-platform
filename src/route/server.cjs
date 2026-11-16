/**
 * json-server 启动入口
 *
 * 为什么不用官方 CLI 的 --routes？
 *   json-server 0.17 的 rewriter 依赖 express-urlrewrite@1.4.0，
 *   它用「完整 URL（含 ?查询串）」去匹配锚定正则，导致任何带查询参数
 *   的请求（?plotId=P-01、?_limit=10 …）都无法命中 routes.json 的映射。
 *   此处改为自实现重写器：只匹配 pathname，查询串原样透传。
 *
 * 用法：
 *   node src/route/server.cjs            # 默认 127.0.0.1:3001
 *   PORT=4000 HOST=0.0.0.0 node src/route/server.cjs
 */
'use strict'

const path = require('node:path')
const fs = require('node:fs')
const JSON5 = require('json5') // json-server 0.17 自带依赖，支持带 // 注释的 routes.json
const jsonServer = require('json-server')
const routes = JSON5.parse(fs.readFileSync(path.join(__dirname, 'routes.json'), 'utf8'))

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
server.use(rewrite) // 自定义路由映射（真实后端风格地址）
server.use(jsonServer.defaults({ bodyParser: true })) // 日志 / CORS / 静态 / JSON 解析
server.use(jsonServer.router(dbFile)) // REST 路由，写操作持久化回 db.json

server.listen(PORT, HOST, () => {
  console.log(`\n  JSON Server (custom routes) is running at http://${HOST}:${PORT}/`)
  console.log('  Route mappings:')
  for (const [from, to] of Object.entries(routes)) {
    console.log(`    ${from}  ->  ${to}`)
  }
  console.log(`  DB file: ${dbFile}\n`)
})
