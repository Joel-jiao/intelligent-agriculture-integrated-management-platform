<script setup lang="ts">
import { computed, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import LineChart from '@/components/ui/LineChart.vue'
import { useToast } from '@/composables/useToast'
import { operationLogs, sysInfo } from '@/data/mock'
import { buildCsv, downloadText, formatNumber, nowDateTime } from '@/utils/format'

const toast = useToast()

interface ServiceItem {
  name: string
  desc: string
  port: number
  version: string
  uptime: string
  latency: number
  status: '运行中' | '告警'
}

const services = ref<ServiceItem[]>([
  { name: 'API 服务', desc: 'Spring Boot 业务接口', port: 8080, version: '3.2.4', uptime: '128 天', latency: 42, status: '运行中' },
  { name: 'MQTT Broker', desc: '设备消息接入与分发', port: 1883, version: 'EMQX 5.6', uptime: '128 天', latency: 8, status: '运行中' },
  { name: 'MySQL 数据库', desc: '业务主数据存储', port: 3306, version: '8.0.36', uptime: '96 天', latency: 6, status: '运行中' },
  { name: 'Redis 缓存', desc: '会话与热点数据缓存', port: 6379, version: '7.2.4', uptime: '96 天', latency: 3, status: '运行中' },
  { name: '文件存储', desc: '对象存储与附件服务', port: 9000, version: 'MinIO 2025', uptime: '64 天', latency: 18, status: '告警' },
])

const health = ref({ cpu: sysInfo.cpu, memory: sysInfo.memory, disk: sysInfo.disk })

const apiTrend = {
  labels: ['10-31', '11-01', '11-02', '11-03', '11-04', '11-05', '11-06'],
  series: [{ name: '接口调用次数', color: '#157a8c', data: [24680, 25940, 27120, 26860, 28410, 27950, 29180] }],
}

const healthStats = computed(() => [
  { label: 'CPU 使用率', value: health.value.cpu, danger: health.value.cpu >= 80 },
  { label: '内存使用率', value: health.value.memory, danger: health.value.memory >= 80 },
  { label: '磁盘使用率', value: health.value.disk, danger: health.value.disk >= 80 },
])

const pendingTasks = ref([
  { id: 'T-01', title: '文件存储节点延迟偏高，需检查对象存储网关', level: '重要', done: false },
  { id: 'T-02', title: '核对本月自动备份文件完整性', level: '一般', done: false },
  { id: 'T-03', title: '更新 MQTT Broker 访问白名单', level: '一般', done: false },
  { id: 'T-04', title: '清理 30 天前的登录日志归档', level: '一般', done: true },
])

const recentLogs = computed(() => operationLogs.slice(0, 5))
const undoneCount = computed(() => pendingTasks.value.filter((item) => !item.done).length)

function refresh() {
  health.value.cpu = Math.min(92, Math.max(12, health.value.cpu + Math.round((Math.random() - 0.5) * 6)))
  health.value.memory = Math.min(92, Math.max(30, health.value.memory + Math.round((Math.random() - 0.5) * 4)))
  health.value.disk = Math.min(95, Math.max(20, health.value.disk + Math.round((Math.random() - 0.5) * 2)))
  toast.success(`系统健康指标已刷新 · ${nowDateTime()}`)
}

function restartService(service: ServiceItem) {
  service.status = '运行中'
  toast.success(`${service.name} 已平滑重启，端口 ${service.port} 恢复监听`)
}

function finishTask(id: string) {
  const task = pendingTasks.value.find((item) => item.id === id)
  if (!task) return
  task.done = true
  toast.success(`运维事项「${task.title}」已标记完成`)
}

function exportServices() {
  const rows = services.value.map((item) => [item.name, item.desc, item.port, item.version, item.status, item.uptime, `${item.latency}ms`])
  downloadText('运维服务巡检表_20261106.csv', buildCsv(['服务名称', '说明', '端口', '版本', '状态', '运行时长', '延迟'], rows))
  toast.success('服务巡检表已导出为 CSV 文件')
}
</script>

<template>
  <div>
    <PageHeader eyebrow="OPS WORKBENCH" title="运维工作台" description="系统健康、服务运行、接口流量与运维待办一屏总览 · 最近刷新 2026-11-06 09:42">
      <template #actions>
        <button class="btn" type="button" @click="refresh">刷新指标</button>
        <RouterLink class="btn" to="/ops/backup">备份恢复</RouterLink>
        <button class="btn btn--primary" type="button" @click="exportServices">导出巡检表</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="系统健康度" :value="92" unit="%" icon="健" note="5 项服务 · 4 运行正常" trend="较昨日 +1" trend-up />
      <StatCard label="在线用户" :value="sysInfo.onlineUsers" unit="人" icon="用" note="管理员端 2 · 运维端 1" trend="会话正常" />
      <StatCard label="MQTT 消息累计" :value="formatNumber(sysInfo.mqttMessages)" unit="条" icon="联" note="今日新增 12,860 条" trend="+3.2% 环比" trend-up />
      <StatCard label="接口调用累计" :value="formatNumber(sysInfo.apiCalls)" unit="次" icon="接" note="平均响应 42 ms" trend="成功率 99.2%" accent />
    </div>

    <div class="grid grid--main">
      <div class="stack">
        <section class="card">
          <div class="card__head">
            <div class="card__title">系统健康统计 <span class="card__sub">{{ sysInfo.env }} · {{ sysInfo.uptime }}</span></div>
            <span class="tag tag--ok">运行平稳</span>
          </div>
          <div class="card__body health">
            <div v-for="item in healthStats" :key="item.label" class="health__row">
              <span class="health__label">{{ item.label }}</span>
              <div class="progress">
                <div class="progress__bar" :class="{ 'progress__bar--warn': item.danger }" :style="{ width: `${item.value}%` }" />
              </div>
              <b>{{ item.value }}%</b>
            </div>
            <div class="kv kv--3" style="margin-top: 4px">
              <div class="kv__item"><span>节点</span><b>agri-prod-01</b></div>
              <div class="kv__item"><span>运行时长</span><b>{{ sysInfo.uptime }}</b></div>
              <div class="kv__item"><span>内核版本</span><b>Linux 6.8</b></div>
            </div>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">服务运行状态 <span class="card__sub">共 5 个核心服务</span></div>
            <RouterLink class="link-action" to="/ops/logs/operation">查看操作审计</RouterLink>
          </div>
          <div class="table-wrap" style="border: 0; border-radius: 0 0 14px 14px">
            <table class="data-table">
              <thead>
                <tr>
                  <th>服务</th>
                  <th>说明</th>
                  <th>端口</th>
                  <th>版本</th>
                  <th>运行时长</th>
                  <th>延迟</th>
                  <th>状态</th>
                  <th>操作</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="service in services" :key="service.name">
                  <td class="cell-strong">{{ service.name }}</td>
                  <td class="cell-muted">{{ service.desc }}</td>
                  <td class="num">{{ service.port }}</td>
                  <td>{{ service.version }}</td>
                  <td>{{ service.uptime }}</td>
                  <td class="num">{{ service.latency }} ms</td>
                  <td>
                    <StatusTag :text="service.status" :tone="service.status === '运行中' ? 'ok' : 'warn'" dot />
                  </td>
                  <td>
                    <button class="link-action" type="button" @click="restartService(service)">重启</button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">近 7 日接口调用 <span class="card__sub">单位：次</span></div>
            <span class="tag tag--brand">日均 27,905 次</span>
          </div>
          <div class="card__body">
            <LineChart :labels="apiTrend.labels" :series="apiTrend.series" :height="216" unit=" 次" />
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">最近操作日志</div>
            <RouterLink class="link-action" to="/ops/logs/operation">全部日志</RouterLink>
          </div>
          <div class="table-wrap" style="border: 0; border-radius: 0 0 14px 14px">
            <table class="data-table">
              <thead>
                <tr>
                  <th>时间</th>
                  <th>操作人</th>
                  <th>动作</th>
                  <th>模块</th>
                  <th>结果</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="log in recentLogs" :key="log.id">
                  <td class="num">{{ log.time }}</td>
                  <td>{{ log.name }}<span class="cell-muted"> · {{ log.account }}</span></td>
                  <td>{{ log.action }}</td>
                  <td><span class="tag">{{ log.module }}</span></td>
                  <td><StatusTag :text="log.result" :tone="log.result === '成功' ? 'ok' : 'danger'" dot /></td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>
      </div>

      <div class="stack">
        <section class="card">
          <div class="card__head">
            <div class="card__title">快捷入口</div>
          </div>
          <div class="card__body entry-grid">
            <RouterLink v-for="entry in [
              { to: '/ops/users', mark: '用', name: '用户管理', desc: '账号启停与权限归属' },
              { to: '/ops/roles', mark: '角', name: '角色权限', desc: 'RBAC 权限矩阵配置' },
              { to: '/ops/devices', mark: '接', name: '设备接入', desc: '网关与协议参数' },
              { to: '/ops/backup', mark: '备', name: '备份恢复', desc: '数据库全量备份' },
              { to: '/ops/openapi', mark: '接', name: '接口配置', desc: '第三方接口与密钥' },
              { to: '/ops/files', mark: '文', name: '文件存储', desc: '附件与配额管理' },
            ]" :key="entry.to" class="entry" :to="entry.to">
              <span class="entry__mark">{{ entry.mark }}</span>
              <b>{{ entry.name }}</b>
              <small>{{ entry.desc }}</small>
            </RouterLink>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">待处理运维事项 <span class="card__sub">{{ undoneCount }} 项待办</span></div>
            <span class="tag" :class="undoneCount > 0 ? 'tag--warn' : 'tag--ok'">{{ undoneCount > 0 ? '有未完成项' : '全部完成' }}</span>
          </div>
          <div class="card__body">
            <div v-for="task in pendingTasks" :key="task.id" class="todo-row">
              <span class="tag" :class="task.level === '重要' ? 'tag--warn' : 'tag--info'">{{ task.level }}</span>
              <span class="todo-row__title" :class="{ 'todo-row__title--done': task.done }">{{ task.title }}</span>
              <button v-if="!task.done" class="link-action" type="button" @click="finishTask(task.id)">完成</button>
              <span v-else class="tag tag--ok">已完成</span>
            </div>
          </div>
        </section>

        <section class="card card--tint">
          <div class="card__head">
            <div class="card__title">系统版本信息</div>
            <span class="tag tag--brand">{{ sysInfo.version }}</span>
          </div>
          <div class="card__body">
            <div class="kv">
              <div class="kv__item"><span>部署环境</span><b>{{ sysInfo.env }}</b></div>
              <div class="kv__item"><span>数据库</span><b>{{ sysInfo.db }}</b></div>
              <div class="kv__item"><span>后端框架</span><b>{{ sysInfo.api }}</b></div>
              <div class="kv__item"><span>前端框架</span><b>Vue 3.5 + Vite</b></div>
              <div class="kv__item"><span>连续运行</span><b>{{ sysInfo.uptime }}</b></div>
              <div class="kv__item"><span>最近部署</span><b>2026-10-31 22:10</b></div>
            </div>
            <div class="notice notice--brand" style="margin-top: 14px">
              <span>当前为生产环境，所有变更操作将写入操作审计日志，请谨慎执行。</span>
            </div>
          </div>
        </section>
      </div>
    </div>
  </div>
