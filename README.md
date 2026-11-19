# 智慧农业综合管理平台

基于 Vue 3 + TypeScript + Vite 构建的智慧农业综合管控平台，覆盖**园区业务管理端、系统运维端、监管端、农户移动端**四类门户，集成物联网环境监测、设备远程控制、农事工单、农资库存、质量溯源、GIS 地图与指挥中心大屏等模块。

当前版本为**前后端分离**演示工程：前端产物中**不包含任何业务数据**，所有数据（园区概览、地块、设备、告警、工单、溯源、字典…）统一通过 `/api/v1/*` 从后端接口读取；本地开发时后端由 `json-server` + 自定义路由（`src/route/`）模拟，数据持久化在 `src/route/db.json`。**后端未启动时，应用会停留在「后端服务不可用」准入页，不渲染任何业务页面，也不会回退到本地假数据。** 登录态保存在浏览器 `localStorage`。

## 技术栈

| 类别 | 说明 |
| --- | --- |
| 框架 | Vue 3.5（`<script setup>` + 组合式 API） |
| 路由 | Vue Router 4（History 模式） |
| 语言 | TypeScript 6 |
| 构建 | Vite 8 + `@vitejs/plugin-vue` |
| 类型检查 | `vue-tsc` |
| 样式 | 原生 CSS + CSS 变量（`src/assets/theme.css`） |
| 图表 | 自研 SVG 图表组件（Bar / Line / Donut） |

## 环境要求

- Node.js `^22.18.0 || >=24.12.0`（见 `package.json` 的 `engines` 字段）
- npm（仓库使用 `package-lock.json`）

## 快速开始

```sh
# 安装依赖
npm install

# 同时启动前端（5173）与后端接口服务（3001）——推荐
npm run dev:all

# 也可以分别启动
npm run dev       # 仅前端，http://localhost:5173（此时若无后端，页面会停在连接失败页）
npm run dev:api   # 仅后端接口，http://127.0.0.1:3001

# 类型检查 + 构建生产包
npm run build

# 本地预览构建产物（需要后端同时运行）
npm run preview
```

> 前端通过 Vite 代理把 `/api` 转发到 `http://127.0.0.1:3001`，开发与 `preview` 均已配置。

### npm 脚本说明

| 命令 | 作用 |
| --- | --- |
| `npm run dev` | 启动 Vite 开发服务器，支持热更新 |
| `npm run dev:api` | 启动 json-server 接口服务（自定义路由，3001 端口） |
| `npm run dev:all` | 并行启动前后端 |
| `npm run build` | 并行执行 `type-check` 与 `build-only` |
| `npm run build-only` | 仅执行 `vite build`，输出到 `dist/` |
| `npm run preview` | 预览 `dist/` 构建结果 |
| `npm run type-check` | 使用 `vue-tsc --build` 做类型检查 |

## 环境配置文件

仓库当前**未包含** `.env` 系列文件，前端默认使用 Vite 内置变量（如 `import.meta.env.BASE_URL`），接口前缀默认 `/api/v1`。如需接入真实后端或区分多环境，按 Vite 约定在项目根目录新增以下文件（已被 `.gitignore` 中的 `*.local` 规则部分覆盖，敏感配置建议使用 `.env.local`）：

```ini
# .env.development —— 开发环境（留空即使用 Vite 代理的 /api/v1）
VITE_APP_TITLE=智慧农业综合管理平台
VITE_API_BASE_URL=/api/v1
```

```ini
# .env.production —— 生产环境，指向真实后端
VITE_APP_TITLE=智慧农业综合管理平台
VITE_API_BASE_URL=https://api.example.com/api/v1
```

使用约定：

- 仅以 `VITE_` 开头的变量会注入客户端，通过 `import.meta.env.VITE_XXX` 读取。
- 接口前缀只在 `src/api/http.ts` 中读取一次，页面不拼接接口地址。
- 新增变量后，建议在 `env.d.ts` 中补充 `ImportMetaEnv` 类型声明以获得类型提示。
- 修改 `.env` 文件后需重启开发服务器。

