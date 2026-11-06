import type {
  Alarm,
  BackupRecord,
  Camera,
  Device,
  FileRecord,
  HarvestRecord,
  InspectReport,
  LogRecord,
  Material,
  MessageItem,
  OpenApi,
  Plot,
  RecallRecord,
  Role,
  SupWarning,
  SysUser,
  TraceBatch,
  WorkOrder,
} from './types'

export const park = {
  name: '云岭智慧农业示范园',
  shortName: '云岭农业',
  location: '重庆市璧山区现代农业园区',
  area: 286,
  plots: 6,
  farmers: 12,
  manager: '李明',
}

export const weather = {
  temperature: 26,
  humidity: 68,
  condition: '多云转晴',
  wind: '东南风 2级',
  rainfall: 0.4,
  forecast: [
    { day: '今天', high: 27, low: 18, icon: '云' },
    { day: '明天', high: 29, low: 19, icon: '晴' },
    { day: '后天', high: 25, low: 17, icon: '雨' },
  ],
}

export const plots: Plot[] = [
  {
    id: 'P-01',
    code: 'P-01',
    name: '1号智能大棚',
    crop: '番茄',
    variety: '云粉 9 号',
    area: 12.8,
    greenhouse: '连栋薄膜温室',
    stage: '结果期',
    soil: '壤土',
    manager: '王强',
    plantedAt: '2026-08-12',
    expectedHarvest: '2026-11-20',
    status: '正常',
    color: '#4fae74',
    polygon: [
      { x: 78, y: 92 },
      { x: 298, y: 82 },
      { x: 320, y: 236 },
      { x: 92, y: 252 },
    ],
  },
  {
    id: 'P-02',
    code: 'P-02',
    name: '2号草莓棚',
    crop: '草莓',
    variety: '红颜',
    area: 8.6,
    greenhouse: '日光温室',
    stage: '开花期',
    soil: '砂壤土',
    manager: '赵敏',
    plantedAt: '2026-09-02',
    expectedHarvest: '2026-12-10',
    status: '正常',
    color: '#d56b6b',
    polygon: [
      { x: 342, y: 78 },
      { x: 546, y: 86 },
      { x: 556, y: 232 },
      { x: 352, y: 244 },
    ],
  },
  {
    id: 'P-03',
    code: 'P-03',
    name: '3号黄瓜棚',
    crop: '黄瓜',
    variety: '津优 35',
    area: 10.2,
    greenhouse: '连栋薄膜温室',
    stage: '采收期',
    soil: '壤土',
    manager: '陈刚',
    plantedAt: '2026-07-26',
    expectedHarvest: '2026-10-30',
    status: '预警',
    color: '#3d8f5c',
    polygon: [
      { x: 602, y: 88 },
      { x: 820, y: 92 },
      { x: 842, y: 246 },
      { x: 612, y: 258 },
    ],
  },
  {
    id: 'P-04',
    code: 'P-04',
    name: '露天 A 区果园',
    crop: '柑橘',
    variety: '爱媛 38',
    area: 32.5,
    greenhouse: '露天种植',
    stage: '果实膨大期',
    soil: '紫色土',
    manager: '周涛',
    plantedAt: '2024-03-18',
    expectedHarvest: '2026-12-05',
    status: '正常',
    color: '#c9973f',
    polygon: [
      { x: 102, y: 322 },
      { x: 330, y: 310 },
      { x: 352, y: 486 },
      { x: 112, y: 498 },
    ],
  },
  {
    id: 'P-05',
    code: 'P-05',
    name: '露天 B 区稻田',
    crop: '水稻',
    variety: '宜香优 2115',
    area: 48.2,
    greenhouse: '露天种植',
    stage: '灌浆期',
    soil: '水稻土',
    manager: '刘洋',
    plantedAt: '2026-05-20',
    expectedHarvest: '2026-10-28',
    status: '正常',
    color: '#6a9e3f',
    polygon: [
      { x: 398, y: 300 },
      { x: 702, y: 296 },
      { x: 712, y: 498 },
      { x: 410, y: 504 },
    ],
  },
  {
    id: 'P-06',
    code: 'P-06',
    name: '育苗棚',
    crop: '辣椒苗',
    variety: '螺丝椒',
    area: 3.4,
    greenhouse: '育苗温室',
    stage: '苗期',
    soil: '基质土',
    manager: '赵敏',
    plantedAt: '2026-10-12',
    expectedHarvest: '2026-12-28',
    status: '休耕',
    color: '#8fb05f',
    polygon: [
      { x: 748, y: 320 },
      { x: 900, y: 318 },
      { x: 912, y: 468 },
      { x: 758, y: 478 },
    ],
  },
]

export const cameras: Camera[] = [
  { id: 'CAM-01', name: '1号大棚 · 东侧', plot: 'P-01', status: '在线', resolution: '1920×1080', stream: 'rtsp://cam01/live' },
  { id: 'CAM-02', name: '1号大棚 · 西侧', plot: 'P-01', status: '在线', resolution: '1920×1080', stream: 'rtsp://cam02/live' },
  { id: 'CAM-03', name: '2号草莓棚 · 入口', plot: 'P-02', status: '在线', resolution: '1280×720', stream: 'rtsp://cam03/live' },
  { id: 'CAM-04', name: '3号黄瓜棚 · 中部', plot: 'P-03', status: '在线', resolution: '1920×1080', stream: 'rtsp://cam04/live' },
  { id: 'CAM-05', name: '露天果园 · 全景', plot: 'P-04', status: '离线', resolution: '2560×1440', stream: 'rtsp://cam05/live' },
  { id: 'CAM-06', name: '稻田 · 灌渠', plot: 'P-05', status: '在线', resolution: '1920×1080', stream: 'rtsp://cam06/live' },
]

