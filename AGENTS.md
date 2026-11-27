# AGENTS.md

> 本文件面向在本仓库工作的 AI 编码代理（也适用于人类协作者）：说明项目全貌、架构约定、常见改造路径与踩过的坑。
> 修改代码前请先读完「必须遵守的约定」与「已知问题」。

---

## 1. 项目是什么

**智慧农业综合管理平台（IAIMP）**：面向现代农业园区的综合管理系统。一个 Vue 单页应用内承载 **4 个业务门户**（管理员端 / 运维端 / 监管端 / 农户移动端），外加**指挥中心大屏**、**公开溯源 H5** 和**业务端导航页**；后端为 Spring Boot + MySQL，提供统一 REST 接口。

当前阶段：已从 `json-server` 假后端迁移到真实 Spring Boot 后端。**读链路已全通**（登录后一次性并发拉取全部业务数据），**写链路大部分仍是前端内存态**（见 §5.3 / §8）。

| 层 | 技术 |
| --- | --- |
| 前端 | Vue 3.5（`<script setup>`）、TypeScript 6、Vite 8、Vue Router 4、Ant Design Vue 4、dayjs |
| 后端 | Java 21、Spring Boot 3.3.13、Spring Data JPA（仅 `accounts`）、JdbcTemplate（业务表）、Knife4j 4.5 |
| 数据库 | MySQL 8.0（库 `agri_platform`，48 张表：`accounts` + 47 张业务表，utf8mb4） |
| 鉴权 | 手写 HS256 JWT（`exp` 为**毫秒**），`Authorization: Bearer <token>` |

---

## 2. 常用命令

### 前端（仓库根目录）

```bash
npm install
npm run dev          # Vite dev server，默认 5173；/api 代理到 127.0.0.1:3001
npm run type-check   # vue-tsc --build（唯一自动化门禁）
npm run build        # type-check + vite build → dist/
npm run preview
```

### 后端（`IAIMP-Backend/`）

```bash
./mvnw spring-boot:run          # Windows PowerShell 用 .\mvnw.cmd
./mvnw -DskipTests compile
./mvnw test
```

### 数据库

```bash
mysql --default-character-set=utf8mb4 -u root -p < sql/agri_platform.sql
mysql --default-character-set=utf8mb4 -u root -p agri_platform < sql/agri_platform_data.sql
```

> `--default-character-set=utf8mb4` **不可省略**：Windows 下 mysql 客户端默认字符集会导致中文首行即报 `Data too long`。

---

## 3. 目录地图

```
.
├── index.html                 # 挂载点
├── vite.config.ts             # @ 别名 + /api 代理（勿删，见 §8.1）
├── env.d.ts                   # VITE_API_BASE_URL 类型声明
├── src/
│   ├── main.ts                # 应用入口；AntD 组件「按需显式注册」在此
│   ├── App.vue                # ConfigProvider + 数据准入层（BackendGate）
│   ├── api/
│   │   ├── http.ts            # 统一 fetch 客户端：超时、Bearer、ApiError
│   │   ├── endpoints.ts       # 接口清单（ENDPOINTS / AGGREGATE_ENDPOINTS / DETAIL_ENDPOINTS）
│   │   └── store.ts           # 全局数据仓库：空容器 + loadAllData 就地填充
│   ├── router/index.ts        # 全部路由 + 登录门禁 beforeEach
│   ├── config/menus.ts        # 三个 PC 门户菜单 + 移动端 tab
│   ├── composables/           # useAuth / useTheme / useToast / useNetwork / useAntdTheme
│   ├── layouts/               # PortalLayout（PC 侧边栏）/ MobileLayout（手机壳）
│   ├── components/ui/         # 自有基础组件：PageHeader、StatCard、图表、GIS、弹窗、分页…
│   ├── pages/                 # 按业务域分目录（admin/ops/sup/app/iot/farm/trace/...）
│   ├── data/types.ts          # 全部业务实体类型（与后端 JSON 字段一一对应）
│   ├── utils/format.ts        # 数字/日期格式化、CSV 导出
│   └── assets/theme.css       # 设计系统：CSS 变量 + 明暗主题（3800+ 行，唯一色板来源）
└── IAIMP-Backend/
    ├── sql/                   # agri_platform.sql（48 表）、agri_platform_data.sql（259 条种子）
    └── src/main/java/com/joel/iaimpbackend/
        ├── account/           # 账号实体、AuthController/AuthService、登录 DTO
        ├── api/               # 10 个域控制器（Farm/Iot/Control/Trace/Quality/Supervise/System/...）
        ├── common/            # config（CORS/拦截器/Knife4j）、exception、security（JWT/CurrentUser）
        └── resource/          # ResourceService（通用 CRUD）、SchemaService、ResourceCollections、DataSeeder
```