</template>

<style scoped>
.health {
  display: grid;
  gap: 13px;
}

.health__row {
  display: flex;
  align-items: center;
  gap: 12px;
  font-size: 12px;
  color: var(--ink-2);
}

.health__label {
  width: 92px;
  color: var(--muted);
}

.health__row .progress {
  flex: 1;
}

.health__row b {
  width: 44px;
  text-align: right;
  font-family: var(--font-num);
}

.entry-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
}

.entry {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  gap: 2px;
  padding: 12px;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: var(--surface-2);
  transition: 0.18s;
}

.entry:hover {
  border-color: var(--brand);
  background: var(--brand-softer);
}

.entry__mark {
  display: grid;
  place-items: center;
  width: 26px;
  height: 26px;
  margin-bottom: 4px;
  border-radius: 8px;
  background: var(--brand-soft);
  color: var(--brand);
  font-size: 12px;
  font-weight: 700;
}

.entry b {
  font-size: 12.5px;
  color: var(--ink);
}

.entry small {
  font-size: 10.5px;
  color: var(--faint);
}

.todo-row {
  display: flex;
  align-items: center;
  gap: 9px;
  padding: 9px 0;
  border-bottom: 1px dashed var(--line);
  font-size: 12px;
}

.todo-row:last-child {
  border-bottom: 0;
}

.todo-row__title {
  flex: 1;
  min-width: 0;
  color: var(--ink-2);
  line-height: 1.5;
}

.todo-row__title--done {
  color: var(--faint);
  text-decoration: line-through;
}
</style>