export const devices: Device[] = [
  { id: 'DEV-101', name: '1号棚水泵', type: '水泵', plotId: 'P-01', status: '在线', running: true, lastSeen: '2026-11-06 09:42:18', protocol: 'MQTT', power: 2.2 },
  { id: 'DEV-102', name: '1号棚环流风机', type: '风机', plotId: 'P-01', status: '在线', running: true, lastSeen: '2026-11-06 09:42:10', protocol: 'MQTT', power: 1.5 },
  { id: 'DEV-103', name: '1号棚外遮阳卷帘', type: '卷帘', plotId: 'P-01', status: '在线', running: false, lastSeen: '2026-11-06 09:41:58', protocol: 'Modbus', power: 0.75 },
  { id: 'DEV-104', name: '1号棚补光灯组', type: '补光灯', plotId: 'P-01', status: '在线', running: false, lastSeen: '2026-11-06 09:42:01', protocol: 'MQTT', power: 3.6 },
  { id: 'DEV-105', name: '2号棚滴灌电磁阀', type: '电磁阀', plotId: 'P-02', status: '在线', running: true, lastSeen: '2026-11-06 09:42:22', protocol: 'MQTT', power: 0.3 },
  { id: 'DEV-106', name: '2号棚加温风机', type: '风机', plotId: 'P-02', status: '在线', running: false, lastSeen: '2026-11-06 09:42:02', protocol: 'MQTT', power: 1.5 },
  { id: 'DEV-107', name: '3号棚水泵', type: '水泵', plotId: 'P-03', status: '故障', running: false, lastSeen: '2026-11-06 08:56:33', protocol: 'MQTT', power: 2.2 },
  { id: 'DEV-108', name: '3号棚内遮阳卷帘', type: '卷帘', plotId: 'P-03', status: '在线', running: false, lastSeen: '2026-11-06 09:42:05', protocol: 'Modbus', power: 0.75 },
  { id: 'DEV-109', name: 'A区灌溉泵', type: '水泵', plotId: 'P-04', status: '在线', running: false, lastSeen: '2026-11-06 09:41:49', protocol: 'Modbus', power: 5.5 },
  { id: 'DEV-110', name: 'A区电磁阀 1', type: '电磁阀', plotId: 'P-04', status: '在线', running: false, lastSeen: '2026-11-06 09:41:51', protocol: 'Modbus', power: 0.3 },
  { id: 'DEV-111', name: 'B区排灌泵', type: '水泵', plotId: 'P-05', status: '在线', running: true, lastSeen: '2026-11-06 09:42:14', protocol: 'MQTT', power: 7.5 },
  { id: 'DEV-112', name: '育苗棚补光灯', type: '补光灯', plotId: 'P-06', status: '在线', running: false, lastSeen: '2026-11-06 09:41:55', protocol: 'MQTT', power: 2.4 },
  { id: 'DEV-201', name: '1号棚环境传感器', type: '传感器', plotId: 'P-01', status: '在线', running: true, lastSeen: '2026-11-06 09:42:24', protocol: 'RS485', power: 0.1, battery: 92 },
  { id: 'DEV-202', name: '2号棚环境传感器', type: '传感器', plotId: 'P-02', status: '在线', running: true, lastSeen: '2026-11-06 09:42:21', protocol: 'RS485', power: 0.1, battery: 88 },
  { id: 'DEV-203', name: '3号棚环境传感器', type: '传感器', plotId: 'P-03', status: '在线', running: true, lastSeen: '2026-11-06 09:42:17', protocol: 'RS485', power: 0.1, battery: 76 },
  { id: 'DEV-204', name: 'B区水质传感器', type: '传感器', plotId: 'P-05', status: '离线', running: false, lastSeen: '2026-11-06 07:12:08', protocol: 'RS485', power: 0.1, battery: 12 },
  { id: 'DEV-301', name: '园区主网关', type: '网关', plotId: 'P-01', status: '在线', running: true, lastSeen: '2026-11-06 09:42:25', protocol: 'MQTT', power: 12 },
]

export const alarms: Alarm[] = [
  { id: 'ALM-20261106-01', level: '紧急', title: '3号黄瓜棚水泵故障停机', source: '设备状态', device: 'DEV-107', plot: 'P-03', createdAt: '2026-11-06 08:56', status: '待确认', value: '运行电流 0 A', threshold: '额定 ≥ 3.2 A', handler: '—' },
  { id: 'ALM-20261106-02', level: '重要', title: '3号棚空气温度超过上限', source: '环境监测', device: 'DEV-203', plot: 'P-03', createdAt: '2026-11-06 09:12', status: '处置中', value: '36.4 ℃', threshold: '上限 32 ℃', handler: '李明' },
  { id: 'ALM-20261106-03', level: '重要', title: 'B区水质传感器电量不足', source: '设备状态', device: 'DEV-204', plot: 'P-05', createdAt: '2026-11-06 07:15', status: '待确认', value: '电量 12%', threshold: '预警 < 20%', handler: '—' },
  { id: 'ALM-20261105-04', level: '一般', title: '2号草莓棚土壤湿度偏低', source: '环境监测', device: 'DEV-202', plot: 'P-02', createdAt: '2026-11-05 16:40', status: '已归档', value: '土壤湿度 38%', threshold: '下限 45%', handler: '赵敏' },
  { id: 'ALM-20261105-05', level: '一般', title: '1号棚 CO₂ 浓度偏低', source: '环境监测', device: 'DEV-201', plot: 'P-01', createdAt: '2026-11-05 14:22', status: '已归档', value: '412 ppm', threshold: '下限 450 ppm', handler: '王强' },
  { id: 'ALM-20261105-06', level: '紧急', title: 'A区摄像头离线', source: '视频监控', device: 'CAM-05', plot: 'P-04', createdAt: '2026-11-05 11:08', status: '已归档', value: '连接超时', threshold: '在线', handler: '运维组' },
  { id: 'ALM-20261104-07', level: '重要', title: 'A区灌溉泵累计运行超时', source: '能耗监测', device: 'DEV-109', plot: 'P-04', createdAt: '2026-11-04 19:36', status: '已归档', value: '连续运行 4.2 h', threshold: '上限 3 h', handler: '周涛' },
  { id: 'ALM-20261104-08', level: '一般', title: '育苗棚光照强度不足', source: '环境监测', device: 'DEV-203', plot: 'P-06', createdAt: '2026-11-04 09:05', status: '已归档', value: '光照 860 lux', threshold: '下限 1200 lux', handler: '赵敏' },
]

