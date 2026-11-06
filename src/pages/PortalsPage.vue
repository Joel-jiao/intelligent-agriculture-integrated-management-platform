<script setup lang="ts">
import { park, plots, sysInfo, traceDetail } from '@/data/mock'

const entries = [
  {
    mark: '管',
    name: '管理员端',
    role: '园区业务管理员',
    desc: '数据看板、设备控制、农事工单、质量溯源与报表统计',
    path: '/login',
    color: '#2f8f5b',
    modules: ['物联网监测', '远程控制', '生产管理', '溯源管理', 'GIS 分析'],
  },
  {
    mark: '运',
    name: '运维端',
    role: '系统运维人员',
    desc: '用户权限、设备接入、系统参数、日志审计与数据备份',
    path: '/ops/login',
    color: '#157a8c',
    modules: ['用户管理', '角色权限', '设备接入', '日志审计', '备份恢复'],
  },
  {
    mark: '监',
    name: '监管端',
    role: '政府农业监管部门',
    desc: '辖区质量安全数据、溯源台账、农药使用记录与监管预警',
    path: '/sup/login',
    color: '#2f5fa8',
    modules: ['质量总览', '溯源查询', '农药台账', '异常预警', '监管报表'],
  },
  {
    mark: '农',
    name: '农户移动端',
    role: '一线生产作业人员',
    desc: '接收农事任务、现场打卡、上传照片、记录工时物料与接收告警',
    path: '/app/login',
    color: '#4fae74',
    modules: ['任务列表', '现场打卡', '环境查看', '设备控制', '扫码录入'],
  },
  {
    mark: '溯',
    name: '溯源 H5',
    role: '普通消费者',
    desc: '微信扫码直接访问，无需登录即可查看产地、农事记录与检测报告',
    path: `/trace/h5/${traceDetail.batchNo}`,
    color: '#b8862f',
    modules: ['产地信息', '生长过程', '检测报告', '批次档案'],
  },
  {
    mark: '屏',
    name: '指挥中心大屏',
    role: '园区管理者',
    desc: '深色可视化大屏，园区态势、环境、设备与告警一屏集中展示',
    path: '/screen',
    color: '#0e7490',
    modules: ['综合态势', '环境监测', '设备状态', '告警动态', '进度看板'],
  },
]
</script>

<template>
  <div class="portals-page">
    <header class="portals-head">
      <div class="portals-head__brand">
        <div class="sidebar__mark" style="color: #0f3d26">农</div>
        <div>
          <strong>{{ park.name }}</strong>
          <span>INTELLIGENT AGRICULTURE PLATFORM</span>
        </div>
      </div>
      <div class="portals-head__meta">
        <span>{{ sysInfo.version }} · {{ sysInfo.env }}</span>
        <span>演示入口</span>
      </div>
    </header>

    <main class="portals-main">
      <div class="portals-hero">
        <div class="page-head__eyebrow" style="color: #b5ecc7">PLATFORM ENTRY</div>
        <h1>智慧农业综合管理平台</h1>
        <p>物联网感知 · 远程控制 · 生产农事 · 质量溯源 · GIS 分析 · 监管服务</p>
        <div class="portals-hero__stats">
          <div><b>{{ park.area }}</b><span>亩种植面积</span></div>
          <div><b>{{ plots.length }}</b><span>个管理地块</span></div>
          <div><b>4</b><span>类业务角色</span></div>
          <div><b>52</b><span>个功能页面</span></div>
        </div>
      </div>

      <div class="portals-grid">
        <RouterLink v-for="item in entries" :key="item.path" :to="item.path" class="portal-card">
          <div class="portal-card__top">
            <div class="portal-card__mark" :style="{ background: item.color }">{{ item.mark }}</div>
            <div>
              <h2>{{ item.name }}</h2>
              <span>{{ item.role }}</span>
            </div>
            <span class="portal-card__arrow">→</span>
          </div>
          <p>{{ item.desc }}</p>
          <div class="portal-card__tags">
            <span v-for="module in item.modules" :key="module">{{ module }}</span>
          </div>
        </RouterLink>
      </div>

      <div class="portals-note">
        <span>数据说明：</span>本演示使用本地 Mock 数据模拟真实业务，所有操作均为前端交互演示，刷新页面后数据会恢复初始状态。
      </div>
    </main>

    <footer class="portals-foot">
      智慧农业综合管理平台 · 重庆工程学院 人工智能与计算机学院 · 24计科2班 · 吴鸿宇 · 2026.11
    </footer>
  </div>
</template>