---

## 4. 必须遵守的约定

### 4.1 数据只有一个来源：后端接口

- **禁止**新增 mock、`db.json`、本地假数据或「接口失败静默回退假数据」。`src/api/http.ts` 的原则是失败即抛 `ApiError`，由调用方显式处理。
- 页面从 `@/api/store` 读数据；store 里只有**空容器**，`loadAllData()` 从后端拉取后**就地填充**。
- 加载失败 → `backend.status = 'error'` → `App.vue` 渲染 `BackendGate` 拦住所有业务页。不要为了「看起来有数据」绕过准入层。

### 4.2 引用稳定性

`store.ts` 导出的 `reactive([])` / `reactive({})` 被页面直接 import，**不能整体重新赋值**（会断掉引用）。新增集合时必须：

1. 在 store 声明空容器；
2. 在 `fillArray(...)` / `fillObjectIfPresent(...)` 中填充；
3. 在 `clearAll()` 中清空；
4. 在 `loadAllData()` 的 `Promise.all` 中拉取；
5. 若属于公开数据，同步加进 `loadPublicData()`。

### 4.3 鉴权与门禁

- 令牌存 `localStorage.agri_platform_token`；会话存 `localStorage.agri_platform_sessions`（一个以 portal 为键的 JSON 对象）。
- **JWT 的 `exp` 是毫秒时间戳**（`JwtService` 手写 HS256，前端 `isTokenValid` 用 `Date.now()` 比对）。**不要替换成标准 JWT 库**——标准库 `exp` 为秒，会让前端判断立刻失效。
- `hasSession` = 有 token **且** 有 session；`useAuth` 模块加载时会清理「过期令牌 / 无 token 残留 session」两类脏数据，这段逻辑不要删。
- 路由守卫：找到 `meta.requiresAuth === true` 的记录，未登录则跳 `loginPaths[portal]`。**新增受保护路由必须同时带 `requiresAuth` 与 `portal`**。
- 公开接口白名单必须前后端同步：后端 `AuthInterceptor.PUBLIC`；前端对应路由不设 `requiresAuth`，且只调用公开接口。

### 4.4 多门户

`Portal = 'admin' | 'ops' | 'sup' | 'app'`。新增/调整门户要同步改动 6 处：

1. `composables/useAuth.ts` → `Portal` 类型、`portalNames`
2. `router/index.ts` → `loginPaths` + 门户路由块（`props: { portal, menu }`）
3. `components/ui/PortalLogin.vue` → `portalPath` 与 `otherPortals` 文案
4. `config/menus.ts` → 菜单分组
5. `pages/PortalsPage.vue` → 门户卡片
6. 后端 `AuthService.PORTAL_NAMES`（登录日志的模块名）

### 4.5 样式与主题

- 设计系统唯一来源：`src/assets/theme.css`（`:root` 与 `[data-theme="dark"]` 的 CSS 变量）。`main.css` 只做 `@import`。
- 页面样式优先用变量：`--primary`、`--text-primary`、`--bg-card`、`--border-card`、`--radius-card`…；**不要硬编码文本色/背景色**（大屏等特殊场景除外）。
- AntD 的局部覆盖写在 `assets/antd-overrides.css`，不要塞进 SFC 的 `<style>`（IDE 会误报）。
- AntD 组件在 `main.ts` **按需显式注册**：新用 `Tooltip`/`Select`/`Table` 等必须同步 `import` + `.use()`，否则运行时「组件未注册」。

### 4.6 组件选型

- 表格、分页、弹窗、图表、GIS 一律使用 `src/components/ui/*` 自有组件，**不要引入 ECharts / Element Plus / 其他 UI 库**。
- 全局提示统一 `useToast()`（它拿的是 `<a-app>` 内跟随主题的 message 实例），不要直接调 antd 静态 `message`。

### 4.7 GIS 地图（Leaflet）

地图已从 SVG 示意图换成真实 Leaflet（高德瓦片），组件 `src/components/ui/GisMap.vue` 是**唯一**的地图入口。