export const workOrders: WorkOrder[] = [
  { id: 'WO-20261106-01', title: '3号棚黄瓜采收与分级', plot: 'P-03', crop: '黄瓜', type: '采收作业', assignee: '陈刚', phone: '138****6210', createdAt: '2026-11-06 08:20', deadline: '2026-11-06 18:00', status: '进行中', priority: '高', progress: 55, requirement: '完成 3 号棚东侧 6 垄黄瓜采收，按特级、一级、二级分筐装运，采收后同步记录单筐重量。' },
  { id: 'WO-20261106-02', title: '1号棚番茄打叶与绑蔓', plot: 'P-01', crop: '番茄', type: '植株管理', assignee: '王强', phone: '139****8832', createdAt: '2026-11-06 07:50', deadline: '2026-11-07 12:00', status: '进行中', priority: '中', progress: 30, requirement: '清除下部老叶与病叶，绑蔓高度控制在 1.6 米，作业后上传现场照片。' },
  { id: 'WO-20261106-03', title: '2号棚滴灌系统巡检', plot: 'P-02', crop: '草莓', type: '设备巡检', assignee: '赵敏', phone: '137****4109', createdAt: '2026-11-06 07:30', deadline: '2026-11-06 15:00', status: '待接单', priority: '中', progress: 0, requirement: '检查滴灌带出水均匀度，清理过滤器，记录主管压力与流量。' },
  { id: 'WO-20261106-04', title: 'B区稻田灌浆期水肥管理', plot: 'P-05', crop: '水稻', type: '水肥管理', assignee: '刘洋', phone: '136****7521', createdAt: '2026-11-05 16:10', deadline: '2026-11-07 10:00', status: '进行中', priority: '高', progress: 42, requirement: '保持浅水层 3-5 cm，追施磷酸二氢钾 2 kg/亩，注意避免倒伏。' },
  { id: 'WO-20261105-05', title: 'A区柑橘果园病枝清理', plot: 'P-04', crop: '柑橘', type: '植保作业', assignee: '周涛', phone: '135****3390', createdAt: '2026-11-05 14:40', deadline: '2026-11-06 17:00', status: '待验收', priority: '中', progress: 100, requirement: '剪除感染枝条并集中处理，作业后喷洒生物制剂，上传病枝处理照片。' },
  { id: 'WO-20261105-06', title: '育苗棚辣椒苗间苗', plot: 'P-06', crop: '辣椒苗', type: '植株管理', assignee: '赵敏', phone: '137****4109', createdAt: '2026-11-05 09:20', deadline: '2026-11-06 12:00', status: '已完成', priority: '低', progress: 100, requirement: '按 3 cm 株距间苗，去除弱苗与病苗，记录间苗数量。' },
  { id: 'WO-20261104-07', title: '3号棚黄板更换', plot: 'P-03', crop: '黄瓜', type: '植保作业', assignee: '陈刚', phone: '138****6210', createdAt: '2026-11-04 15:30', deadline: '2026-11-05 18:00', status: '已完成', priority: '低', progress: 100, requirement: '更换黄板 40 张，记录粘虫数量并上报虫情。' },
  { id: 'WO-20261104-08', title: 'A区灌溉管道冬季保温', plot: 'P-04', crop: '柑橘', type: '设施维护', assignee: '周涛', phone: '135****3390', createdAt: '2026-11-04 10:00', deadline: '2026-11-08 17:00', status: '待接单', priority: '中', progress: 0, requirement: '对暴露管道加装保温棉，检查阀门密封性，完成后拍照留档。' },
]

export const materials: Material[] = [
  { id: 'MAT-01', name: '云粉 9 号番茄种子', category: '种子', unit: '袋', stock: 24, safeStock: 10, supplier: '重庆种业有限公司', batchNo: 'SD20260812', updatedAt: '2026-11-05 14:20' },
  { id: 'MAT-02', name: '红颜草莓苗', category: '种子', unit: '株', stock: 1200, safeStock: 800, supplier: '璧山苗木合作社', batchNo: 'SD20260902', updatedAt: '2026-11-05 10:12' },
  { id: 'MAT-03', name: '复合肥 15-15-15', category: '化肥', unit: 'kg', stock: 380, safeStock: 300, supplier: '中化化肥西南分公司', batchNo: 'FERT20261018', updatedAt: '2026-11-04 16:35' },
  { id: 'MAT-04', name: '磷酸二氢钾', category: '化肥', unit: 'kg', stock: 68, safeStock: 100, supplier: '中化化肥西南分公司', batchNo: 'FERT20260926', updatedAt: '2026-11-04 09:28' },
  { id: 'MAT-05', name: '生物杀虫剂苏云金杆菌', category: '农药', unit: '瓶', stock: 18, safeStock: 12, supplier: '绿源生物科技', batchNo: 'PEST20260930', updatedAt: '2026-11-03 15:42' },
  { id: 'MAT-06', name: '黄板诱虫贴', category: '工具', unit: '张', stock: 22, safeStock: 50, supplier: '农友农资店', batchNo: 'TOOL20261012', updatedAt: '2026-11-03 11:05' },
  { id: 'MAT-07', name: '滴灌带 Φ16', category: '工具', unit: '卷', stock: 9, safeStock: 6, supplier: '润丰灌溉设备', batchNo: 'TOOL20260820', updatedAt: '2026-11-01 14:16' },
  { id: 'MAT-08', name: '温室保温膜', category: '农膜', unit: '卷', stock: 5, safeStock: 8, supplier: '渝西农膜厂', batchNo: 'FILM20261008', updatedAt: '2026-10-30 09:30' },
]