<style scoped>
.portals-page {
  min-height: 100vh;
  color: #eaf6ee;
  background:
    radial-gradient(900px 500px at 12% 0%, rgba(90, 200, 140, 0.24), transparent 62%),
    radial-gradient(700px 500px at 95% 90%, rgba(184, 134, 47, 0.16), transparent 60%),
    linear-gradient(150deg, #0b3220, #0a2a1b 55%, #061a10);
  padding: 0 24px;
}

.portals-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  max-width: 1180px;
  margin: 0 auto;
  padding: 22px 0;
  border-bottom: 1px solid rgba(255, 255, 255, 0.09);
}

.portals-head__brand {
  display: flex;
  align-items: center;
  gap: 11px;
}

.portals-head__brand strong {
  display: block;
  font-size: 15px;
  color: #fff;
}

.portals-head__brand span {
  font-size: 10px;
  letter-spacing: 1.6px;
  color: rgba(234, 246, 238, 0.5);
}

.portals-head__meta {
  display: flex;
  gap: 14px;
  font-size: 11px;
  color: rgba(234, 246, 238, 0.55);
}

.portals-main {
  max-width: 1180px;
  margin: 0 auto;
  padding: 56px 0 40px;
}

.portals-hero h1 {
  font-size: 38px;
  font-weight: 780;
  letter-spacing: -0.8px;
  color: #fff;
}

.portals-hero p {
  margin-top: 8px;
  font-size: 13px;
  letter-spacing: 0.4px;
  color: rgba(234, 246, 238, 0.62);
}

.portals-hero__stats {
  display: flex;
  gap: 34px;
  margin-top: 30px;
  flex-wrap: wrap;
}

.portals-hero__stats div {
  display: flex;
  align-items: baseline;
  gap: 8px;
}

.portals-hero__stats b {
  font-size: 26px;
  color: #b5ecc7;
  font-variant-numeric: tabular-nums;
}

.portals-hero__stats span {
  font-size: 11.5px;
  color: rgba(234, 246, 238, 0.5);
}

.portals-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 16px;
  margin-top: 42px;
}

.portal-card {
  display: flex;
  flex-direction: column;
  padding: 20px 20px 18px;
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: 16px;
  background: rgba(255, 255, 255, 0.055);
  backdrop-filter: blur(8px);
  transition: 0.22s;
}

.portal-card:hover {
  border-color: rgba(181, 236, 199, 0.45);
  background: rgba(255, 255, 255, 0.09);
  transform: translateY(-3px);
  box-shadow: 0 18px 40px rgba(0, 0, 0, 0.22);
}

.portal-card__top {
  display: flex;
  align-items: center;
  gap: 11px;
}

.portal-card__mark {
  display: grid;
  place-items: center;
  width: 40px;
  height: 40px;
  border-radius: 11px;
  color: #fff;
  font-size: 17px;
  font-weight: 800;
}

.portal-card__top h2 {
  font-size: 15px;
  font-weight: 650;
  color: #fff;
}

.portal-card__top span {
  font-size: 10.5px;
  color: rgba(234, 246, 238, 0.5);
}

.portal-card__arrow {
  margin-left: auto;
  font-size: 16px;
  color: rgba(181, 236, 199, 0.6);
  transition: 0.2s;
}

.portal-card:hover .portal-card__arrow {
  color: #b5ecc7;
  transform: translateX(3px);
}

.portal-card p {
  margin-top: 14px;
  min-height: 42px;
  font-size: 11.5px;
  line-height: 1.75;
  color: rgba(234, 246, 238, 0.6);
}

.portal-card__tags {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-top: 14px;
}

.portal-card__tags span {
  padding: 3px 8px;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.07);
  font-size: 10px;
  color: rgba(234, 246, 238, 0.62);
}

.portals-note {
  margin-top: 28px;
  padding: 13px 16px;
  border-radius: 10px;
  border: 1px dashed rgba(255, 255, 255, 0.16);
  font-size: 11.5px;
  color: rgba(234, 246, 238, 0.5);
}

.portals-note span {
  color: #b5ecc7;
}

.portals-foot {
  max-width: 1180px;
  margin: 0 auto;
  padding: 20px 0 28px;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
  text-align: center;
  font-size: 10.5px;
  color: rgba(234, 246, 238, 0.35);
}

@media (max-width: 960px) {
  .portals-grid {
    grid-template-columns: repeat(2, minmax(0, 1fr));
  }

  .portals-hero h1 {
    font-size: 28px;
  }
}

@media (max-width: 620px) {
  .portals-grid {
    grid-template-columns: 1fr;
  }

  .portals-head__meta {
    display: none;
  }
}
</style>