### 其他配置文件

| 文件 | 说明 |
| --- | --- |
| `vite.config.ts` | Vite 配置，注册 Vue / DevTools 插件，配置 `@` → `./src` 路径别名 |
| `env.d.ts` | 引入 `vite/client` 类型，声明环境变量类型 |
| `tsconfig.json` | 根 TS 配置，引用 app 与 node 两套子配置 |
| `tsconfig.app.json` | 应用侧 TS 配置，含 `@/*` 路径映射 |
| `tsconfig.node.json` | 构建工具（Vite 配置等）的 Node 侧 TS 配置 |
| `index.html` | 应用入口 HTML，挂载 `#app` |
| `.gitignore` | 忽略 `node_modules`、`dist`、日志、IDE 与临时文件 |
| `.vscode/extensions.json` | 推荐安装 Vue (Official) 插件 |

## 目录结构

```text
.
├── src/
│   ├── api/                     # 数据访问层（唯一数据入口）
│   │   ├── http.ts              # 统一 fetch 封装：基址、超时、错误类型
│   │   ├── endpoints.ts         # 接口清单与类型化请求函数
│   │   └── store.ts             # 响应式数据仓库：启动时从后端全量加载，失败即清空
│   ├── assets/
│   │   ├── base.css             # 基础样式与颜色变量
│   │   ├── theme.css            # 平台主题样式（布局、卡片、表格、按钮等）
│   │   └── main.css             # 样式总入口
│   ├── components/
│   │   ├── ui/                  # 通用组件：图表、GIS 地图、弹窗、分页、二维码、登录卡等
│   │   ├── GlobalHeader.vue
│   │   └── GlobalFooter.vue
│   ├── composables/
│   │   ├── useAuth.ts           # 四端登录态（localStorage 持久化）
│   │   └── useToast.ts          # 全局轻提示
│   ├── config/
│   │   └── menus.ts             # 管理员端 / 运维端 / 监管端菜单及移动端 Tab 配置
│   ├── data/
│   │   └── types.ts             # 业务实体类型定义（不含任何数据）
│   ├── layouts/
│   │   ├── PortalLayout.vue     # 桌面端通用布局（侧边菜单 + 顶栏 + 内容区）
│   │   ├── MobileLayout.vue     # 农户移动端布局（底部 Tab）
│   │   └── BasicLayout.vue
│   ├── pages/                   # 按业务域拆分的页面，详见下表
│   ├── route/                   # 本地模拟后端（json-server）
│   │   ├── server.cjs           # 启动入口：自实现路由重写器，查询串透传
│   │   ├── routes.json          # /api/v1/* 真实后端风格地址 → 集合映射
│   │   └── db.json              # 后端数据集（写操作会持久化到这里）
│   ├── router/
│   │   └── index.ts             # 路由表、门户前缀与页面标题
│   ├── utils/
│   │   └── format.ts            # 时间/数字格式化、CSV 拼接与文件下载
│   ├── App.vue
│   └── main.ts                  # 应用入口，挂载路由
├── env.d.ts
├── index.html
├── package.json
├── tsconfig.json
├── tsconfig.app.json
├── tsconfig.node.json
└── vite.config.ts
```

### 页面目录（`src/pages/`）

| 目录 | 业务模块 |
| --- | --- |
| `home/` | 综合数据看板、农户工作台首页 |
| `iot/` | 环境数据监测、设备状态监控、视频监控、水电计量统计 |
| `control/` | 设备远程控制、自动联动策略 |
| `farm/` | GIS 地块档案、农事工单列表/详情、农资库存、采收登记 |
| `trace/` | 溯源批次档案、溯源码生成、检测报告、产品召回、H5 溯源查询、扫码录入 |
| `gis/` | GIS 综合地图总览 |
| `alarm/` | 告警信息处理 |
| `report/` | 综合报表导出 |
| `screen/` | 指挥中心大屏 |
| `ops/` | 运维工作台、用户管理、RBAC 角色权限、设备接入、数据字典、第三方接口、文件存储、登录/操作日志、数据库备份、运维个人设置 |
| `supervise/` | 监管总览、辖区质量安全、溯源查询、农药台账、监管预警、监管报表、监管账号设置 |
| `admin/` | 管理员个人信息设置 |
| `task/` | 移动端农事任务列表/详情 |
| `message/` | 移动端告警消息 |
| `env/` | 移动端环境数据查看 |
| `device/` | 移动端设备控制 |
| `mine/` | 移动端个人中心 |
| `login/` | 农户移动端登录 |
| `public/` | 管理员端登录 |