export const harvests: HarvestRecord[] = [
  { id: 'HR-01', batchNo: 'B20261105-03', plot: 'P-03', crop: '黄瓜', weight: 1260, grade: '一级', harvestedAt: '2026-11-05 16:30', operator: '陈刚', status: '已入库' },
  { id: 'HR-02', batchNo: 'B20261105-04', plot: 'P-01', crop: '番茄', weight: 860, grade: '特级', harvestedAt: '2026-11-05 10:15', operator: '王强', status: '已入库' },
  { id: 'HR-03', batchNo: 'B20261104-02', plot: 'P-02', crop: '草莓', weight: 420, grade: '特级', harvestedAt: '2026-11-04 08:40', operator: '赵敏', status: '已入库' },
  { id: 'HR-04', batchNo: 'B20261103-01', plot: 'P-05', crop: '水稻', weight: 5200, grade: '一级', harvestedAt: '2026-11-03 15:20', operator: '刘洋', status: '待入库' },
  { id: 'HR-05', batchNo: 'B20261102-05', plot: 'P-04', crop: '柑橘', weight: 3100, grade: '一级', harvestedAt: '2026-11-02 11:00', operator: '周涛', status: '已入库' },
  { id: 'HR-06', batchNo: 'B20261030-06', plot: 'P-03', crop: '黄瓜', weight: 980, grade: '二级', harvestedAt: '2026-10-30 17:10', operator: '陈刚', status: '已入库' },
]

export const batches: TraceBatch[] = [
  { id: 'TB-01', batchNo: 'B20261105-03', plot: 'P-03', crop: '黄瓜', variety: '津优 35', plantedAt: '2026-07-26', harvestedAt: '2026-11-05', weight: 1260, grade: '一级', status: '已赋码', qrCount: 1260, scans: 386 },
  { id: 'TB-02', batchNo: 'B20261105-04', plot: 'P-01', crop: '番茄', variety: '云粉 9 号', plantedAt: '2026-08-12', harvestedAt: '2026-11-05', weight: 860, grade: '特级', status: '已赋码', qrCount: 860, scans: 254 },
  { id: 'TB-03', batchNo: 'B20261104-02', plot: 'P-02', crop: '草莓', variety: '红颜', plantedAt: '2026-09-02', harvestedAt: '2026-11-04', weight: 420, grade: '特级', status: '待赋码', qrCount: 0, scans: 0 },
  { id: 'TB-04', batchNo: 'B20261103-01', plot: 'P-05', crop: '水稻', variety: '宜香优 2115', plantedAt: '2026-05-20', harvestedAt: '2026-11-03', weight: 5200, grade: '一级', status: '待赋码', qrCount: 0, scans: 0 },
  { id: 'TB-05', batchNo: 'B20261030-06', plot: 'P-03', crop: '黄瓜', variety: '津优 35', plantedAt: '2026-07-26', harvestedAt: '2026-10-30', weight: 980, grade: '二级', status: '已召回', qrCount: 980, scans: 122 },
  { id: 'TB-06', batchNo: 'B20261102-05', plot: 'P-04', crop: '柑橘', variety: '爱媛 38', plantedAt: '2024-03-18', harvestedAt: '2026-11-02', weight: 3100, grade: '一级', status: '已赋码', qrCount: 3100, scans: 915 },
]

export const inspections: InspectReport[] = [
  { id: 'IR-01', batchNo: 'B20261105-03', crop: '黄瓜', reportNo: 'CQ-JC-20261105-031', agency: '重庆市农产品质量检测中心', testedAt: '2026-11-05', pesticide: '未检出', heavyMetal: '合格', result: '合格', file: '黄瓜检测报告_20261105.pdf' },
  { id: 'IR-02', batchNo: 'B20261105-04', crop: '番茄', reportNo: 'CQ-JC-20261105-032', agency: '重庆市农产品质量检测中心', testedAt: '2026-11-05', pesticide: '未检出', heavyMetal: '合格', result: '合格', file: '番茄检测报告_20261105.pdf' },
  { id: 'IR-03', batchNo: 'B20261104-02', crop: '草莓', reportNo: 'CQ-JC-20261104-018', agency: '璧山区农产品检测站', testedAt: '2026-11-04', pesticide: '未检出', heavyMetal: '合格', result: '合格', file: '草莓检测报告_20261104.pdf' },
  { id: 'IR-04', batchNo: 'B20261030-06', crop: '黄瓜', reportNo: 'CQ-JC-20261030-096', agency: '璧山区农产品检测站', testedAt: '2026-10-30', pesticide: '检出 0.03 mg/kg', heavyMetal: '合格', result: '不合格', file: '黄瓜检测报告_20261030.pdf' },
  { id: 'IR-05', batchNo: 'B20261102-05', crop: '柑橘', reportNo: 'CQ-JC-20261102-044', agency: '重庆市农产品质量检测中心', testedAt: '2026-11-02', pesticide: '未检出', heavyMetal: '合格', result: '合格', file: '柑橘检测报告_20261102.pdf' },
]

