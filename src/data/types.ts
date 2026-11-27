/**
 * 地块边界顶点
 *
 * 真实 GIS 数据以 lng / lat（WGS84）为准；x / y 是历史虚拟画布坐标，
 * 新数据由经纬度反算得到，保留是为了兼容仍按像素取值的旧代码（见 utils/geo.ts）。
 */
export interface MapPoint {
  x: number
  y: number
  lng?: number
  lat?: number
}

export interface Plot {
  id: string
  code: string
  name: string
  crop: string
  variety: string
  area: number
  greenhouse: string
  stage: string
  soil: string
  manager: string
  plantedAt: string
  expectedHarvest: string
  status: '正常' | '预警' | '休耕'
  color: string
  polygon: MapPoint[]
}

export type DeviceType = '水泵' | '风机' | '卷帘' | '补光灯' | '电磁阀' | '传感器' | '摄像头' | '网关'

export interface Device {
  id: string
  name: string
  type: DeviceType
  plotId: string
  status: '在线' | '离线' | '故障'
  running: boolean
  lastSeen: string
  protocol: string
  power: number
  battery?: number
}

export type AlarmLevel = '紧急' | '重要' | '一般'
export type AlarmStatus = '待确认' | '处置中' | '已归档'

export interface Alarm {
  id: string
  level: AlarmLevel
  title: string
  source: string
  device: string
  plot: string
  createdAt: string
  status: AlarmStatus
  value: string
  threshold: string
  handler: string
}

export type WorkStatus = '待接单' | '进行中' | '待验收' | '已完成'

export interface WorkOrder {
  id: string
  title: string
  plot: string
  crop: string
  type: string
  assignee: string
  phone: string
  createdAt: string
  deadline: string
  status: WorkStatus
  priority: '高' | '中' | '低'
  progress: number
  requirement: string
}

export interface Material {
  id: string
  name: string
  category: '种子' | '化肥' | '农药' | '农膜' | '工具'
  unit: string
  stock: number
  safeStock: number
  supplier: string
  batchNo: string
  updatedAt: string
}

export interface HarvestRecord {
  id: string
  batchNo: string
  plot: string
  crop: string
  weight: number
  grade: '特级' | '一级' | '二级'
  harvestedAt: string
  operator: string
  status: '待入库' | '已入库'
}

export interface TraceBatch {
  id: string
  batchNo: string
  plot: string
  crop: string
  variety: string
  plantedAt: string
  harvestedAt: string
  weight: number
  grade: string
  status: '已赋码' | '待赋码' | '已召回'
  qrCount: number
  scans: number
}

export interface InspectReport {
  id: string
  batchNo: string
  crop: string
  reportNo: string
  agency: string
  testedAt: string
  pesticide: string
  heavyMetal: string
  result: '合格' | '不合格'
  file: string
}

export interface RecallRecord {
  id: string
  batchNo: string
  crop: string
  reason: string
  level: '一级' | '二级'
  createdAt: string
  affected: number
  recovered: number
  status: '通知中' | '召回中' | '已完成'
}

export interface SysUser {
  id: string
  account: string
  name: string
  role: string
  phone: string
  plotScope: string
  status: '启用' | '停用'
  lastLogin: string
  createdAt: string
}

export interface Role {
  id: string
  name: string
  code: string
  members: number
  description: string
  permissions: string[]
}

export interface LogRecord {
  id: string
  account: string
  name: string
  action: string
  module: string
  ip: string
  time: string
  result: '成功' | '失败'
  detail?: string
}

export interface BackupRecord {
  id: string
  name: string
  size: string
  type: '自动' | '手动'
  createdAt: string
  status: '成功' | '进行中' | '失败'
}

export interface OpenApi {
  id: string
  name: string
  path: string
  method: 'GET' | 'POST' | 'PUT'
  target: string
  enabled: boolean
  calls: number
  updatedAt: string
  key: string
}

export interface FileRecord {
  id: string
  name: string
  type: '图片' | '文档' | '视频'
  size: string
  uploader: string
  uploadedAt: string
  url: string
}

