<script setup lang="ts">
import { park, plots, sysInfo, traceDetail } from '@/api/store'

const entries = [
  {
    name: '管理员端',
    role: '园区业务管理员',
    desc: '数据看板、设备控制、农事工单、质量溯源与报表统计',
    path: '/login',
    color: '#007aff',
    modules: ['物联网监测', '远程控制', '生产管理', '溯源管理', 'GIS 分析'],
  },
  {
    name: '运维端',
    role: '系统运维人员',
    desc: '用户权限、设备接入、系统参数、日志审计与数据备份',
    path: '/ops/login',
    color: '#5e5ce6',
    modules: ['用户管理', '角色权限', '设备接入', '日志审计', '备份恢复'],
  },
  {
    name: '监管端',
    role: '政府农业监管部门',
    desc: '辖区质量安全数据、溯源台账、农药使用记录与监管预警',
    path: '/sup/login',
    color: '#0a84ff',
    modules: ['质量总览', '溯源查询', '农药台账', '异常预警', '监管报表'],
  },
  {
    name: '农户移动端',
    role: '一线生产作业人员',
    desc: '接收农事任务、现场打卡、上传照片、记录工时物料与接收告警',
    path: '/app/login',
    color: '#34c759',
    modules: ['任务列表', '现场打卡', '环境查看', '设备控制', '扫码录入'],
  },
  {
    name: '溯源 H5',
    role: '普通消费者',
    desc: '微信扫码直接访问，无需登录即可查看产地、农事记录与检测报告',
    path: `/trace/h5/${traceDetail.batchNo}`,
    color: '#ff9f0a',
    modules: ['产地信息', '生长过程', '检测报告', '批次档案'],
  },
  {
    name: '指挥中心大屏',
    role: '园区管理者',
    desc: '深色可视化大屏，园区态势、环境、设备与告警一屏集中展示',
    path: '/screen',
    color: '#334155',
    modules: ['综合态势', '环境监测', '设备状态', '告警动态', '进度看板'],
  },
]
</script>

<template>
  <div class="portals-page">
    <header class="portals-head">
      <div class="portals-head__brand">
        <div class="portals-head__mark">农</div>
        <div>
          <strong>{{ park.name }}</strong>
          <span>INTELLIGENT AGRICULTURE PLATFORM</span>
        </div>
      </div>
      <div class="portals-head__meta">
        <span>{{ sysInfo.version }} · {{ sysInfo.env }}</span>
      </div>
    </header>

    <main class="portals-main">
      <div class="portals-hero">
        <h1>智慧农业综合管理平台</h1>
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
            <div>
              <h1>{{ item.name }}</h1>
              <span>{{ item.role }}</span>
            </div>
          </div>
          <p>{{ item.desc }}</p>
          <div class="portal-card__tags">
            <span v-for="module in item.modules" :key="module">{{ module }}</span>
          </div>
        </RouterLink>
      </div>

    </main>

    <footer class="portals-foot">
      智慧农业综合管理平台 · 重庆工程学院 人工智能与计算机学院 · 24计科2班 · 吴鸿宇 · 2026.11
    </footer>
  </div>
</template>

<style scoped>
.portals-page {
  position: relative;
  min-height: 100vh;
  padding: 0 24px;
  background: var(--bg-page);
  overflow: hidden;
}

/* 与登录页一致的柔和弥散渐变 */
.portals-page::before,
.portals-page::after {
  content: "";
  position: absolute;
  border-radius: 50%;
  filter: blur(110px);
  opacity: 0.4;
  pointer-events: none;
}

.portals-page::before {
  top: -12%;
  left: -8%;
  width: 52vw;
  height: 52vw;
  background: rgba(0, 122, 255, 0.22);
}

.portals-page::after {
  right: -10%;
  bottom: -16%;
  width: 46vw;
  height: 46vw;
  background: rgba(52, 199, 89, 0.14);
}

.portals-head {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  justify-content: space-between;
  max-width: 1180px;
  margin: 0 auto;
  padding: 22px 0;
  border-bottom: 1px solid var(--border-card);
}

.portals-head__brand {
  display: flex;
  align-items: center;
  gap: 11px;
}

.portals-head__mark {
  display: grid;
  place-items: center;
  width: 40px;
  height: 40px;
  border-radius: 12px;
  background: var(--primary);
  color: #fff;
  font-size: 18px;
  font-weight: 700;
  box-shadow: 0 8px 18px -8px rgba(0, 122, 255, 0.55);
}

.portals-head__brand strong {
  display: block;
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
}

.portals-head__brand span {
  font-size: 10px;
  letter-spacing: 1.6px;
  color: var(--text-tertiary);
}

.portals-head__meta {
  display: flex;
  gap: 14px;
  font-size: 11px;
  color: var(--text-secondary);
}

.portals-main {
  position: relative;
  z-index: 1;
  max-width: 1180px;
  margin: 0 auto;
  padding: 56px 0 40px;
}

.portals-hero h1 {
  margin-top: 6px;
  font-size: 38px;
  font-weight: 700;
  letter-spacing: -0.8px;
  color: var(--text-primary);
}

.portals-hero p {
  margin-top: 8px;
  font-size: 13px;
  letter-spacing: 0.4px;
  color: var(--text-secondary);
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
  color: var(--primary);
  font-variant-numeric: tabular-nums;
}

.portals-hero__stats span {
  font-size: 11.5px;
  color: var(--text-secondary);
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
  border: 1px solid var(--border-card);
  border-radius: var(--radius-card);
  background: var(--bg-card);
  backdrop-filter: blur(14px);
  transition: 0.22s var(--ease);
}

.portal-card:hover {
  border-color: var(--primary);
  transform: translateY(-3px);
  box-shadow: var(--shadow-float);
}

.portal-card__top {
  display: flex;
  align-items: center;
  gap: 11px;
}

.portal-card__top h2 {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
}

.portal-card__top span {
  font-size: 10.5px;
  color: var(--text-secondary);
}

.portal-card:hover .portal-card__arrow {
  color: var(--primary);
  transform: translateX(3px);
}

.portal-card p {
  margin-top: 14px;
  min-height: 42px;
  font-size: 11.5px;
  line-height: 1.75;
  color: var(--text-secondary);
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
  background: var(--bg-subtle-2);
  font-size: 10px;
  color: var(--text-secondary);
}

.portals-note {
  margin-top: 28px;
  padding: 13px 16px;
  border-radius: 10px;
  border: 1px dashed var(--border-strong);
  font-size: 11.5px;
  color: var(--text-secondary);
}

.portals-note span {
  color: var(--primary);
}

.portals-foot {
  position: relative;
  z-index: 1;
  max-width: 1180px;
  margin: 0 auto;
  padding: 20px 0 28px;
  border-top: 1px solid var(--border-card);
  text-align: center;
  font-size: 10.5px;
  color: var(--text-tertiary);
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