export const recalls: RecallRecord[] = [
  { id: 'RC-01', batchNo: 'B20261030-06', crop: '黄瓜', reason: '农残检测结果超出内部验收标准，存在质量风险', level: '二级', createdAt: '2026-11-01 09:30', affected: 980, recovered: 760, status: '召回中' },
  { id: 'RC-02', batchNo: 'B20261025-02', crop: '番茄', reason: '包装标签批次信息打印错误', level: '二级', createdAt: '2026-10-27 14:10', affected: 320, recovered: 320, status: '已完成' },
  { id: 'RC-03', batchNo: 'B20261018-04', crop: '草莓', reason: '冷链运输温度异常，果实品质下降', level: '一级', createdAt: '2026-10-19 08:20', affected: 260, recovered: 248, status: '已完成' },
]

export const users: SysUser[] = [
  { id: 'U-001', account: 'admin', name: '李明', role: '园区管理员', phone: '138****0001', plotScope: '全部地块', status: '启用', lastLogin: '2026-11-06 09:32', createdAt: '2026-03-01' },
  { id: 'U-002', account: 'wangq', name: '王强', role: '农户', phone: '139****8832', plotScope: 'P-01', status: '启用', lastLogin: '2026-11-06 08:12', createdAt: '2026-03-12' },
  { id: 'U-003', account: 'zhaom', name: '赵敏', role: '农户', phone: '137****4109', plotScope: 'P-02、P-06', status: '启用', lastLogin: '2026-11-06 07:48', createdAt: '2026-03-12' },
  { id: 'U-004', account: 'cheng', name: '陈刚', role: '农户', phone: '138****6210', plotScope: 'P-03', status: '启用', lastLogin: '2026-11-06 08:02', createdAt: '2026-04-08' },
  { id: 'U-005', account: 'ops', name: '张运维', role: '运维', phone: '136****5521', plotScope: '系统全部', status: '启用', lastLogin: '2026-11-06 09:10', createdAt: '2026-03-01' },
  { id: 'U-006', account: 'liuy', name: '刘洋', role: '农户', phone: '136****7521', plotScope: 'P-05', status: '停用', lastLogin: '2026-10-28 16:22', createdAt: '2026-04-15' },
  { id: 'U-007', account: 'sup01', name: '监管员 · 黄洁', role: '监管人员', phone: '135****1180', plotScope: '璧山区辖区', status: '启用', lastLogin: '2026-11-06 09:01', createdAt: '2026-06-20' },
]

export const roles: Role[] = [
  { id: 'R-01', name: '园区管理员', code: 'ADMIN', members: 2, description: '业务运营、设备控制、工单派发、报表统计', permissions: ['dashboard', 'iot', 'control', 'farm', 'trace', 'gis', 'alarm', 'report'] },
  { id: 'R-02', name: '运维', code: 'OPS', members: 1, description: '底层运维、用户权限、设备接入、日志审计', permissions: ['workbench', 'users', 'roles', 'device-access', 'dict', 'logs', 'backup', 'openapi', 'files'] },
  { id: 'R-03', name: '农户', code: 'FARMER', members: 8, description: '移动端任务执行、打卡上报、设备控制', permissions: ['app-tasks', 'app-env', 'app-device', 'app-trace'] },
  { id: 'R-04', name: '监管人员', code: 'SUPERVISE', members: 3, description: '辖区质量数据、溯源台账、预警与报表', permissions: ['sup-overview', 'sup-quality', 'sup-trace', 'sup-pesticide', 'sup-warning', 'sup-report'] },
  { id: 'R-05', name: '访客', code: 'GUEST', members: 0, description: '只读查看公开溯源数据', permissions: ['h5-trace'] },
]

export const loginLogs: LogRecord[] = [
  { id: 'LL-01', account: 'admin', name: '李明', action: '登录系统', module: '管理员端', ip: '192.168.10.22', time: '2026-11-06 09:32:18', result: '成功' },
  { id: 'LL-02', account: 'ops', name: '张运维', action: '登录系统', module: '运维端', ip: '192.168.10.31', time: '2026-11-06 09:10:44', result: '成功' },
  { id: 'LL-03', account: 'sup01', name: '黄洁', action: '登录系统', module: '监管端', ip: '10.20.5.118', time: '2026-11-06 09:01:05', result: '成功' },
  { id: 'LL-04', account: 'wangq', name: '王强', action: '移动端登录', module: '农户端', ip: '10.20.8.42', time: '2026-11-06 08:12:51', result: '成功' },
  { id: 'LL-05', account: 'admin', name: '李明', action: '密码错误', module: '管理员端', ip: '192.168.10.22', time: '2026-11-06 08:02:13', result: '失败' },
  { id: 'LL-06', account: 'liuy', name: '刘洋', action: '登录系统', module: '农户端', ip: '10.20.8.55', time: '2026-11-05 16:22:30', result: '成功' },
  { id: 'LL-07', account: 'ops', name: '张运维', action: '退出系统', module: '运维端', ip: '192.168.10.31', time: '2026-11-05 18:05:12', result: '成功' },
  { id: 'LL-08', account: 'unknown', name: '未知用户', action: '非法令牌访问', module: '接口', ip: '203.0.113.8', time: '2026-11-05 03:14:29', result: '失败' },
]

