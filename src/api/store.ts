/**
 * 业务数据仓库
 *
 * 唯一数据来源：后端接口（src/api/endpoints.ts）。这里不保存任何业务数据，
 * 只有空容器；应用启动时由 loadAllData() 从后端拉取并「就地填充」，
 * 从而保持导出引用的稳定性，页面可以直接 import 使用。
 *
 * 后端不可用时：容器保持为空，状态置为 error，由 App.vue 的准入层
 * 拦住所有页面，避免在无后端的情况下展示数据。
 */
import { reactive } from 'vue'
import {
  DETAIL_ENDPOINTS,
  fetchAlarms,
  fetchBackups,
  fetchBatches,
  fetchCameras,
  fetchDetailRows,
  fetchDictTypes,
  fetchDevices,
  fetchEnvSeries,
  fetchFarmerPlots,
  fetchFiles,
  fetchHarvests,
  fetchInspections,
  fetchIrrigationSummary,
  fetchLoginLogs,
  fetchMaterials,
  fetchMessages,
  fetchMonthlyReport,
  fetchOpenApis,
  fetchOperationLogs,
  fetchPark,
  fetchPesticideLedger,
  fetchPlotAudits,
  fetchPlots,
  fetchQualityOverview,
  fetchRecalls,
  fetchRoles,
  fetchScreenConfig,
  fetchSupWarnings,
  fetchSysInfo,
  fetchTenants,
  fetchTraceDetail,
  fetchTraceTimeline,
  fetchUsers,
  fetchWaterElectric,
  fetchWeather,
  fetchWorkOrders,
} from './endpoints'
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

export type BackendStatus = 'idle' | 'loading' | 'ready' | 'error'

/** 后端连通状态，供准入层与页面展示使用 */
export const backend = reactive<{
  status: BackendStatus
  error: string
  loadedAt: number
  attempts: number
}>({
  status: 'idle',
  error: '',
  loadedAt: 0,
  attempts: 0,
})

/* ------------------------------------------------------------------ *
 * 数据容器：引用稳定，加载后就地填充
 * ------------------------------------------------------------------ */

export const park = reactive<ParkInfo>({
  name: '',
  shortName: '',
  location: '',
  area: 0,
  plots: 0,
  farmers: 0,
  manager: '',
})

export const weather = reactive<WeatherInfo>({
  temperature: 0,
  humidity: 0,
  condition: '',
  wind: '',
  rainfall: 0,
  forecast: [],
})

export const sysInfo = reactive<SysInfo>({
  version: '',
  env: '',
  db: '',
  api: '',
  uptime: '',
  cpu: 0,
  memory: 0,
  disk: 0,
  onlineUsers: 0,
  mqttMessages: 0,
  apiCalls: 0,
})

export const qualityOverview = reactive<QualityOverview>({
  passRate: 0,
  inspectedBatches: 0,
  qualified: 0,
  unqualified: 0,
  recalls: 0,
  pesticideChecks: 0,
  trend: [],
  categories: [],
})

export const traceDetail = reactive<TraceDetail>({
  batchNo: '',
  crop: '',
  variety: '',
  origin: '',
  grade: '',
  weight: '',
  harvestedAt: '',
  farmer: '',
  plot: '',
  scans: 0,
  inspect: {
    reportNo: '',
    agency: '',
    testedAt: '',
    pesticide: '',
    heavyMetal: '',
    conclusion: '',
  },
})

export const screenConfig = reactive<ScreenConfig>({
  sections: [],
  interval: 0,
  theme: '',
  resolution: '',
  defaultScope: '',
})

export const envSeries = reactive<EnvSeries>({
  labels: [],
  temperature: [],
  humidity: [],
  soilTemperature: [],
  soilMoisture: [],
  co2: [],
  light: [],
  ph: [],
  waterTemperature: [],
})

export const waterElectric = reactive<WaterElectric>({
  months: [],
  water: [],
  electric: [],
})

/** 环境曲线时间轴（由 envSeries.labels 同步，独立导出以兼容页面用法） */
export const envLabels: string[] = reactive<string[]>([])

export const plots: Plot[] = reactive<Plot[]>([])
export const cameras: Camera[] = reactive<Camera[]>([])
export const devices: Device[] = reactive<Device[]>([])
export const alarms: Alarm[] = reactive<Alarm[]>([])
export const workOrders: WorkOrder[] = reactive<WorkOrder[]>([])
export const materials: Material[] = reactive<Material[]>([])
export const harvests: HarvestRecord[] = reactive<HarvestRecord[]>([])
export const batches: TraceBatch[] = reactive<TraceBatch[]>([])
export const inspections: InspectReport[] = reactive<InspectReport[]>([])
export const recalls: RecallRecord[] = reactive<RecallRecord[]>([])
export const users: SysUser[] = reactive<SysUser[]>([])
export const roles: Role[] = reactive<Role[]>([])
export const loginLogs: LogRecord[] = reactive<LogRecord[]>([])
export const operationLogs: LogRecord[] = reactive<LogRecord[]>([])
export const backups: BackupRecord[] = reactive<BackupRecord[]>([])
export const openApis: OpenApi[] = reactive<OpenApi[]>([])
export const files: FileRecord[] = reactive<FileRecord[]>([])
export const supWarnings: SupWarning[] = reactive<SupWarning[]>([])
export const messages: MessageItem[] = reactive<MessageItem[]>([])
export const monthlyReport: MonthlyReportRow[] = reactive<MonthlyReportRow[]>([])
export const traceTimeline: TraceTimelineItem[] = reactive<TraceTimelineItem[]>([])
export const pesticideLedger: PesticideLedgerRow[] = reactive<PesticideLedgerRow[]>([])
export const tenants: Tenant[] = reactive<Tenant[]>([])
export const plotAudits: PlotAudit[] = reactive<PlotAudit[]>([])
export const farmerPlots: FarmerPlot[] = reactive<FarmerPlot[]>([])
export const dictTypes: DictType[] = reactive<DictType[]>([])

