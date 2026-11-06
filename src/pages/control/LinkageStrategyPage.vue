<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { plotName, plots } from '@/data/mock'
import { nowDateTime } from '@/utils/format'

const toast = useToast()

interface Strategy {
  id: string
  name: string
  plotId: string
  tempMin: number
  tempMax: number
  humidityMin: number
  humidityMax: number
  soilMin: number
  action: string
  window: string
  enabled: boolean
  lastTriggered: string
}

interface StrategyForm {
  name: string
  plotId: string
  tempMin: number
  tempMax: number
  humidityMin: number
  humidityMax: number
  soilMin: number
  action: string
  window: string
}

const actionOptions = [
  '启动环流风机',
  '关闭环流风机',
  '启动滴灌电磁阀',
  '关闭滴灌电磁阀',
  '展开外遮阳卷帘',
  '关闭外遮阳卷帘',
  '开启补光灯组',
  '关闭补光灯组',
]

const strategies = ref<Strategy[]>([
  {
    id: 'LS-01',
    name: '高温自动通风',
    plotId: 'P-01',
    tempMin: 18,
    tempMax: 30,
    humidityMin: 55,
    humidityMax: 85,
    soilMin: 45,
    action: '启动环流风机',
    window: '08:00-18:00',
    enabled: true,
    lastTriggered: '2026-11-06 13:20',
  },
  {
    id: 'LS-02',
    name: '夜间低温保温',
    plotId: 'P-02',
    tempMin: 16,
    tempMax: 28,
    humidityMin: 60,
    humidityMax: 85,
    soilMin: 50,
    action: '关闭外遮阳卷帘',
    window: '18:00-08:00',
    enabled: true,
    lastTriggered: '2026-11-05 23:10',
  },
  {
    id: 'LS-03',
    name: '土壤干旱自动补灌',
    plotId: 'P-03',
    tempMin: 20,
    tempMax: 32,
    humidityMin: 50,
    humidityMax: 80,
    soilMin: 40,
    action: '启动滴灌电磁阀',
    window: '06:00-10:00',
    enabled: false,
    lastTriggered: '2026-11-04 07:05',
  },
  {
    id: 'LS-04',
    name: '高湿自动除湿',
    plotId: 'P-05',
    tempMin: 18,
    tempMax: 30,
    humidityMin: 60,
    humidityMax: 80,
    soilMin: 50,
    action: '启动环流风机',
    window: '00:00-24:00',
    enabled: true,
    lastTriggered: '2026-11-06 06:40',
  },
  {
    id: 'LS-05',
    name: '育苗期定时补光',
    plotId: 'P-06',
    tempMin: 22,
    tempMax: 28,
    humidityMin: 65,
    humidityMax: 85,
    soilMin: 55,
    action: '开启补光灯组',
    window: '16:00-22:00',
    enabled: true,
    lastTriggered: '2026-11-05 18:00',
  },
])

function conditionText(strategy: Strategy): string {
  return `温度 ${strategy.tempMin} - ${strategy.tempMax}℃ · 湿度 ${strategy.humidityMin} - ${strategy.humidityMax}% · 土壤湿度 < ${strategy.soilMin}%`
}

interface ExecLog {
  id: string
  time: string
  strategy: string
  detail: string
  result: '成功' | '失败'
}

const execLogs = ref<ExecLog[]>([
  { id: 'EL-01', time: '2026-11-06 13:20:08', strategy: '高温自动通风', detail: '1号棚温度 31.2℃，启动环流风机', result: '成功' },
  { id: 'EL-02', time: '2026-11-06 06:40:12', strategy: '高湿自动除湿', detail: 'B区稻田湿度 84%，启动环流风机', result: '成功' },
  { id: 'EL-03', time: '2026-11-05 23:10:40', strategy: '夜间低温保温', detail: '2号棚温度 15.4℃，关闭外遮阳卷帘', result: '成功' },
  { id: 'EL-04', time: '2026-11-05 18:00:05', strategy: '育苗期定时补光', detail: '进入补光时段，开启补光灯组', result: '成功' },
  { id: 'EL-05', time: '2026-11-04 07:05:22', strategy: '土壤干旱自动补灌', detail: '3号棚土壤湿度 38%，启动滴灌电磁阀', result: '失败' },
])

