import { createRouter, createWebHistory } from 'vue-router'
import type { RouteRecordRaw } from 'vue-router'
import PortalLayout from '@/layouts/PortalLayout.vue'
import MobileLayout from '@/layouts/MobileLayout.vue'
import { adminMenu, opsMenu, supMenu } from '@/config/menus'
import { useAuth, type Portal } from '@/composables/useAuth'

const routes: RouteRecordRaw[] = [
  { path: '/', redirect: '/portals' },
  {
    path: '/portals',
    name: 'portals',
    component: () => import('@/pages/PortalsPage.vue'),
    meta: { title: '业务端总览' },
  },
  {
    path: '/login',
    name: 'admin-login',
    component: () => import('@/pages/public/LoginPage.vue'),
    meta: { title: '管理员登录' },
  },
  {
    path: '/ops/login',
    name: 'ops-login',
    component: () => import('@/pages/ops/OpsLoginPage.vue'),
    meta: { title: '运维登录' },
  },
  {
    path: '/sup/login',
    name: 'sup-login',
    component: () => import('@/pages/supervise/SupLoginPage.vue'),
    meta: { title: '监管端登录' },
  },
  {
    path: '/app/login',
    name: 'app-login',
    component: () => import('@/pages/login/LoginPage.vue'),
    meta: { title: '农户移动端登录' },
  },
  {
    path: '/screen',
    name: 'command-screen',
    component: () => import('@/pages/screen/CommandScreenPage.vue'),
    meta: { title: '指挥中心大屏', requiresAuth: true, portal: 'admin' },
  },
  {
    path: '/trace/h5/:code',
    name: 'trace-h5',
    component: () => import('@/pages/trace/TraceH5Page.vue'),
    meta: { title: '农产品溯源查询' },
  },
  {
    path: '/trace/h5/invalid',
    name: 'trace-invalid',
    component: () => import('@/pages/trace/TraceInvalidPage.vue'),
    meta: { title: '溯源码失效提示' },
  },
  {
    path: '/',
    component: PortalLayout,
    props: { portal: 'admin', menu: adminMenu },
    meta: { requiresAuth: true, portal: 'admin' },
    children: [
      { path: '', redirect: '/login' },
      { path: 'dashboard', name: 'dashboard', component: () => import('@/pages/home/DashboardPage.vue'), meta: { title: '综合数据看板' } },
      { path: 'iot/env', name: 'iot-env', component: () => import('@/pages/iot/EnvMonitorPage.vue'), meta: { title: '环境数据监测' } },
      { path: 'iot/devices', name: 'iot-devices', component: () => import('@/pages/iot/DeviceStatusPage.vue'), meta: { title: '设备管理' } },
      { path: 'iot/video', name: 'iot-video', component: () => import('@/pages/iot/VideoMonitorPage.vue'), meta: { title: '视频监控' } },
      { path: 'iot/water-elec', name: 'iot-water-elec', component: () => import('@/pages/iot/WaterElecStatPage.vue'), meta: { title: '水电计量统计' } },
      { path: 'control/device', name: 'control-device', component: () => import('@/pages/control/DeviceControlPage.vue'), meta: { title: '设备远程控制' } },
      { path: 'control/irrigation', name: 'control-irrigation', component: () => import('@/pages/control/IrrigationPage.vue'), meta: { title: '智能灌溉控制' } },
      { path: 'control/linkage', name: 'control-linkage', component: () => import('@/pages/control/LinkageStrategyPage.vue'), meta: { title: '自动联动策略' } },
      { path: 'farm/plots', name: 'farm-plots', component: () => import('@/pages/farm/PlotProfilePage.vue'), meta: { title: 'GIS 地块管理' } },
      { path: 'farm/plot-audit', name: 'farm-plot-audit', component: () => import('@/pages/farm/PlotAuditPage.vue'), meta: { title: '地块档案审核' } },
      { path: 'farm/work-orders', name: 'farm-work-orders', component: () => import('@/pages/farm/WorkOrderListPage.vue'), meta: { title: '农事工单列表' } },
      { path: 'farm/work-orders/:id', name: 'farm-work-order-detail', component: () => import('@/pages/farm/WorkOrderDetailPage.vue'), meta: { title: '农事工单详情' } },
      { path: 'farm/materials', name: 'farm-materials', component: () => import('@/pages/farm/MaterialStockPage.vue'), meta: { title: '农资库存管理' } },
      { path: 'farm/harvest', name: 'farm-harvest', component: () => import('@/pages/farm/HarvestRegisterPage.vue'), meta: { title: '采收登记' } },
      { path: 'trace/batches', name: 'trace-batches', component: () => import('@/pages/trace/BatchListPage.vue'), meta: { title: '溯源批次档案' } },
      { path: 'trace/qrcode', name: 'trace-qrcode', component: () => import('@/pages/trace/QrcodeGeneratePage.vue'), meta: { title: '溯源码生成' } },
      { path: 'trace/inspections', name: 'trace-inspections', component: () => import('@/pages/trace/InspectReportPage.vue'), meta: { title: '检测报告管理' } },
      { path: 'trace/recalls', name: 'trace-recalls', component: () => import('@/pages/trace/RecallRegisterPage.vue'), meta: { title: '产品召回登记' } },
      { path: 'gis', name: 'gis', component: () => import('@/pages/gis/GisMapOverviewPage.vue'), meta: { title: 'GIS 综合地图', flush: true } },
      { path: 'alarms', name: 'alarms', component: () => import('@/pages/alarm/AlarmHandlePage.vue'), meta: { title: '告警信息处理' } },
      { path: 'reports', name: 'reports', component: () => import('@/pages/report/ReportExportPage.vue'), meta: { title: '综合报表导出' } },
      { path: 'screen/config', name: 'screen-config', component: () => import('@/pages/screen/ScreenConfigPage.vue'), meta: { title: '大屏展示配置' } },
      { path: 'profile', name: 'profile', component: () => import('@/pages/admin/ProfilePage.vue'), meta: { title: '个人信息修改' } },
    ],
  },
  {
    path: '/ops',
    component: PortalLayout,
    props: { portal: 'ops', menu: opsMenu },
    meta: { requiresAuth: true, portal: 'ops' },
    children: [
      { path: '', redirect: '/ops/workbench' },
      { path: 'workbench', name: 'ops-workbench', component: () => import('@/pages/ops/OpsWorkbenchPage.vue'), meta: { title: '运维工作台' } },
      { path: 'tenants', name: 'ops-tenants', component: () => import('@/pages/ops/TenantManagePage.vue'), meta: { title: '租户信息管理' } },
      { path: 'users', name: 'ops-users', component: () => import('@/pages/ops/UserManagePage.vue'), meta: { title: '系统用户管理' } },
      { path: 'roles', name: 'ops-roles', component: () => import('@/pages/ops/RolePermissionPage.vue'), meta: { title: 'RBAC 角色权限配置' } },
      { path: 'devices', name: 'ops-devices', component: () => import('@/pages/ops/DeviceAccessPage.vue'), meta: { title: '设备接入管理' } },
      { path: 'dict', name: 'ops-dict', component: () => import('@/pages/ops/DataDictPage.vue'), meta: { title: '系统数据字典' } },
      { path: 'openapi', name: 'ops-openapi', component: () => import('@/pages/ops/OpenApiConfigPage.vue'), meta: { title: '第三方接口管理' } },
      { path: 'files', name: 'ops-files', component: () => import('@/pages/ops/FileStoragePage.vue'), meta: { title: '文件存储管理' } },
      { path: 'logs/login', name: 'ops-login-logs', component: () => import('@/pages/ops/LoginLogPage.vue'), meta: { title: '登录日志' } },
      { path: 'logs/operation', name: 'ops-operation-logs', component: () => import('@/pages/ops/OperationLogPage.vue'), meta: { title: '操作审计日志' } },
      { path: 'backup', name: 'ops-backup', component: () => import('@/pages/ops/DbBackupPage.vue'), meta: { title: '数据库备份恢复' } },
      { path: 'profile', name: 'ops-profile', component: () => import('@/pages/ops/OpsProfilePage.vue'), meta: { title: '运维个人设置' } },
    ],
  },
  {
    path: '/sup',
    component: PortalLayout,
    props: { portal: 'sup', menu: supMenu },
    meta: { requiresAuth: true, portal: 'sup' },
    children: [
      { path: '', redirect: '/sup/overview' },
      { path: 'overview', name: 'sup-overview', component: () => import('@/pages/supervise/SupOverviewPage.vue'), meta: { title: '监管数据总览' } },
      { path: 'quality', name: 'sup-quality', component: () => import('@/pages/supervise/QualityOverviewPage.vue'), meta: { title: '辖区质量安全总览' } },
      { path: 'trace', name: 'sup-trace', component: () => import('@/pages/supervise/TraceQueryPage.vue'), meta: { title: '农产品溯源查询' } },
      { path: 'pesticide', name: 'sup-pesticide', component: () => import('@/pages/supervise/PesticideLedgerPage.vue'), meta: { title: '农药农资使用记录' } },
      { path: 'warnings', name: 'sup-warnings', component: () => import('@/pages/supervise/WarningListPage.vue'), meta: { title: '监管预警管理' } },
      { path: 'reports', name: 'sup-reports', component: () => import('@/pages/supervise/SupReportPage.vue'), meta: { title: '监管报表导出' } },
      { path: 'profile', name: 'sup-profile', component: () => import('@/pages/supervise/SupProfilePage.vue'), meta: { title: '监管账号设置' } },
    ],
  },
  {
    path: '/app',
    component: MobileLayout,
    meta: { requiresAuth: true, portal: 'app' },
    children: [
      { path: '', redirect: '/app/home' },
      { path: 'home', name: 'app-home', component: () => import('@/pages/home/HomePage.vue'), meta: { title: '农户工作台' } },
      { path: 'tasks', name: 'app-tasks', component: () => import('@/pages/task/TaskListPage.vue'), meta: { title: '农事任务列表' } },
      { path: 'tasks/:id', name: 'app-task-detail', component: () => import('@/pages/task/TaskDetailPage.vue'), meta: { title: '农事任务详情' } },
      { path: 'messages', name: 'app-messages', component: () => import('@/pages/message/AlarmMessagePage.vue'), meta: { title: '告警消息' } },
      { path: 'env', name: 'app-env', component: () => import('@/pages/env/EnvDataPage.vue'), meta: { title: '环境数据查看' } },
      { path: 'devices', name: 'app-devices', component: () => import('@/pages/device/DeviceControlPage.vue'), meta: { title: '移动端设备控制' } },
      { path: 'trace-scan', name: 'app-trace-scan', component: () => import('@/pages/trace/TraceScanPage.vue'), meta: { title: '扫码溯源录入' } },
      { path: 'plots', name: 'app-plots', component: () => import('@/pages/mine/MyPlotsPage.vue'), meta: { title: '我的地块' } },
      { path: 'plots/submit', name: 'app-plot-submit', component: () => import('@/pages/mine/PlotSubmitPage.vue'), meta: { title: '地块录入' } },
      { path: 'plots/submit/:id', name: 'app-plot-resubmit', component: () => import('@/pages/mine/PlotSubmitPage.vue'), meta: { title: '地块重新提交' } },
      { path: 'mine', name: 'app-mine', component: () => import('@/pages/mine/MinePage.vue'), meta: { title: '个人中心' } },
    ],
  },
  { path: '/error', name: 'error', component: () => import('@/pages/error/StatusPage.vue'), meta: { title: '状态提示' } },
  { path: '/:pathMatch(.*)*', name: 'not-found', component: () => import('@/pages/error/StatusPage.vue'), meta: { title: '页面不存在' } },
]

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
})

const loginPaths: Record<Portal, string> = {
  admin: '/login',
  ops: '/ops/login',
  sup: '/sup/login',
  app: '/app/login',
}

/** 登录门禁：受保护路由未登录时，一律重定向到对应业务端的登录页 */
router.beforeEach((to) => {
  const guard = to.matched.find((record) => record.meta.requiresAuth === true)
  if (!guard) return true
  const portal = guard.meta.portal as Portal
  if (useAuth().isLoggedIn(portal).value) return true
  return { path: loginPaths[portal], query: { redirect: to.fullPath } }
})

router.afterEach((to) => {
  const title = typeof to.meta.title === 'string' ? to.meta.title : '智慧农业综合管理平台'
  document.title = `${title} · 智慧农业综合管理平台`
})

export default router