- 坐标：`MapPoint` 以 `lng` / `lat`（WGS84）为准；`x` / `y` 是历史 1000×600 虚拟画布坐标，由 `utils/geo.ts` 与经纬度互算。老数据（只有 `x`/`y`）无需迁移即可落到真实底图，**不要**再写死 `x/y` 画 SVG。
- 面积/周长统一走 `utils/geo.ts`（球面公式），不要再手写像素比或引入 turf。
- 绘制：`drawable` → 用户圈画 → `@draw-complete` 返回 `{ polygon, area, areaMu, perimeter, geojson }`；绘制结果通过 `pending` prop 回显为蓝色虚线，避免"画完就消失"。
- 编辑：`editable` + `selectedId` 可直接拖拽顶点，`@edit-complete` 同样返回边界数据。
- 框选：`box-select` 或 `defineExpose` 的 `toggleBoxSelect()`；`@select-area` 同时给出真实 `bounds` 与兼容旧代码的画布矩形。
- 底图三种：`vector` / `satellite` / `blank`，`dark` 对瓦片做反相滤镜；Leaflet 运行时生成的 DOM 样式写在 `assets/leaflet-overrides.css`，**不要**塞进 SFC 的 scoped 样式。
- 地块写操作已接后端（`POST/PATCH/DELETE /farm/plots`），失败必须 `toast.error`，不要静默回退。

---

## 5. 常见改造路径

### 5.1 新增一个业务页面

1. 在 `src/pages/<域>/XxxPage.vue` 新建，`<script setup lang="ts">`，顶部用 `PageHeader`。
2. `src/router/index.ts` 在对应门户 `children` 中加一条（必带 `meta.title`）。
3. `src/config/menus.ts` 加菜单项（`label` / `to` / `icon`，icon 用单个汉字）。
4. 数据取 `@/api/store`；新集合按 5.2 扩展。
5. `npm run type-check` 通过后再交付。

### 5.2 新增一个后端资源 / 接口

**后端**

1. `ResourceCollections` 加常量（集合名 = 物理表名）；
2. `sql/agri_platform.sql` 加表（表名与集合名完全一致）；
3. 在对应域 Controller 加 `@GetMapping` → `resourceService.list/get/getSingleton`；需要写就补 `@PostMapping/@PatchMapping/@DeleteMapping`；
4. 如属公开数据，加入 `AuthInterceptor.PUBLIC`；
5. 方法加 `@Operation(summary=...)`，域上加 `@Tag`。

**前端**

1. `src/data/types.ts` 加类型；
2. `src/api/endpoints.ts` 加 `fetchXxx`；
3. `src/api/store.ts` 加容器 + 在 `loadAllData()` 填充（单例用 `fillObjectIfPresent`）；
4. 页面消费。

### 5.3 把某个页面的写操作真正落库

现状：多数页面的「保存/确认/归档」只改内存 + `toast.success`（如 `AlarmHandlePage`、各端 `ProfilePage` 的资料保存）。只有「修改密码」真正请求后端。

接入写接口的推荐写法：

```ts
import { updateResource, createResource, ENDPOINTS } from '@/api/endpoints'
import { ApiError } from '@/api/http'

try {
  await updateResource(ENDPOINTS.alarms, row.id, { status: '处置中', handler: name })
  toast.success('已提交')
} catch (error) {
  toast.error(error instanceof ApiError ? error.message : '提交失败，请稍后重试')
}
```

要求：不要静默吞错；成功后要么就地更新 store，要么重新拉取该集合。

---

## 6. 后端约定

- **`collection` = 物理表名**，页面集合名与表名严格一一对应（camelCase，如 `workOrders`、`supWarnings`）。
- `ResourceService` 语义（刻意与 json-server 对齐）：
  - `list`：`SELECT * ORDER BY id`，返回数组；
  - `get`：按 `id` 查，缺失抛 404；
  - `getSingleton`：取首行并**移除自增 `id`**，无数据返回 `null`（HTTP 200 + 空体，前端得到 `undefined`）；
  - `create`：忽略未知列；无可用字段 → 400；
  - `update(merge=true)`：PATCH 浅合并，主键不改；影响 0 行 → 404；
  - `delete`：影响 0 行 → 404。
- 单例集合见 `ResourceCollections.SINGLETONS`（`park`、`weather`、`envSeries`、`waterElectric`、`traceDetail`、`qualityOverview`、`sysInfo`、`screenConfig`、`irrigationSummary`），返回**对象**，别按数组处理。
- 类型转换由 `SchemaService`（读 `information_schema` 并缓存）驱动：JSON 列 ↔ 对象/数组、`TINYINT(1)` ↔ boolean、`DATE`/`DATETIME` → 字符串（`yyyy-MM-dd` / `yyyy-MM-dd HH:mm:ss`）、`DECIMAL` → double。
- 异常统一由 `GlobalExceptionHandler` 返回 `{"error": "..."}`；前端 `http.ts` 会优先透传 `error`。
- **SQL 安全**：表名、列名是字符串拼接的，`collection` 只能来自 `ResourceCollections` 常量或控制器里写死的字面量，**绝不能**来自请求参数。
- 表结构由 `sql/` 脚本管理，`ddl-auto: none`，Hibernate 不建表也不改表。

