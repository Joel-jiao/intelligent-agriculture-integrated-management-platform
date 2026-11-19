/**
 * 后端接口清单
 *
 * 路径与 src/route/routes.json 中的映射一一对应（真实后端风格地址），
 * 更换真实后端时只需要调整 routes.json / 本文件，页面无需改动。
 */
import { apiDelete, apiGet, apiPatch, apiPost } from './http'
import type {
  Alarm,
  BackupRecord,
  Camera,
  Device,
  DictType,
  EnvSeries,
  FarmerPlot,
  FileRecord,
  HarvestRecord,
  InspectReport,
  LogRecord,
  Material,
  MessageItem,
  MonthlyReportRow,
  OpenApi,
  ParkInfo,
  PesticideLedgerRow,
  Plot,
  PlotAudit,
  QualityOverview,
  RecallRecord,
  Role,
  ScreenConfig,
  SupWarning,
  SysInfo,
  SysUser,
  Tenant,
  TraceBatch,
  TraceDetail,
  TraceTimelineItem,
  WaterElectric,
  WeatherInfo,
  WorkOrder,
} from '@/data/types'

/** 集合型资源：列表接口地址 */
export const ENDPOINTS = {
  plots: '/farm/plots',
  harvests: '/farm/harvests',
  materials: '/farm/materials',
  workOrders: '/farm/work-orders',
  plotAudits: '/farm/plot-audits',
  farmerPlots: '/farmer/my-plots',
  devices: '/iot/devices',
  cameras: '/iot/cameras',
  alarms: '/alarm/records',
  messages: '/message/messages',
  batches: '/trace/batches',
  inspections: '/trace/inspections',
  recalls: '/trace/recalls',
  supWarnings: '/supervise/warnings',
  users: '/system/users',
  roles: '/system/roles',
  loginLogs: '/system/login-logs',
  operationLogs: '/system/operation-logs',
  backups: '/system/backups',
  openApis: '/system/open-apis',
  files: '/system/files',
  tenants: '/system/tenants',
  dictTypes: '/system/dicts',
  pesticideLedger: '/quality/pesticide-ledger',
  monthlyReport: '/report/monthly',
} as const

/** 单对象 / 聚合型资源：只读接口地址 */
export const AGGREGATE_ENDPOINTS = {
  park: '/park/overview',
  weather: '/weather/current',
  envSeries: '/iot/env-series',
  waterElectric: '/energy/water-electric',
  traceTimeline: '/trace/timeline',
  traceDetail: '/trace/detail',
  qualityOverview: '/quality/overview',
  sysInfo: '/system/info',
  screenConfig: '/screen/config',
} as const

/* ---------------- 集合型资源：读取 ---------------- */

export const fetchPlots = () => apiGet<Plot[]>(ENDPOINTS.plots)
export const fetchHarvests = () => apiGet<HarvestRecord[]>(ENDPOINTS.harvests)
export const fetchMaterials = () => apiGet<Material[]>(ENDPOINTS.materials)
export const fetchWorkOrders = () => apiGet<WorkOrder[]>(ENDPOINTS.workOrders)
export const fetchPlotAudits = () => apiGet<PlotAudit[]>(ENDPOINTS.plotAudits)
export const fetchFarmerPlots = () => apiGet<FarmerPlot[]>(ENDPOINTS.farmerPlots)
export const fetchDevices = () => apiGet<Device[]>(ENDPOINTS.devices)
export const fetchCameras = () => apiGet<Camera[]>(ENDPOINTS.cameras)
export const fetchAlarms = () => apiGet<Alarm[]>(ENDPOINTS.alarms)
export const fetchMessages = () => apiGet<MessageItem[]>(ENDPOINTS.messages)
export const fetchBatches = () => apiGet<TraceBatch[]>(ENDPOINTS.batches)
export const fetchInspections = () => apiGet<InspectReport[]>(ENDPOINTS.inspections)
export const fetchRecalls = () => apiGet<RecallRecord[]>(ENDPOINTS.recalls)
export const fetchSupWarnings = () => apiGet<SupWarning[]>(ENDPOINTS.supWarnings)
export const fetchUsers = () => apiGet<SysUser[]>(ENDPOINTS.users)
export const fetchRoles = () => apiGet<Role[]>(ENDPOINTS.roles)
export const fetchLoginLogs = () => apiGet<LogRecord[]>(ENDPOINTS.loginLogs)
export const fetchOperationLogs = () => apiGet<LogRecord[]>(ENDPOINTS.operationLogs)
export const fetchBackups = () => apiGet<BackupRecord[]>(ENDPOINTS.backups)
export const fetchOpenApis = () => apiGet<OpenApi[]>(ENDPOINTS.openApis)
export const fetchFiles = () => apiGet<FileRecord[]>(ENDPOINTS.files)
export const fetchTenants = () => apiGet<Tenant[]>(ENDPOINTS.tenants)
export const fetchDictTypes = () => apiGet<DictType[]>(ENDPOINTS.dictTypes)
export const fetchPesticideLedger = () => apiGet<PesticideLedgerRow[]>(ENDPOINTS.pesticideLedger)
export const fetchMonthlyReport = () => apiGet<MonthlyReportRow[]>(ENDPOINTS.monthlyReport)