export const operationLogs: LogRecord[] = [
  { id: 'OL-01', account: 'admin', name: '李明', action: '下发 1号棚水泵启动指令', module: '设备控制', ip: '192.168.10.22', time: '2026-11-06 09:40:12', result: '成功', detail: '设备 DEV-101，指令 START，耗时 0.42s' },
  { id: 'OL-02', account: 'admin', name: '李明', action: '创建农事工单 WO-20261106-01', module: '农事工单', ip: '192.168.10.22', time: '2026-11-06 08:20:35', result: '成功', detail: '派发给农户陈刚' },
  { id: 'OL-03', account: 'ops', name: '张运维', action: '新增设备接入 DEV-301', module: '设备接入', ip: '192.168.10.31', time: '2026-11-06 08:05:19', result: '成功', detail: '协议 MQTT，采集频率 30s' },
  { id: 'OL-04', account: 'admin', name: '李明', action: '确认告警 ALM-20261106-02', module: '告警处置', ip: '192.168.10.22', time: '2026-11-06 09:15:07', result: '成功', detail: '转为处置中，处置人李明' },
  { id: 'OL-05', account: 'ops', name: '张运维', action: '修改数据字典 crop_type', module: '系统参数', ip: '192.168.10.31', time: '2026-11-05 17:42:11', result: '成功', detail: '新增作物分类：叶菜类' },
  { id: 'OL-06', account: 'admin', name: '李明', action: '导出环境月报 2026-10', module: '报表中心', ip: '192.168.10.22', time: '2026-11-05 16:30:45', result: '成功', detail: 'Excel，共 31 天数据' },
  { id: 'OL-07', account: 'sup01', name: '黄洁', action: '查询辖区溯源台账', module: '监管端', ip: '10.20.5.118', time: '2026-11-05 15:12:28', result: '成功', detail: '查询 24 条' },
  { id: 'OL-08', account: 'ops', name: '张运维', action: '执行数据库备份', module: '数据备份', ip: '192.168.10.31', time: '2026-11-05 02:00:00', result: '成功', detail: '备份文件 agri_20261105_020000.sql.gz，大小 428MB' },
  { id: 'OL-09', account: 'admin', name: '李明', action: '召回批次 B20261030-06', module: '产品召回', ip: '192.168.10.22', time: '2026-11-01 09:30:22', result: '成功', detail: '召回级别二级' },
  { id: 'OL-10', account: 'ops', name: '张运维', action: '重置用户 liuy 密码', module: '用户管理', ip: '192.168.10.31', time: '2026-10-31 14:18:09', result: '成功', detail: '临时密码有效 24 小时' },
]

export const backups: BackupRecord[] = [
  { id: 'BK-01', name: 'agri_20261105_020000.sql.gz', size: '428 MB', type: '自动', createdAt: '2026-11-05 02:00:00', status: '成功' },
  { id: 'BK-02', name: 'agri_20261104_020000.sql.gz', size: '426 MB', type: '自动', createdAt: '2026-11-04 02:00:00', status: '成功' },
  { id: 'BK-03', name: 'agri_20261103_020000.sql.gz', size: '425 MB', type: '自动', createdAt: '2026-11-03 02:00:00', status: '成功' },
  { id: 'BK-04', name: 'agri_manual_20261102_143012.sql.gz', size: '424 MB', type: '手动', createdAt: '2026-11-02 14:30:12', status: '成功' },
  { id: 'BK-05', name: 'agri_20261101_020000.sql.gz', size: '423 MB', type: '自动', createdAt: '2026-11-01 02:00:00', status: '成功' },
]

export const openApis: OpenApi[] = [
  { id: 'API-01', name: '气象数据同步', path: '/api/v1/open/weather/sync', method: 'GET', target: '和风天气 API', enabled: true, calls: 8642, updatedAt: '2026-11-05 10:12', key: 'ak_weather_9f2c****3a71' },
  { id: 'API-02', name: '监管平台溯台上报', path: '/api/v1/open/trace/report', method: 'POST', target: '璧山区农业监管平台', enabled: true, calls: 1260, updatedAt: '2026-11-04 16:30', key: 'ak_sup_7d1e****b842' },
  { id: 'API-03', name: '短信告警推送', path: '/api/v1/open/sms/send', method: 'POST', target: '阿里云短信服务', enabled: true, calls: 342, updatedAt: '2026-11-03 09:05', key: 'ak_sms_3c88****e15d' },
  { id: 'API-04', name: '视频流鉴权', path: '/api/v1/open/video/token', method: 'GET', target: '海康威视 openapi', enabled: false, calls: 78, updatedAt: '2026-10-28 14:22', key: 'ak_video_b41f****00c9' },
  { id: 'API-05', name: 'MQTT 网关状态回调', path: '/api/v1/open/iot/callback', method: 'POST', target: '园区物联网网关', enabled: true, calls: 25680, updatedAt: '2026-11-06 09:42', key: 'ak_iot_6a9d****7f30' },
]

export const files: FileRecord[] = [
  { id: 'F-01', name: '番茄检测报告_20261105.pdf', type: '文档', size: '1.2 MB', uploader: '李明', uploadedAt: '2026-11-05 11:20', url: '/files/inspect/tomato-1105.pdf' },
  { id: 'F-02', name: '3号棚黄瓜采收现场-1.jpg', type: '图片', size: '3.8 MB', uploader: '陈刚', uploadedAt: '2026-11-05 16:32', url: '/files/harvest/cucumber-01.jpg' },
  { id: 'F-03', name: '3号棚黄瓜采收现场-2.jpg', type: '图片', size: '3.6 MB', uploader: '陈刚', uploadedAt: '2026-11-05 16:33', url: '/files/harvest/cucumber-02.jpg' },
  { id: 'F-04', name: 'A区病枝清理作业.mp4', type: '视频', size: '48.2 MB', uploader: '周涛', uploadedAt: '2026-11-05 17:05', url: '/files/work/a-orchard.mp4' },
  { id: 'F-05', name: '园区设备台账_2026Q4.xlsx', type: '文档', size: '860 KB', uploader: '张运维', uploadedAt: '2026-11-04 09:40', url: '/files/device/ledger-q4.xlsx' },
  { id: 'F-06', name: '草莓包装标签模板.png', type: '图片', size: '2.1 MB', uploader: '李明', uploadedAt: '2026-11-03 15:12', url: '/files/trace/strawberry-label.png' },
  { id: 'F-07', name: '2026年10月环境月报.pdf', type: '文档', size: '4.6 MB', uploader: '李明', uploadedAt: '2026-11-02 10:08', url: '/files/report/env-202610.pdf' },
  { id: 'F-08', name: '物联网网关配置说明.pdf', type: '文档', size: '2.8 MB', uploader: '张运维', uploadedAt: '2026-11-01 14:00', url: '/files/iot/gateway-config.pdf' },
]

