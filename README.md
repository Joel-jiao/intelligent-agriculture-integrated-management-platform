# 智慧农业综合管理平台（IAIMP）

> 一个平台 · 四类角色 · 两端一屏
> Intelligent Agriculture Integrated Management Platform

面向现代农业园区的综合管理系统：把**物联网监测、远程控制、农事生产、质量溯源、监管预警、系统运维**收进同一套前端，用四个业务门户分别服务园区管理员、运维人员、监管部门和一线农户，另配指挥中心大屏与面向消费者的扫码溯源页。

前端 **Vue 3 + TypeScript + Vite + Ant Design Vue**，后端 **Spring Boot 3 + MySQL 8**，数据全部来自真实接口，不含 mock。

---

## 功能概览

| 门户 | 使用角色 | 核心能力 |
| --- | --- | --- |
| 管理员端 `/login` | 园区业务管理员 | 综合看板、环境监测、设备/灌溉/联动控制、地块档案、农事工单、农资与采收、溯源批次与赋码、检测报告、召回、GIS、告警处置、报表导出、大屏配置 |
| 运维端 `/ops/login` | 系统运维人员 | 运维工作台、租户、用户、RBAC 角色权限、设备接入、数据字典、第三方接口、文件存储、登录/操作日志、数据库备份 |
| 监管端 `/sup/login` | 政府农业监管部门 | 辖区监管总览、质量安全总览、溯源查询、农药农资台账、监管预警、监管报表 |
| 农户移动端 `/app/login` | 一线生产人员 | 任务列表与详情、现场打卡、告警消息、环境查看、设备控制、扫码录入、我的地块与地块申报 |
| 指挥中心大屏 `/screen` | 园区管理者 | 深色可视化大屏：综合态势、环境曲线、设备状态、告警动态（需登录） |
| 溯源 H5 `/trace/h5/:code` | 消费者 | 微信扫码免登录查看产地、批次、农事时间线、检测报告 |
| 业务端总览 `/portals` | 所有人 | 各门户入口导航（免登录） |

规模化数据：**62 个 Vue 页面组件**、**108 个 REST 端点**、**48 张数据表**（`accounts` + 47 张业务表）。

---

## 技术栈

| 层次 | 选型 |
| --- | --- |
| 前端框架 | Vue 3.5（`<script setup>` + Composition API） |
| 语言 / 构建 | TypeScript 6、Vite 8、`vue-tsc` |
| 路由 | Vue Router 4（History 模式 + 全局登录门禁） |
| UI | Ant Design Vue 4（按需注册）+ 自有设计系统（CSS 变量，支持明暗主题） |
| 状态 | 轻量自建仓库：`reactive` 容器 + 统一加载，无 Pinia/Vuex |
| 图表 / 地图 | 自绘 SVG 组件（LineChart / BarChart / DonutChart / GisMap），不引入图表库 |
| 后端 | Java 21、Spring Boot 3.3.13、Spring Web MVC |
| 持久化 | Spring Data JPA（仅账号）+ JdbcTemplate（业务表通用 CRUD） |
| 数据库 | MySQL 8.0（`utf8mb4`） |
| 认证 | 手写 HS256 JWT，`Authorization: Bearer <token>`，有效期 12 小时 |
| 接口文档 | Knife4j 4.5 / OpenAPI 3 |

---

## 整体架构

```
┌──────────────────────────── 浏览器 ────────────────────────────┐
│  Vue SPA (5173)                                                │
│  ├─ App.vue        数据准入层：ready 才渲染业务页               │
│  ├─ router         按 portal 做登录门禁                         │
│  ├─ pages          4 门户 + 大屏 + 溯源 H5 + 导航页             │
│  └─ api/store      空容器 → loadAllData() 就地填充              │
└───────────────────────────┬────────────────────────────────────┘
                            │ /api/v1/**（dev 由 Vite 代理）
┌───────────────────────────▼────────────────────────────────────┐
│  Spring Boot (3001)                                            │
│  ├─ AuthInterceptor  除白名单外校验 Bearer 令牌                 │
│  ├─ api/*Controller  10 个业务域控制器 + 认证，共 108 个端点     │
│  ├─ ResourceService  collection=表名 的通用 CRUD                │
│  └─ SchemaService    读取列元数据，负责 JSON ↔ 列值转换         │
└───────────────────────────┬────────────────────────────────────┘
                            │ JDBC
                  ┌────────────────────────────┐
                  │  MySQL 8 · agri_platform   │   48 张表（accounts + 47 张业务表）
                  └────────────────────────────┘
```

数据流：**登录 → 拿 JWT → `loadAllData()` 并发拉取 34 个集合 + 13 个明细接口 → 填充 store → 页面渲染**。任一请求失败即判定后端不可用，清空数据并显示「后端服务不可用」准入页，不展示任何残留/假数据。

---

## 目录结构