## 门户与路由入口

| 门户 | 登录地址 | 演示账号 / 密码 | 首页 |
| --- | --- | --- | --- |
| 管理员端 | `/login` | `admin` / `123456` | `/dashboard` |
| 运维端 | `/ops/login` | `ops` / `123456` | `/ops/workbench` |
| 监管端 | `/sup/login` | `sup01` / `123456` | `/sup/overview` |
| 农户移动端 | `/app/login` | `wangq` / `123456` | `/app/home` |

> 演示账号与密码统一维护在后端 `src/route/db.json` 的 `accounts` 集合，前端不内置任何账号或密码。

其他独立入口：

- `/portals`：业务端总览与切换
- `/screen`：指挥中心大屏（独立全屏页面）
- `/trace/h5/:code`：农产品溯源 H5 查询页，可直接分享访问

> 登录由后端 `POST /api/v1/auth/login` 校验（账号密码存于 `src/route/db.json` 的 `accounts` 集合），校验通过签发 HMAC 访问令牌；前端仅将令牌与会话信息写入 `localStorage` 的 `agri_platform_token` / `agri_platform_sessions` 键，不再内置或校验任何演示账号、密码。

## 数据读取约定

**前端不存业务数据，一切以接口为准。**

1. 页面统一 `import { plots, devices, ... } from '@/api/store'`，不再从任何本地文件读取业务数据（`src/data/mock.ts` 已删除）。
2. `src/api/store.ts` 在应用启动时（`App.vue` 的 `loadAllData()`）并发请求全部接口，把响应「就地填充」进响应式容器，页面因此可以直接用同步写法访问数据。
3. 任一接口失败即判定后端不可用：容器被清空，状态转为 `error`，`BackendGate` 准入页拦截全部页面，只提供「重新连接」入口——**不会回退到本地假数据**。
4. 取数地址只在 `src/api/endpoints.ts` 维护，与 `src/route/routes.json` 一一对应；接入真实后端时改这两处即可，页面无需改动。
5. 新增一个业务数据集需同步四处：`routes.json` 路由映射、`db.json` 数据、`endpoints.ts` 请求函数、`store.ts` 容器与加载逻辑。
6. 写操作（新增/修改/删除）也应走 `src/api/endpoints.ts` 中的写函数，避免页面直接改动内存副本后再无持久化。

## 开发约定

- 页面按业务域存放在 `src/pages/<domain>/` 下，新增页面需同步在 `src/router/index.ts` 注册，并在 `src/config/menus.ts` 增加菜单项。
- 可复用组件统一放在 `src/components/ui/`，通过 `@/components/ui/xxx.vue` 引用。
- 业务实体类型定义在 `src/data/types.ts`（只放类型，不放数据），业务数据集维护在 `src/route/db.json`。
- 路径别名 `@` 指向 `src`，不要在代码中使用较长的相对路径。
- 路由使用 History 模式，部署到静态服务器时需配置回退到 `index.html`（SPA fallback）。

## 部署说明

```sh
npm run build
```

将生成的 `dist/` 部署到任意静态服务器；若部署在子路径下，需在 `vite.config.ts` 中配置 `base` 并同步服务器路由重写规则。

**前端必须配合后端使用**：`dist/` 内不含任何业务数据，部署时需保证 `VITE_API_BASE_URL` 指向的后端接口可访问（本地联调可用 `npm run preview`，已配置 `/api` 代理到 3001）。