const enabledCount = computed(() => strategies.value.filter((item) => item.enabled).length)
const plotCoverage = computed(() => new Set(strategies.value.map((item) => item.plotId)).size)
const todayTriggerCount = computed(() => execLogs.value.filter((item) => item.time.startsWith('2026-11-06')).length)

function addLog(strategy: string, detail: string, result: '成功' | '失败' = '成功') {
  execLogs.value.unshift({
    id: `EL-${Date.now().toString().slice(-6)}`,
    time: nowDateTime(),
    strategy,
    detail,
    result,
  })
  if (execLogs.value.length > 12) {
    execLogs.value = execLogs.value.slice(0, 12)
  }
}

function toggleStrategy(strategy: Strategy) {
  strategy.enabled = !strategy.enabled
  if (strategy.enabled) {
    toast.success(`「${strategy.name}」已启用，条件满足时将自动执行`)
    addLog(strategy.name, '策略启用')
  } else {
    toast.warn(`「${strategy.name}」已停用，不再触发自动控制`)
    addLog(strategy.name, '策略停用')
  }
}

function defaultForm(): StrategyForm {
  return {
    name: '',
    plotId: 'P-01',
    tempMin: 18,
    tempMax: 30,
    humidityMin: 55,
    humidityMax: 85,
    soilMin: 45,
    action: '启动环流风机',
    window: '08:00-18:00',
  }
}

const form = reactive<StrategyForm>(defaultForm())
const formOpen = ref(false)
const editingId = ref<string | null>(null)

function openCreate() {
  Object.assign(form, defaultForm())
  editingId.value = null
  formOpen.value = true
}

function openEdit(strategy: Strategy) {
  Object.assign(form, {
    name: strategy.name,
    plotId: strategy.plotId,
    tempMin: strategy.tempMin,
    tempMax: strategy.tempMax,
    humidityMin: strategy.humidityMin,
    humidityMax: strategy.humidityMax,
    soilMin: strategy.soilMin,
    action: strategy.action,
    window: strategy.window,
  })
  editingId.value = strategy.id
  formOpen.value = true
}

function saveStrategy() {
  if (form.name.trim() === '') {
    toast.error('请填写策略名称')
    return
  }
  if (form.tempMax <= form.tempMin) {
    toast.error('温度上限必须大于温度下限')
    return
  }
  if (form.humidityMax <= form.humidityMin) {
    toast.error('湿度上限必须大于湿度下限')
    return
  }

  if (editingId.value) {
    const target = strategies.value.find((item) => item.id === editingId.value)
    if (target) {
      target.name = form.name.trim()
      target.plotId = form.plotId
      target.tempMin = form.tempMin
      target.tempMax = form.tempMax
      target.humidityMin = form.humidityMin
      target.humidityMax = form.humidityMax
      target.soilMin = form.soilMin
      target.action = form.action
      target.window = form.window
    }
    toast.success('联动策略已更新并同步至控制网关')
    addLog(form.name.trim(), '编辑策略阈值与执行动作')
  } else {
    strategies.value.unshift({
      id: `LS-${Date.now().toString().slice(-6)}`,
      name: form.name.trim(),
      plotId: form.plotId,
      tempMin: form.tempMin,
      tempMax: form.tempMax,
      humidityMin: form.humidityMin,
      humidityMax: form.humidityMax,
      soilMin: form.soilMin,
      action: form.action,
      window: form.window,
      enabled: true,
      lastTriggered: '—',
    })
    toast.success('新联动策略已创建并启用')
    addLog(form.name.trim(), '新建策略并启用')
  }

  formOpen.value = false
  editingId.value = null
}