export const supWarnings: SupWarning[] = [
  { id: 'SW-01', title: '黄瓜批次 B20261030-06 农残检测不合格', type: '质量异常', entity: '云岭智慧农业示范园 · P-03', level: '高', createdAt: '2026-11-01 09:35', status: '处理中' },
  { id: 'SW-02', title: '农药使用记录缺少施药人员签字', type: '台账缺失', entity: '云岭智慧农业示范园 · P-01', level: '中', createdAt: '2026-10-31 15:20', status: '待处理' },
  { id: 'SW-03', title: '3号棚水泵故障未在 2 小时内处置', type: '设备告警', entity: '云岭智慧农业示范园 · P-03', level: '中', createdAt: '2026-11-06 08:58', status: '待处理' },
  { id: 'SW-04', title: '草莓采收未按规定进行分级登记', type: '农事违规', entity: '云岭智慧农业示范园 · P-02', level: '低', createdAt: '2026-11-04 10:12', status: '已办结' },
  { id: 'SW-05', title: '追溯码扫码访问量异常骤增', type: '质量异常', entity: '云岭智慧农业示范园 · P-04', level: '低', createdAt: '2026-11-03 22:40', status: '已办结' },
  { id: 'SW-06', title: '水稻批次检测报告尚未归档', type: '台账缺失', entity: '云岭智慧农业示范园 · P-05', level: '中', createdAt: '2026-11-03 14:05', status: '处理中' },
]

export const messages: MessageItem[] = [
  { id: 'MSG-01', title: '3号黄瓜棚水泵故障停机', body: '设备 DEV-107 运行电流为 0，请尽快到现场排查水泵及供电线路。', time: '2026-11-06 08:56', level: '紧急', read: false, from: '告警中心' },
  { id: 'MSG-02', title: '3号棚空气温度超过上限', body: '当前温度 36.4℃，已超过设定上限 32℃，建议开启环流风机并拉开遮阳帘。', time: '2026-11-06 09:12', level: '重要', read: false, from: '环境监测' },
  { id: 'MSG-03', title: '新工单：3号棚黄瓜采收与分级', body: '管理员李明派发采收工单，截止时间今日 18:00，请及时接单。', time: '2026-11-06 08:20', level: '重要', read: false, from: '农事工单' },
  { id: 'MSG-04', title: 'B区水质传感器电量不足', body: '设备 DEV-204 剩余电量 12%，请更换电池，避免数据中断。', time: '2026-11-06 07:15', level: '一般', read: true, from: '设备状态' },
  { id: 'MSG-05', title: '2号棚滴灌巡检任务已派发', body: '请在今日 15:00 前完成滴灌系统巡检并提交记录。', time: '2026-11-06 07:30', level: '一般', read: true, from: '农事工单' },
  { id: 'MSG-06', title: '本月环境月报已生成', body: '2026 年 10 月环境监测月报已生成，可在报表中心查看与导出。', time: '2026-11-01 09:00', level: '一般', read: true, from: '报表中心' },
]

export const envLabels = ['00:00', '01:00', '02:00', '03:00', '04:00', '05:00', '06:00', '07:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00', '21:00', '22:00', '23:00']

export const envSeries = {
  temperature: [19.2, 18.6, 18.2, 17.9, 17.8, 18.1, 18.8, 20.4, 23.1, 26.2, 28.4, 30.1, 31.6, 32.4, 32.1, 30.8, 29.2, 27.4, 25.6, 23.8, 22.1, 20.9, 20.1, 19.6],
  humidity: [82, 84, 86, 87, 88, 86, 83, 79, 74, 68, 63, 58, 55, 52, 51, 53, 57, 62, 68, 73, 77, 80, 81, 82],
  soilTemperature: [22.4, 22.1, 21.8, 21.6, 21.5, 21.6, 21.9, 22.6, 23.8, 25.1, 26.4, 27.2, 27.8, 28.1, 27.9, 27.2, 26.3, 25.2, 24.3, 23.7, 23.2, 22.9, 22.7, 22.5],
  soilMoisture: [52, 51, 50, 49, 49, 48, 48, 47, 46, 45, 44, 43, 42, 42, 41, 41, 42, 43, 45, 47, 49, 50, 51, 52],
  co2: [438, 442, 448, 452, 455, 458, 462, 468, 476, 486, 498, 510, 522, 530, 526, 516, 502, 488, 474, 462, 452, 446, 442, 439],
  light: [0, 0, 0, 0, 0, 0, 32, 420, 1250, 2480, 3860, 5020, 5860, 6080, 5720, 4860, 3720, 2380, 1160, 360, 60, 0, 0, 0],
  ph: [6.4, 6.4, 6.5, 6.5, 6.5, 6.5, 6.4, 6.4, 6.3, 6.3, 6.2, 6.2, 6.2, 6.3, 6.3, 6.4, 6.4, 6.4, 6.5, 6.5, 6.5, 6.4, 6.4, 6.4],
  waterTemperature: [18.2, 18.0, 17.8, 17.6, 17.6, 17.7, 18.0, 18.6, 19.8, 21.2, 22.4, 23.1, 23.8, 24.0, 23.9, 23.4, 22.8, 22.0, 21.2, 20.4, 19.6, 19.0, 18.7, 18.4],
}