/* ---------- 页面级明细记录：结构由使用页面声明，数据同样只来自后端 ---------- */

export const loginDevices = reactive<unknown[]>([])
export const controlLogs = reactive<unknown[]>([])
export const linkageStrategies = reactive<unknown[]>([])
export const linkageLogs = reactive<unknown[]>([])
export const deviceOpRecords = reactive<unknown[]>([])
export const workOrderCheckins = reactive<unknown[]>([])
export const opApiKeys = reactive<unknown[]>([])
export const opSessions = reactive<unknown[]>([])
export const serviceHealth = reactive<unknown[]>([])
export const exportRecords = reactive<unknown[]>([])
export const videoReplays = reactive<unknown[]>([])
export const irrigationPlots = reactive<unknown[]>([])

export const irrigationSummary = reactive<{
  todayWater: number
  todayArea: number
  savingRate: number
}>({ todayWater: 0, todayArea: 0, savingRate: 0 })

/** 把后端返回的明细行复制成页面可自由编辑的副本（页面自行声明行类型） */
export function cloneRows<T>(rows: unknown): T[] {
  return JSON.parse(JSON.stringify(rows ?? [])) as T[]
}

const detailTargets: Array<{ target: unknown[]; path: string }> = [
  { target: loginDevices, path: DETAIL_ENDPOINTS.loginDevices },
  { target: controlLogs, path: DETAIL_ENDPOINTS.controlLogs },
  { target: linkageStrategies, path: DETAIL_ENDPOINTS.linkageStrategies },
  { target: linkageLogs, path: DETAIL_ENDPOINTS.linkageLogs },
  { target: deviceOpRecords, path: DETAIL_ENDPOINTS.deviceOpRecords },
  { target: workOrderCheckins, path: DETAIL_ENDPOINTS.workOrderCheckins },
  { target: opApiKeys, path: DETAIL_ENDPOINTS.opApiKeys },
  { target: opSessions, path: DETAIL_ENDPOINTS.opSessions },
  { target: serviceHealth, path: DETAIL_ENDPOINTS.serviceHealth },
  { target: exportRecords, path: DETAIL_ENDPOINTS.exportRecords },
  { target: videoReplays, path: DETAIL_ENDPOINTS.videoReplays },
  { target: irrigationPlots, path: DETAIL_ENDPOINTS.irrigationPlots },
]

/* ------------------------------------------------------------------ *
 * 就地填充工具：保证已导出的引用不失效
 * ------------------------------------------------------------------ */

function fillArray<T>(target: T[], source: T[] | null | undefined) {
  target.splice(0, target.length, ...(source ?? []))
}

function fillObject<T extends object>(target: T, source: Partial<T> | null | undefined) {
  for (const key of Object.keys(target)) {
    delete (target as Record<string, unknown>)[key]
  }
  if (source) Object.assign(target, source)
}

/** 清空所有容器（后端不可用时不留任何残留数据） */
function clearAll() {
  fillArray(plots, [])
  fillArray(cameras, [])
  fillArray(devices, [])
  fillArray(alarms, [])
  fillArray(workOrders, [])
  fillArray(materials, [])
  fillArray(harvests, [])
  fillArray(batches, [])
  fillArray(inspections, [])
  fillArray(recalls, [])
  fillArray(users, [])
  fillArray(roles, [])
  fillArray(loginLogs, [])
  fillArray(operationLogs, [])
  fillArray(backups, [])
  fillArray(openApis, [])
  fillArray(files, [])
  fillArray(supWarnings, [])
  fillArray(messages, [])
  fillArray(monthlyReport, [])
  fillArray(traceTimeline, [])
  fillArray(pesticideLedger, [])
  fillArray(tenants, [])
  fillArray(plotAudits, [])
  fillArray(farmerPlots, [])
  fillArray(dictTypes, [])
  fillArray(envLabels, [])
  for (const { target } of detailTargets) fillArray(target, [])
  fillObject(irrigationSummary, null)
  fillObject(park, null)
  fillObject(weather, null)
  fillObject(sysInfo, null)
  fillObject(qualityOverview, null)
  fillObject(traceDetail, null)
  fillObject(screenConfig, null)
  fillObject(envSeries, null)
  fillObject(waterElectric, null)
}