const deleteOpen = ref(false)
const deleteTarget = ref<Strategy | null>(null)

function askDelete(strategy: Strategy) {
  deleteTarget.value = strategy
  deleteOpen.value = true
}

function confirmDelete() {
  const target = deleteTarget.value
  if (!target) return
  strategies.value = strategies.value.filter((item) => item.id !== target.id)
  deleteOpen.value = false
  deleteTarget.value = null
  toast.success(`策略「${target.name}」已删除`)
  addLog(target.name, '删除策略')
}

interface SceneTemplate {
  key: string
  name: string
  plotId: string
  tempMin: number
  tempMax: number
  humidityMin: number
  humidityMax: number
  soilMin: number
  action: string
  window: string
  desc: string
}

const sceneTemplates: SceneTemplate[] = [
  {
    key: 'seedling',
    name: '育苗期恒温补光',
    plotId: 'P-06',
    tempMin: 22,
    tempMax: 28,
    humidityMin: 65,
    humidityMax: 85,
    soilMin: 55,
    action: '开启补光灯组',
    window: '06:00-22:00',
    desc: '苗期保持温暖湿润，弱光时段自动补光，促进幼苗整齐生长。',
  },
  {
    key: 'flower',
    name: '开花期控湿通风',
    plotId: 'P-02',
    tempMin: 18,
    tempMax: 26,
    humidityMin: 55,
    humidityMax: 75,
    soilMin: 50,
    action: '启动环流风机',
    window: '08:00-18:00',
    desc: '开花期控制棚内湿度，降低病害风险，保持授粉环境稳定。',
  },
  {
    key: 'winter',
    name: '越冬期夜间保温',
    plotId: 'P-01',
    tempMin: 14,
    tempMax: 24,
    humidityMin: 50,
    humidityMax: 80,
    soilMin: 45,
    action: '关闭外遮阳卷帘',
    window: '18:00-08:00',
    desc: '夜间低温时段关闭卷帘并减少通风，防止冻害发生。',
  },
]

function applyTemplate(template: SceneTemplate) {
  strategies.value.unshift({
    id: `LS-${Date.now().toString().slice(-6)}`,
    name: template.name,
    plotId: template.plotId,
    tempMin: template.tempMin,
    tempMax: template.tempMax,
    humidityMin: template.humidityMin,
    humidityMax: template.humidityMax,
    soilMin: template.soilMin,
    action: template.action,
    window: template.window,
    enabled: true,
    lastTriggered: '—',
  })
  toast.success(`已应用「${template.name}」场景模板，新增策略 1 条`)
  addLog(template.name, '应用场景模板并启用')
}

function refreshStatus() {
  toast.info('联动策略状态已刷新，调度引擎运行正常')
}
</script>