---

## 7. 数据库

- MySQL 8.0+，库 `agri_platform`，`utf8mb4` / `utf8mb4_unicode_ci`，48 张表。
- `accounts` 表由 JPA `Account` 实体管理（业务主键 `id`，如 `A-001`）；其余 47 张由 `JdbcTemplate` 通用读写。
- 密码字段存 BCrypt；`seed/db.json` 中是明文种子，`DataSeeder` 导入时加密。
- 新加字段顺序：`sql/agri_platform.sql` → 前端 `types.ts`。`SchemaService` 有列元数据缓存，**改表结构后需重启后端**。
- 单例表用自增 `id` 作主键，业务集合用业务 `id`（VARCHAR）。

---

## 8. 已知问题与陷阱（都真实踩过）

1. **不要删 Vite 代理**。删掉后 `/api/v1/*` 会落到 dev server 自身、返回 `index.html` + HTTP 200，`http.ts` 解析 JSON 失败，全站卡在 `BackendGate`。`vite.config.ts` 的 `server.proxy['/api']` 是联通前提。
2. **`DataSeeder` 以「`accounts` 非空」整体跳过**。只在新建空库时正常；若只清空业务表，业务数据不会补种。此时用 `sql/agri_platform_data.sql`（259 条）。
3. **中文 SQL 导入必须带 `--default-character-set=utf8mb4`**，否则首条 insert 即 `Data too long for column`。
4. **登录态脏数据**：无 token 但有 session 会被误判为已登录 → 受保护接口 401 风暴 → 连公开页都被 `BackendGate` 挡住。`useAuth` 顶部的清理逻辑即为修复，不要移除。
5. **`application.yaml` 目前写死 `username: root` / `password: password`**，只有 `DB_URL` 走环境变量。换机/改密码时要么改这里，要么先改成 `${DB_USERNAME:root}` 形式。
6. **未使用文件**：`src/layouts/BasicLayout.vue`（及其引用的 `GlobalHeader.vue`、`GlobalFooter.vue`）、`src/pages/HomePage.vue`（根目录那个，不是 `pages/home/HomePage.vue`）。清理前先全局确认引用。
7. **页面里仍有演示性质的本地交互**：如 `EnvMonitorPage` 的 `jitter()` 随机刷新、部分页面的「保存」只弹 toast。改这些页面时不要误以为数据来自后端。
8. **没有 ESLint / Prettier 配置**，唯一自动门禁是 `vue-tsc`。写完务必跑 `npm run type-check`。
9. 前端同时存在 `pages/control/DeviceControlPage.vue` 与 `pages/device/DeviceControlPage.vue`（PC 端 / 移动端），`pages/public/LoginPage.vue` 与 `pages/login/LoginPage.vue`（PC / 移动）——改错文件不会有报错，只会「没生效」。

---

## 9. 完工检查清单

- [ ] `npm run type-check` 通过（交付前再跑一次 `npm run build`）
- [ ] 后端 `./mvnw -DskipTests compile` 通过
- [ ] 后端在 3001 启动，前端登录后可进入对应门户且数据非空
- [ ] 未登录访问 `/portals`、`/trace/h5/:code`、`/login` 正常；未登录访问 `/screen` 会跳登录
- [ ] 明暗主题切换后新页面文字/背景仍可读
- [ ] 新增 AntD 组件已写入 `main.ts`
- [ ] 新增接口已同步 `endpoints.ts` + `store.ts` + `loadAllData()`
- [ ] 提交信息用中文短句（与仓库现有风格一致）

---

## 10. 红线

- 不删除 `.workbuddy/`（项目记忆与工作日志）。
- 不把令牌、数据库密码、`AUTH_SECRET` 等密钥写入代码或提交。
- 不恢复 mock 后端，不引入第二套数据源。
- 不改「集合名 ↔ 表名」的对应关系（前后端靠它耦合）。
- 不把用户输入拼进 SQL 标识符。
- 不擅自替换鉴权实现（毫秒 `exp` 是前后端契约）。