/* ---------------- 单对象 / 聚合型资源 ---------------- */

export const fetchPark = () => apiGet<ParkInfo>(AGGREGATE_ENDPOINTS.park)
export const fetchWeather = () => apiGet<WeatherInfo>(AGGREGATE_ENDPOINTS.weather)
export const fetchEnvSeries = () => apiGet<EnvSeries>(AGGREGATE_ENDPOINTS.envSeries)
export const fetchWaterElectric = () => apiGet<WaterElectric>(AGGREGATE_ENDPOINTS.waterElectric)
export const fetchQualityOverview = () => apiGet<QualityOverview>(AGGREGATE_ENDPOINTS.qualityOverview)
export const fetchSysInfo = () => apiGet<SysInfo>(AGGREGATE_ENDPOINTS.sysInfo)
export const fetchScreenConfig = () => apiGet<ScreenConfig>(AGGREGATE_ENDPOINTS.screenConfig)

/** 指定批次的溯源时间线（无参数时取默认批次） */
export const fetchTraceTimeline = (batchNo?: string) =>
  apiGet<TraceTimelineItem[]>(
    batchNo ? `/trace/${encodeURIComponent(batchNo)}/timeline` : AGGREGATE_ENDPOINTS.traceTimeline,
  )

/** 指定批次的溯源详情（无参数时取默认批次） */
export const fetchTraceDetail = (batchNo?: string) =>
  apiGet<TraceDetail>(
    batchNo ? `/trace/${encodeURIComponent(batchNo)}/detail` : AGGREGATE_ENDPOINTS.traceDetail,
  )

/* ---------------- 页面级明细记录 ---------------- */

/**
 * 各业务面板的明细数据（联动策略、控制日志、打卡、导出记录等）。
 * 结构由对应页面声明，这里只负责按地址取回。
 */
export const DETAIL_ENDPOINTS = {
  loginDevices: '/system/login-devices',
  controlLogs: '/control/logs',
  irrigationPlots: '/control/irrigation-plots',
  irrigationSummary: '/control/irrigation-summary',
  linkageStrategies: '/control/linkage-strategies',
  linkageLogs: '/control/linkage-logs',
  deviceOpRecords: '/iot/op-records',
  workOrderCheckins: '/farm/work-order-checkins',
  opApiKeys: '/system/api-keys',
  opSessions: '/system/sessions',
  serviceHealth: '/system/services',
  exportRecords: '/report/exports',
  videoReplays: '/iot/video-replays',
} as const

export const fetchDetailRows = (path: string) => apiGet<unknown[]>(path)

/** 灌溉今日统计 */
export const fetchIrrigationSummary = () =>
  apiGet<{ todayWater: number; todayArea: number; savingRate: number }>(
    DETAIL_ENDPOINTS.irrigationSummary,
  )

/* ---------------- 写操作（按需扩展） ---------------- */

export function createResource<T>(path: string, payload: unknown) {
  return apiPost<T>(path, payload)
}

/** 修改当前登录账号的密码（需携带登录令牌，校验原密码后更新后端） */
export const changePassword = (oldPassword: string, newPassword: string) =>
  apiPost<{ ok: boolean }>('/auth/change-password', { oldPassword, newPassword })

export function updateResource<T>(path: string, id: string, payload: unknown) {
  return apiPatch<T>(`${path}/${encodeURIComponent(id)}`, payload)
}

export function deleteResource(path: string, id: string) {
  return apiDelete<void>(`${path}/${encodeURIComponent(id)}`)
}