/* ------------------------------------------------------------------ *
 * 全量加载
 * ------------------------------------------------------------------ */

let inflight: Promise<void> | null = null

/**
 * 从后端加载全部业务数据。
 * 并发请求所有接口，任一失败即视为后端不可用：清空数据并进入 error 状态。
 */
export function loadAllData(): Promise<void> {
  if (inflight) return inflight

  backend.status = 'loading'
  backend.error = ''
  backend.attempts += 1

  inflight = (async () => {
    try {
      const [
        parkData,
        weatherData,
        envSeriesData,
        waterElectricData,
        qualityOverviewData,
        sysInfoData,
        screenConfigData,
        traceDetailData,
        traceTimelineData,
        plotsData,
        camerasData,
        devicesData,
        alarmsData,
        workOrdersData,
        materialsData,
        harvestsData,
        batchesData,
        inspectionsData,
        recallsData,
        usersData,
        rolesData,
        loginLogsData,
        operationLogsData,
        backupsData,
        openApisData,
        filesData,
        supWarningsData,
        messagesData,
        monthlyReportData,
        pesticideLedgerData,
        tenantsData,
        plotAuditsData,
        farmerPlotsData,
        dictTypesData,
      ] = await Promise.all([
        fetchPark(),
        fetchWeather(),
        fetchEnvSeries(),
        fetchWaterElectric(),
        fetchQualityOverview(),
        fetchSysInfo(),
        fetchScreenConfig(),
        fetchTraceDetail(),
        fetchTraceTimeline(),
        fetchPlots(),
        fetchCameras(),
        fetchDevices(),
        fetchAlarms(),
        fetchWorkOrders(),
        fetchMaterials(),
        fetchHarvests(),
        fetchBatches(),
        fetchInspections(),
        fetchRecalls(),
        fetchUsers(),
        fetchRoles(),
        fetchLoginLogs(),
        fetchOperationLogs(),
        fetchBackups(),
        fetchOpenApis(),
        fetchFiles(),
        fetchSupWarnings(),
        fetchMessages(),
        fetchMonthlyReport(),
        fetchPesticideLedger(),
        fetchTenants(),
        fetchPlotAudits(),
        fetchFarmerPlots(),
        fetchDictTypes(),
      ])

      fillObject(park, parkData)
      fillObject(weather, weatherData)
      fillObject(sysInfo, sysInfoData)
      fillObject(qualityOverview, qualityOverviewData)
      fillObject(traceDetail, traceDetailData)
      fillObject(screenConfig, screenConfigData)
      fillObject(envSeries, envSeriesData)
      fillObject(waterElectric, waterElectricData)

      fillArray(envLabels, envSeriesData.labels)
      fillArray(plots, plotsData)
      fillArray(cameras, camerasData)
      fillArray(devices, devicesData)
      fillArray(alarms, alarmsData)
      fillArray(workOrders, workOrdersData)
      fillArray(materials, materialsData)
      fillArray(harvests, harvestsData)
      fillArray(batches, batchesData)
      fillArray(inspections, inspectionsData)
      fillArray(recalls, recallsData)
      fillArray(users, usersData)
      fillArray(roles, rolesData)
      fillArray(loginLogs, loginLogsData)
      fillArray(operationLogs, operationLogsData)
      fillArray(backups, backupsData)
      fillArray(openApis, openApisData)
      fillArray(files, filesData)
      fillArray(supWarnings, supWarningsData)
      fillArray(messages, messagesData)
      fillArray(monthlyReport, monthlyReportData)
      fillArray(pesticideLedger, pesticideLedgerData)
      fillArray(tenants, tenantsData)
      fillArray(plotAudits, plotAuditsData)
      fillArray(farmerPlots, farmerPlotsData)
      fillArray(dictTypes, dictTypesData)
      fillArray(traceTimeline, traceTimelineData)

      // 页面级明细记录：结构由页面声明，这里只做搬运
      await Promise.all([
        ...detailTargets.map(async ({ target, path }) => {
          fillArray(target, await fetchDetailRows(path))
        }),
        fetchIrrigationSummary().then((data) => fillObject(irrigationSummary, data)),
      ])

      backend.status = 'ready'
      backend.loadedAt = Date.now()
    } catch (error) {
      clearAll()
      backend.status = 'error'
      backend.error = error instanceof Error ? error.message : '后端服务不可用'
    } finally {
      inflight = null
    }
  })()

  return inflight
}

/** 重试加载（失败后由准入层触发） */
export function reloadAllData(): Promise<void> {
  if (backend.status === 'loading') return inflight ?? Promise.resolve()
  return loadAllData()
}

/* ------------------------------------------------------------------ *
 * 派生查询
 * ------------------------------------------------------------------ */

export function findPlot(id: string): Plot | undefined {
  return plots.find((item) => item.id === id)
}

export function plotName(id: string): string {
  return findPlot(id)?.name ?? id
}