<template>
  <div>
    <PageHeader
      eyebrow="CONTROL · LINKAGE"
      title="自动联动策略"
      description="基于环境阈值的设备自动联动规则 · 策略由边缘网关本地执行，断网仍可生效"
    >
      <template #actions>
        <button class="btn" type="button" @click="refreshStatus">刷新状态</button>
        <button class="btn btn--primary" type="button" @click="openCreate">新建策略</button>
      </template>
    </PageHeader>

    <div class="notice notice--brand" style="margin-bottom: 16px">
      联动策略按「触发条件 + 生效时段」判断，条件持续满足 5 分钟后下发执行动作；同一设备 10 分钟内仅执行一次，避免频繁启停。
    </div>

    <div class="stat-grid">
      <div class="stat">
        <div class="stat__top">
          <span class="stat__label">策略总数</span>
          <span class="stat__icon">策</span>
        </div>
        <div class="stat__value">{{ strategies.length }}<small>条</small></div>
        <div class="stat__foot"><span>覆盖 {{ plotCoverage }} 个地块</span></div>
      </div>
      <div class="stat">
        <div class="stat__top">
          <span class="stat__label">启用中</span>
          <span class="stat__icon">启</span>
        </div>
        <div class="stat__value">{{ enabledCount }}<small>条</small></div>
        <div class="stat__foot"><span class="stat__trend stat__trend--up">调度引擎运行正常</span></div>
      </div>
      <div class="stat">
        <div class="stat__top">
          <span class="stat__label">今日触发</span>
          <span class="stat__icon">触</span>
        </div>
        <div class="stat__value">{{ todayTriggerCount }}<small>次</small></div>
        <div class="stat__foot"><span>最近触发 {{ strategies[0]?.lastTriggered ?? '—' }}</span></div>
      </div>
      <div class="stat stat--accent">
        <div class="stat__top">
          <span class="stat__label">执行成功率</span>
          <span class="stat__icon">率</span>
        </div>
        <div class="stat__value">92<small>%</small></div>
        <div class="stat__foot"><span>近 7 日共执行 26 次</span></div>
      </div>
    </div>

    <section class="card">
      <div class="card__head">
        <div class="card__title">
          策略列表
          <span class="card__sub">阈值条件满足后自动执行</span>
        </div>
        <span class="tag tag--brand">{{ enabledCount }} / {{ strategies.length }} 启用</span>
      </div>
      <div class="table-wrap" style="border: 0; border-radius: 0">
        <table class="data-table">
          <thead>
            <tr>
              <th>策略名称</th>
              <th>地块</th>
              <th>触发条件</th>
              <th>执行动作</th>
              <th>生效时段</th>
              <th>启用</th>
              <th>最近触发</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="strategy in strategies" :key="strategy.id">
              <td>
                <div class="cell-strong">{{ strategy.name }}</div>
                <div class="cell-muted" style="font-size: 10.5px">{{ strategy.id }}</div>
              </td>
              <td>{{ plotName(strategy.plotId) }}</td>
              <td class="cell-muted">{{ conditionText(strategy) }}</td>
              <td>{{ strategy.action }}</td>
              <td class="num">{{ strategy.window }}</td>
              <td>
                <label class="switch">
                  <input type="checkbox" :checked="strategy.enabled" @change="toggleStrategy(strategy)" />
                  <span class="switch__track" />
                  <span style="font-size: 11px">{{ strategy.enabled ? '启用' : '停用' }}</span>
                </label>
              </td>
              <td class="num cell-muted">{{ strategy.lastTriggered }}</td>
              <td>
                <div class="table-actions">
                  <button class="btn btn--sm" type="button" @click="openEdit(strategy)">编辑</button>
                  <button class="btn btn--sm btn--danger" type="button" @click="askDelete(strategy)">删除</button>
                </div>
              </td>
            </tr>
            <tr v-if="strategies.length === 0">
              <td colspan="8"><div class="empty">暂无联动策略，可新建策略或应用场景模板</div></td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <div class="grid grid--main" style="margin-top: 16px">
      <section class="card">
        <div class="card__head">
          <div class="card__title">场景模板</div>
          <span class="tag tag--info">一键应用</span>
        </div>
        <div class="card__body template-grid">
          <div v-for="template in sceneTemplates" :key="template.key" class="template-card">
            <div class="row row--between">
              <b>{{ template.name }}</b>
              <span class="tag tag--brand">{{ plotName(template.plotId) }}</span>
            </div>
            <div class="template-card__desc">{{ template.desc }}</div>
            <div class="template-card__meta">
              {{ template.tempMin }} - {{ template.tempMax }}℃ · 湿度 {{ template.humidityMin }} - {{ template.humidityMax }}%
            </div>
            <button class="btn btn--sm btn--full" type="button" @click="applyTemplate(template)">应用模板</button>
          </div>
        </div>
      </section>

      <section class="card">
        <div class="card__head">
          <div class="card__title">执行日志</div>
          <span class="tag tag--info">{{ execLogs.length }} 条</span>
        </div>
        <div class="table-wrap" style="border: 0; border-radius: 0 0 14px 14px">
          <table class="data-table">
            <thead>
              <tr>
                <th>时间</th>
                <th>策略</th>
                <th>执行说明</th>
                <th>结果</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="log in execLogs.slice(0, 6)" :key="log.id">
                <td class="num cell-strong">{{ log.time }}</td>
                <td>{{ log.strategy }}</td>
                <td class="cell-muted">{{ log.detail }}</td>
                <td><StatusTag :text="log.result" :tone="log.result === '成功' ? 'ok' : 'danger'" dot /></td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </div>

    <AppModal v-model="formOpen" :title="editingId ? '编辑联动策略' : '新建联动策略'" size="lg">
      <div class="form-grid">
        <div class="field span-2">
          <span class="field__label">策略名称</span>
          <input v-model="form.name" class="input" placeholder="例如：高温自动通风" />
        </div>
        <div class="field">
          <span class="field__label">适用地块</span>
          <select v-model="form.plotId" class="select">
            <option v-for="plot in plots" :key="plot.id" :value="plot.id">{{ plot.name }}</option>
          </select>
        </div>
        <div class="field">
          <span class="field__label">执行设备动作</span>
          <select v-model="form.action" class="select">
            <option v-for="action in actionOptions" :key="action" :value="action">{{ action }}</option>
          </select>
        </div>
        <div class="field">
          <span class="field__label">温度下限（℃）</span>
          <input v-model.number="form.tempMin" class="input" type="number" />
        </div>
        <div class="field">
          <span class="field__label">温度上限（℃）</span>
          <input v-model.number="form.tempMax" class="input" type="number" />
        </div>
        <div class="field">
          <span class="field__label">湿度下限（%）</span>
          <input v-model.number="form.humidityMin" class="input" type="number" />
        </div>
        <div class="field">
          <span class="field__label">湿度上限（%）</span>
          <input v-model.number="form.humidityMax" class="input" type="number" />
        </div>
        <div class="field">
          <span class="field__label">土壤湿度下限（%）</span>
          <input v-model.number="form.soilMin" class="input" type="number" />
        </div>
        <div class="field">
          <span class="field__label">生效时段</span>
          <input v-model="form.window" class="input" placeholder="例如 08:00-18:00" />
        </div>
      </div>
      <div class="notice" style="margin-top: 14px">
        触发条件同时包含温度、湿度与土壤湿度阈值；生效时段为空时表示全天生效。
      </div>
      <template #footer>
        <button class="btn" type="button" @click="formOpen = false">取消</button>
        <button class="btn btn--primary" type="button" @click="saveStrategy">
          {{ editingId ? '保存修改' : '创建策略' }}
        </button>
      </template>
    </AppModal>

    <AppModal v-model="deleteOpen" title="删除联动策略">
      <div class="notice notice--danger">
        删除后该策略将立即从调度引擎移除，正在执行的动作不会被中断。
      </div>
      <div v-if="deleteTarget" class="kv" style="margin-top: 14px">
        <div class="kv__item"><span>策略名称</span><b>{{ deleteTarget.name }}</b></div>
        <div class="kv__item"><span>适用地块</span><b>{{ plotName(deleteTarget.plotId) }}</b></div>
        <div class="kv__item"><span>执行动作</span><b>{{ deleteTarget.action }}</b></div>
        <div class="kv__item"><span>生效时段</span><b>{{ deleteTarget.window }}</b></div>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="deleteOpen = false">取消</button>
        <button class="btn btn--danger" type="button" @click="confirmDelete">确认删除</button>
      </template>
    </AppModal>
  </div>
</template>

<style scoped>
.template-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 12px;
}

.template-card {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 12px;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: var(--surface-2);
}

.template-card b {
  font-size: 12.5px;
  color: var(--ink);
}

.template-card__desc {
  font-size: 11.5px;
  line-height: 1.6;
  color: var(--muted);
}

.template-card__meta {
  font-size: 10.5px;
  color: var(--faint);
  font-family: var(--font-num);
}

@media (max-width: 1024px) {
  .template-grid {
    grid-template-columns: 1fr;
  }
}
</style>