export interface SupWarning {
  id: string
  title: string
  type: '质量异常' | '农事违规' | '设备告警' | '台账缺失'
  entity: string
  level: '高' | '中' | '低'
  createdAt: string
  status: '待处理' | '处理中' | '已办结'
}

export interface Camera {
  id: string
  name: string
  plot: string
  status: '在线' | '离线'
  resolution: string
  stream: string
}

export interface MessageItem {
  id: string
  title: string
  body: string
  time: string
  level: '紧急' | '重要' | '一般'
  read: boolean
  from: string
}

export interface Tenant {
  id: string
  name: string
  code: string
  contact: string
  phone: string
  resourceQuota: string
  userCount: number
  deviceCount: number
  status: '启用' | '停用'
  createdAt: string
}

export type AuditStatus = '待审核' | '已通过' | '已驳回'

export interface PlotAudit {
  id: string
  plotCode: string
  plotName: string
  crop: string
  variety: string
  area: number
  greenhouse: string
  submitBy: string
  farmerId: string
  submittedAt: string
  status: AuditStatus
  boundaryClosed: boolean
  polygon: MapPoint[]
  rejectReason?: string
}

/* ---------- 以下为聚合类接口返回结构（园区概览、系统信息、统计看板等） ---------- */

export interface ParkInfo {
  name: string
  shortName: string
  location: string
  area: number
  plots: number
  farmers: number
  manager: string
}

export interface WeatherForecast {
  day: string
  high: number
  low: number
  icon: string
}

export interface WeatherInfo {
  temperature: number
  humidity: number
  condition: string
  wind: string
  rainfall: number
  forecast: WeatherForecast[]
}

export interface SysInfo {
  version: string
  env: string
  db: string
  api: string
  uptime: string
  cpu: number
  memory: number
  disk: number
  onlineUsers: number
  mqttMessages: number
  apiCalls: number
}

export interface QualityCategory {
  name: string
  batches: number
  passRate: number
}

export interface QualityOverview {
  passRate: number
  inspectedBatches: number
  qualified: number
  unqualified: number
  recalls: number
  pesticideChecks: number
  trend: number[]
  categories: QualityCategory[]
}

export interface TraceInspect {
  reportNo: string
  agency: string
  testedAt: string
  pesticide: string
  heavyMetal: string
  conclusion: string
}

export interface TraceDetail {
  batchNo: string
  crop: string
  variety: string
  origin: string
  grade: string
  weight: string
  harvestedAt: string
  farmer: string
  plot: string
  scans: number
  inspect: TraceInspect
}

export interface TraceTimelineItem {
  date: string
  title: string
  desc: string
}

export interface ScreenSection {
  id: string
  name: string
  icon: string
  enabled: boolean
}

export interface ScreenConfig {
  sections: ScreenSection[]
  interval: number
  theme: string
  resolution: string
  defaultScope: string
}

export interface EnvSeries {
  labels: string[]
  temperature: number[]
  humidity: number[]
  soilTemperature: number[]
  soilMoisture: number[]
  co2: number[]
  light: number[]
  ph: number[]
  waterTemperature: number[]
}

export interface WaterElectric {
  months: string[]
  water: number[]
  electric: number[]
}

export interface MonthlyReportRow {
  month: string
  water: number
  electric: number
  cost: number
  alarms: number
  orders: number
}

export interface PesticideLedgerRow {
  id: string
  date: string
  plot: string
  crop: string
  name: string
  amount: string
  operator: string
  method: string
  safetyDays: number
  compliant: boolean
  note?: string
}

export interface DictItem {
  id: string
  code: string
  name: string
  sort: number
  status: '启用' | '停用'
  note: string
}

export interface DictType {
  id: string
  code: string
  name: string
  desc: string
  items: DictItem[]
}

export interface FarmerPlot {
  id: string
  name: string
  crop: string
  variety: string
  area: number
  greenhouse: string
  plantedAt: string
  expectedHarvest: string
  auditStatus: AuditStatus
  rejectReason?: string
  deviceCount: number
  envTemp: number
  envHumidity: number
  polygon: MapPoint[]
}