```
intelligent-agriculture-integrated-management-platform/
├── src/
│   ├── api/            http 客户端、接口清单、全局数据仓库
│   ├── router/         全部路由与登录门禁
│   ├── layouts/        PortalLayout（PC 侧边栏）/ MobileLayout（手机视口）
│   ├── pages/          admin / ops / sup / app / iot / farm / trace / supervise / screen …
│   ├── components/ui/  PageHeader、StatCard、图表、GisMap、AppModal、Pager、BackendGate…
│   ├── composables/    useAuth / useTheme / useToast / useNetwork / useAntdTheme
│   ├── config/menus.ts 各门户菜单与移动端 tab
│   ├── data/types.ts   全部实体类型
│   ├── utils/format.ts 格式化与 CSV 导出
│   └── assets/theme.css 设计系统（CSS 变量 + 明暗主题）
├── IAIMP-Backend/
│   ├── sql/            agri_platform.sql（建表）/ agri_platform_data.sql（种子）
│   ├── src/main/java/com/joel/iaimpbackend/
│   │   ├── account/    账号、登录、改密
│   │   ├── api/        Farm / Iot / Control / Trace / Quality / Supervise /
│   │   │               System / Report / AlarmMessage / Overview 控制器
│   │   ├── common/     CORS、鉴权拦截器、JWT、全局异常、Knife4j
│   │   └── resource/   通用 CRUD、表结构元数据、集合常量、种子导入
│   └── src/main/resources/
│       ├── application.yaml
│       └── seed/db.json    首启种子（含 4 个演示账号）
├── AGENTS.md           工程约定与改造指南（协作者/AI 必读）
├── vite.config.ts
└── package.json
```

---

## 快速开始

### 1. 环境要求

| 依赖 | 版本 |
| --- | --- |
| Node.js | `^22.18.0` 或 `>= 24.12.0`（见 `package.json` engines） |
| JDK | 21 |
| MySQL | 8.0+ |
| Maven | 随仓库附带 `mvnw`，无需单独安装 |

### 2. 初始化数据库

```bash
cd IAIMP-Backend

# 建库 + 48 张表
mysql --default-character-set=utf8mb4 -u root -p < sql/agri_platform.sql

# 可选：导入演示数据（259 条）；后端首次启动也会从 seed/db.json 自动导入
mysql --default-character-set=utf8mb4 -u root -p agri_platform < sql/agri_platform_data.sql
```

> **注意**：`--default-character-set=utf8mb4` 不能省，否则 Windows 下会因字符集不匹配报 `Data too long`。

### 3. 启动后端

```bash
cd IAIMP-Backend
./mvnw spring-boot:run        # Windows: .\mvnw.cmd spring-boot:run
```

默认端口 **3001**，数据库连接在 `src/main/resources/application.yaml`（默认 `root` / `password`，库 `agri_platform`）。

首次启动且 `accounts` 表为空时，`DataSeeder` 会把 `seed/db.json` 全量写入（账号密码自动转 BCrypt）。

### 4. 启动前端

```bash
npm install
npm run dev
```

打开 <http://localhost:5173>。开发环境下 `/api` 由 Vite 代理到 `http://127.0.0.1:3001`，无需处理跨域。

### 5. 访问地址

| 地址 | 说明 |
| --- | --- |
| <http://localhost:5173/portals> | 业务端总览（免登录） |
| <http://localhost:5173/login> | 管理员端登录 |
| <http://localhost:5173/ops/login> | 运维端登录 |
| <http://localhost:5173/sup/login> | 监管端登录 |
| <http://localhost:5173/app/login> | 农户移动端登录 |
| `http://localhost:5173/trace/h5/{批次号}` | 溯源 H5（免登录，批次号取自批次档案） |
| <http://localhost:5173/screen> | 指挥中心大屏（需登录） |
| <http://127.0.0.1:3001/doc.html> | Knife4j 接口文档 |

---

## 环境变量

### 前端（`.env` / `.env.local`，可选）

| 变量 | 默认 | 说明 |
| --- | --- | --- |
| `VITE_API_BASE_URL` | `/api/v1` | 接口前缀。留空走 Vite 代理；生产可指向完整域名 |

### 后端（环境变量可覆盖 `application.yaml`）

| 变量 | 默认 | 说明 |
| --- | --- | --- |
| `SERVER_PORT` | `3001` | 服务端口 |
| `DB_URL` | `jdbc:mysql://127.0.0.1:3306/agri_platform?...` | JDBC 连接串 |
| `AUTH_SECRET` | `agri-platform-demo-secret-2026` | JWT 签名密钥（**生产必须覆盖**） |
| `AUTH_TTL_MS` | `43200000` | 令牌有效期（12 小时，毫秒） |
| `CORS_ALLOWED_ORIGINS` | `http://localhost:5173,http://127.0.0.1:5173` | 允许的前端来源，逗号分隔 |

> 数据库用户名/密码目前写死在 `application.yaml`（`root` / `password`），换机时请先修改，或自行改为 `${DB_USERNAME:root}` 形式。

---

## 账号与登录

