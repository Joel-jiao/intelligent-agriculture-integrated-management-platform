export interface MapPoint {
  x: number
  y: number
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
