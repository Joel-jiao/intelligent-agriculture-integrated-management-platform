export interface MenuItem {
  label: string
  to: string
  icon: string
}

export interface MenuGroup {
  title: string
  items: MenuItem[]
}

export const adminMenu: MenuGroup[] = [
  {
    title: '总览',
    items: [{ label: '综合数据看板', to: '/dashboard', icon: '概' }],
  },
  {
    title: '物联网感知',
    items: [
      { label: '环境数据监测', to: '/iot/env', icon: '环' },
      { label: '设备状态监控', to: '/iot/devices', icon: '设' },
      { label: '视频监控', to: '/iot/video', icon: '视' },
      { label: '水电计量统计', to: '/iot/water-elec', icon: '水' },
    ],
  },
  {
    title: '远程控制',
    items: [
      { label: '设备远程控制', to: '/control/device', icon: '控' },
      { label: '自动联动策略', to: '/control/linkage', icon: '联' },
    ],
  },
  {
    title: '生产农事',
    items: [
      { label: 'GIS 地块档案', to: '/farm/plots', icon: '地' },
      { label: '农事工单管理', to: '/farm/work-orders', icon: '工' },
      { label: '农资库存管理', to: '/farm/materials', icon: '资' },
      { label: '采收登记', to: '/farm/harvest', icon: '收' },
    ],
  },
  {
    title: '质量溯源',
    items: [
      { label: '溯源批次档案', to: '/trace/batches', icon: '批' },
      { label: '溯源码生成', to: '/trace/qrcode', icon: '码' },
      { label: '检测报告管理', to: '/trace/inspections', icon: '检' },
      { label: '产品召回登记', to: '/trace/recalls', icon: '召' },
    ],
  },
  {
    title: '分析与告警',
    items: [
      { label: 'GIS 综合地图', to: '/gis', icon: '图' },
      { label: '告警信息处理', to: '/alarms', icon: '警' },
      { label: '综合报表导出', to: '/reports', icon: '报' },
      { label: '指挥中心大屏', to: '/screen', icon: '屏' },
    ],
  },
  {
    title: '账号',
    items: [{ label: '个人信息设置', to: '/profile', icon: '我' }],
  },
]

export const opsMenu: MenuGroup[] = [
  {
    title: '总览',
    items: [{ label: '运维工作台', to: '/ops/workbench', icon: '台' }],
  },
  {
    title: '用户与权限',
    items: [
      { label: '系统用户管理', to: '/ops/users', icon: '用' },
      { label: '角色权限配置', to: '/ops/roles', icon: '角' },
    ],
  },
  {
    title: '设备与系统',
    items: [
      { label: '设备接入管理', to: '/ops/devices', icon: '接' },
      { label: '系统数据字典', to: '/ops/dict', icon: '典' },
      { label: '第三方接口管理', to: '/ops/openapi', icon: '接' },
      { label: '文件存储管理', to: '/ops/files', icon: '文' },
    ],
  },
  {
    title: '日志与安全',
    items: [
      { label: '登录日志', to: '/ops/logs/login', icon: '登' },
      { label: '操作审计日志', to: '/ops/logs/operation', icon: '审' },
      { label: '数据库备份恢复', to: '/ops/backup', icon: '备' },
    ],
  },
  {
    title: '账号',
    items: [{ label: '运维个人设置', to: '/ops/profile', icon: '我' }],
  },
]

export const supMenu: MenuGroup[] = [
  {
    title: '总览',
    items: [{ label: '监管数据总览', to: '/sup/overview', icon: '总' }],
  },
  {
    title: '质量与台账',
    items: [
      { label: '辖区质量安全', to: '/sup/quality', icon: '质' },
      { label: '农产品溯源查询', to: '/sup/trace', icon: '溯' },
      { label: '农药农资台账', to: '/sup/pesticide', icon: '药' },
    ],
  },
  {
    title: '预警与报表',
    items: [
      { label: '监管预警管理', to: '/sup/warnings', icon: '警' },
      { label: '监管报表导出', to: '/sup/reports', icon: '报' },
    ],
  },
  {
    title: '账号',
    items: [{ label: '监管账号设置', to: '/sup/profile', icon: '我' }],
  },
]

export const mobileTabs: MenuItem[] = [
  { label: '首页', to: '/app/home', icon: '家' },
  { label: '任务', to: '/app/tasks', icon: '务' },
  { label: '消息', to: '/app/messages', icon: '信' },
  { label: '我的', to: '/app/mine', icon: '我' },
]