- 账号由 4 个门户共用 `accounts` 表，按 `portal`（`admin`/`ops`/`sup`/`app`）+ `account` 唯一定位，密码为 BCrypt 哈希。
- 演示账号见 `IAIMP-Backend/src/main/resources/seed/db.json` 的 `accounts` 数组（明文仅用于种子导入，入库即加密）。
- 登录流程：`POST /api/v1/auth/login` → 校验账号状态与密码 → 签发 JWT 并写入登录日志 → 前端保存 `token` + `session` → 全量拉取业务数据 → 跳转门户首页。
- 修改密码：`POST /api/v1/auth/change-password`（需携带令牌，校验原密码）。
- 令牌过期或损坏时，前端会在启动时自动清理登录态，回到登录页。

---

## 接口说明

### 基础约定

- **前缀**：`/api/v1`
- **鉴权**：除白名单外，所有接口需 `Authorization: Bearer <token>`，缺失/失效返回 `401 {"error":"未登录或登录已过期"}`。
- **错误格式**：统一 `{"error": "..."}`，由 `GlobalExceptionHandler` 输出，前端直接透传给用户。
- **接口风格**：列表 `GET /集合` 返回数组；单例 `GET /xxx` 返回对象（无数据时为 `200` + 空体）；`PATCH` 为浅合并更新；`DELETE` 按 `id` 删除。集合名与数据库表名严格一致。
- **在线调试**：启动后端后访问 <http://127.0.0.1:3001/doc.html>，先调登录接口拿 token，再在全局参数里填 `Bearer <token>`。

### 公开白名单（免登录）

```
POST /auth/login
GET  /park/overview
GET  /system/info
GET  /trace/detail          GET /trace/{batchNo}/detail
GET  /trace/timeline        GET /trace/{batchNo}/timeline
GET  /trace/batches         GET /trace/batches/{id}
GET  /trace/inspections     GET /trace/recalls
GET  /farm/plots            GET /farm/plots/{id}
```

### 接口域划分

| 前缀 | 内容 |
| --- | --- |
| `/auth` | 登录、修改密码 |
| `/farm` | 地块、采收、农资、工单、地块审核、工单打卡 |
| `/farmer` | 农户「我的地块」 |
| `/iot` | 设备、摄像头、环境曲线、操作记录、录像回放 |
| `/control` | 控制日志、灌溉、联动策略 |
| `/alarm`、`/message` | 告警记录、消息 |
| `/trace` | 批次、检测、召回、溯源详情与时间线 |
| `/quality` | 质量总览、农药台账 |
| `/supervise` | 监管预警 |
| `/system` | 用户、角色、日志、备份、开放接口、文件、租户、字典、系统信息 |
| `/park`、`/weather`、`/energy`、`/screen`、`/report` | 园区概览、天气、水电、大屏配置、报表 |

---

## 构建与部署

```bash
# 前端产物 → dist/
npm run build

# 后端产物 → IAIMP-Backend/target/*.jar
cd IAIMP-Backend && ./mvnw -DskipTests package
java -jar target/IAIMP-Backend-0.0.1-SNAPSHOT.jar
```

Nginx 参考（History 路由需回退到 `index.html`，接口反代到后端）：

```nginx
server {
    listen 80;
    root /var/www/iaimp;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api/ {
        proxy_pass http://127.0.0.1:3001;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

生产部署请务必：覆盖 `AUTH_SECRET`、收紧 `CORS_ALLOWED_ORIGINS`、修改数据库默认口令、关闭或限制 Knife4j 文档访问。

---

## 开发约定（摘要）

完整约定与「踩坑清单」见 [AGENTS.md](./AGENTS.md)，要点：

1. **不写假数据**：页面只从 `@/api/store` 取数，接口失败就显式报错，不做静默兜底。
2. **store 引用稳定**：新增集合要同步 `clearAll()` / `loadAllData()`，不能整体重新赋值。
3. **受保护路由必带** `meta.requiresAuth` + `meta.portal`。
4. **新增 AntD 组件必须在 `main.ts` 注册**。
5. **样式只用 `theme.css` 的 CSS 变量**，保证明暗主题一致。
6. **提交前跑** `npm run type-check`。

---

## 已知限制与后续计划

- **写操作尚未全面落库**：除「修改密码」外，多数页面（告警处置、资料保存、工单新建等）目前只更新前端内存并提示成功。后端多数资源已提供 `POST/PATCH/DELETE`（告警、工单、用户、租户、字典、批次等），控制类与日志类仍为只读，待逐页接入。
- **`DataSeeder` 按 `accounts` 判空整体跳过**：清空业务表后不会自动补种，需执行 `sql/agri_platform_data.sql`。
- **未清理的遗留文件**：`src/layouts/BasicLayout.vue`、`src/components/GlobalHeader.vue`、`src/components/GlobalFooter.vue`、`src/pages/HomePage.vue`。
- **权限控制粒度**：目前为「门户级」登录校验，接口层尚未按角色/租户做数据隔离。
- 后续可做：真实 MQTT/视频流接入、报表异步导出、审计日志全量埋点、单元测试与 E2E。

---

## 项目信息

- 项目名：智慧农业综合管理平台（IAIMP）
- 类型：本科毕业设计 / 课程综合实践
- 作者：重庆工程学院 · 人工智能与计算机学院 · 计算机科学与技术 · 24 计科 2 班 · 吴鸿宇
- 时间：2026
