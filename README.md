# 智慧农业综合管理平台

基于 Vue 3 + TypeScript + Vite 构建的智慧农业综合管控平台，覆盖**园区业务管理端、系统运维端、监管端、农户移动端**四类门户，集成物联网环境监测、设备远程控制、农事工单、农资库存、质量溯源、GIS 地图与指挥中心大屏等模块。

当前版本为纯前端演示工程，业务数据来自 `src/data/mock.ts`，登录态保存在浏览器 `localStorage`。

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

# 启动开发服务器（默认 http://localhost:5173）
npm run dev

# 类型检查 + 构建生产包
npm run build

# 本地预览构建产物
npm run preview
```

### npm 脚本说明

| 命令 | 作用 |
| --- | --- |
| `npm run dev` | 启动 Vite 开发服务器，支持热更新 |
| `npm run build` | 并行执行 `type-check` 与 `build-only` |
| `npm run build-only` | 仅执行 `vite build`，输出到 `dist/` |
| `npm run preview` | 预览 `dist/` 构建结果 |
| `npm run type-check` | 使用 `vue-tsc --build` 做类型检查 |

## 环境配置文件

仓库当前**未包含** `.env` 系列文件，前端默认使用 Vite 内置变量（如 `import.meta.env.BASE_URL`）。如需接入真实后端或区分多环境，按 Vite 约定在项目根目录新增以下文件（已被 `.gitignore` 中的 `*.local` 规则部分覆盖，敏感配置建议使用 `.env.local`）：

```ini
# .env.development —— 开发环境
VITE_APP_TITLE=智慧农业综合管理平台
VITE_API_BASE_URL=/api
VITE_USE_MOCK=true
```

```ini
# .env.production —— 生产环境
VITE_APP_TITLE=智慧农业综合管理平台
VITE_API_BASE_URL=https://api.example.com
VITE_USE_MOCK=false
```

使用约定：

- 仅以 `VITE_` 开头的变量会注入客户端，通过 `import.meta.env.VITE_XXX` 读取。
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
├── .vscode/                     # 编辑器推荐配置
├── src/
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
│   │   ├── mock.ts              # 演示业务数据与聚合统计
│   │   └── types.ts             # 业务实体类型定义
│   ├── layouts/
│   │   ├── PortalLayout.vue     # 桌面端通用布局（侧边菜单 + 顶栏 + 内容区）
│   │   ├── MobileLayout.vue     # 农户移动端布局（底部 Tab）
│   │   └── BasicLayout.vue
│   ├── pages/                   # 按业务域拆分的页面，详见下表
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
| 农户移动端 | `/app/login` | 任意账号 / `123456` | `/app/home` |

其他独立入口：

- `/portals`：业务端总览与切换
- `/screen`：指挥中心大屏（独立全屏页面）
- `/trace/h5/:code`：农产品溯源 H5 查询页，可直接分享访问

> 演示登录仅校验账号非空、密码不少于 6 位，不请求后端接口；会话信息存放在 `localStorage` 的 `agri_platform_sessions` 键中。

## 开发约定

- 页面按业务域存放在 `src/pages/<domain>/` 下，新增页面需同步在 `src/router/index.ts` 注册，并在 `src/config/menus.ts` 增加菜单项。
- 可复用组件统一放在 `src/components/ui/`，通过 `@/components/ui/xxx.vue` 引用。
- 业务实体类型定义在 `src/data/types.ts`，演示数据集中维护在 `src/data/mock.ts`。
- 路径别名 `@` 指向 `src`，不要在代码中使用较长的相对路径。
- 路由使用 History 模式，部署到静态服务器时需配置回退到 `index.html`（SPA fallback）。

## 部署说明

```sh
npm run build
```

将生成的 `dist/` 目录部署到任意静态服务器即可；若部署在子路径下，需在 `vite.config.ts` 中配置 `base` 并同步服务器路由重写规则。