export const waterElectric = {
  months: ['6月', '7月', '8月', '9月', '10月', '11月'],
  water: [3280, 4120, 4680, 3860, 2940, 1260],
  electric: [8620, 10840, 12260, 9860, 7540, 3120],
}

export const monthlyReport = [
  { month: '2026-06', water: 3280, electric: 8620, cost: 6420, alarms: 32, orders: 18 },
  { month: '2026-07', water: 4120, electric: 10840, cost: 8240, alarms: 41, orders: 24 },
  { month: '2026-08', water: 4680, electric: 12260, cost: 9360, alarms: 38, orders: 26 },
  { month: '2026-09', water: 3860, electric: 9860, cost: 7560, alarms: 27, orders: 21 },
  { month: '2026-10', water: 2940, electric: 7540, cost: 5840, alarms: 19, orders: 17 },
  { month: '2026-11', water: 1260, electric: 3120, cost: 2460, alarms: 8, orders: 9 },
]

export const traceTimeline = [
  { date: '2026-07-26', title: '定植移栽', desc: '3 号黄瓜棚完成津优 35 定植，株距 30 cm，共定植 2,400 株。' },
  { date: '2026-08-10', title: '水肥一体化', desc: '施用复合肥 15-15-15 共 18 kg，滴灌时长 45 分钟，EC 2.1 mS/cm。' },
  { date: '2026-08-24', title: '植株调整', desc: '吊蔓、落蔓作业，清除下部老叶，保持通风透光。' },
  { date: '2026-09-15', title: '生物防治', desc: '释放捕食螨防治红蜘蛛，悬挂黄板 40 张，未使用化学农药。' },
  { date: '2026-10-20', title: '环境监测', desc: '连续 7 天棚内温度 24-31℃，湿度 60%-75%，土壤湿度稳定在 45%。' },
  { date: '2026-11-05', title: '采收分级', desc: '采收黄瓜 1,260 kg，按一级果标准分筐，同步赋码 1,260 枚。' },
  { date: '2026-11-05', title: '质量检测', desc: '重庆市农产品质量检测中心出具报告，农残未检出，综合判定合格。' },
]

export const traceDetail = {
  batchNo: 'B20261105-03',
  crop: '黄瓜',
  variety: '津优 35',
  origin: '重庆市璧山区现代农业园区 · 3号黄瓜棚',
  grade: '一级',
  weight: '1,260 kg',
  harvestedAt: '2026-11-05',
  farmer: '陈刚',
  plot: 'P-03',
  scans: 386,
  inspect: {
    reportNo: 'CQ-JC-20261105-031',
    agency: '重庆市农产品质量检测中心',
    testedAt: '2026-11-05',
    pesticide: '未检出',
    heavyMetal: '合格',
    conclusion: '合格',
  },
}

export const qualityOverview = {
  passRate: 98.6,
  inspectedBatches: 72,
  qualified: 71,
  unqualified: 1,
  recalls: 3,
  pesticideChecks: 126,
  trend: [96.8, 97.2, 97.9, 98.1, 98.4, 98.6],
  categories: [
    { name: '蔬菜', batches: 38, passRate: 97.4 },
    { name: '水果', batches: 22, passRate: 100 },
    { name: '粮油', batches: 8, passRate: 100 },
    { name: '经济作物', batches: 4, passRate: 100 },
  ],
}

export const pesticideLedger = [
  { id: 'PL-01', date: '2026-11-02', plot: 'P-04', crop: '柑橘', name: '生物杀虫剂苏云金杆菌', amount: '2.4 L', operator: '周涛', method: '叶面喷施', safetyDays: 7, compliant: true },
  { id: 'PL-02', date: '2026-10-28', plot: 'P-01', crop: '番茄', name: '枯草芽孢杆菌', amount: '1.8 kg', operator: '王强', method: '灌根', safetyDays: 3, compliant: true },
  { id: 'PL-03', date: '2026-10-22', plot: 'P-03', crop: '黄瓜', name: '吡虫啉', amount: '0.6 kg', operator: '陈刚', method: '叶面喷施', safetyDays: 14, compliant: false, note: '施药后 9 天即采收，未满足安全间隔期' },
  { id: 'PL-04', date: '2026-10-18', plot: 'P-02', crop: '草莓', name: '多菌灵', amount: '0.9 kg', operator: '赵敏', method: '叶面喷施', safetyDays: 10, compliant: true },
  { id: 'PL-05', date: '2026-10-12', plot: 'P-05', crop: '水稻', name: '稻瘟灵', amount: '3.2 L', operator: '刘洋', method: '无人机喷施', safetyDays: 21, compliant: true },
  { id: 'PL-06', date: '2026-10-05', plot: 'P-04', crop: '柑橘', name: '矿物油', amount: '5.0 L', operator: '周涛', method: '全园喷雾', safetyDays: 5, compliant: true },
]

export const sysInfo = {
  version: 'v2.4.0',
  env: '生产环境',
  db: 'MySQL 8.0.36',
  api: 'Spring Boot 3.2',
  uptime: '128 天 06 小时',
  cpu: 38,
  memory: 62,
  disk: 47,
  onlineUsers: 86,
  mqttMessages: 1286420,
  apiCalls: 286412,
}

export function findPlot(id: string): Plot | undefined {
  return plots.find((item) => item.id === id)
}

export function plotName(id: string): string {
  return findPlot(id)?.name ?? id
}
