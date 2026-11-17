<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { cloneRows, irrigationPlots as irrigationPlotsSeed, irrigationSummary, plots } from '@/api/store'
import type { Plot } from '@/data/types'
import { formatNumber } from '@/utils/format'

const toast = useToast()

type IrrigationStatus = '正常' | '运行中' | '待灌溉' | '已停止'

interface IrrigationPlot {
  plot: Plot
  moisture: number
  planned: number
  status: IrrigationStatus
  lastRun: string
}

/** 地块墒情与灌溉计划来自后端（/api/v1/control/irrigation-plots） */
interface IrrigationRow {
  id: string
  plotId: string
  moisture: number
  planned: number
  status: IrrigationStatus
  lastRun: string
}

const irrigationRows = cloneRows<IrrigationRow>(irrigationPlotsSeed)

const cards = reactive<IrrigationPlot[]>(
  irrigationRows
    .map((row) => {
      const plot = plots.find((item) => item.id === row.plotId)
      if (!plot) return null
      return {
        plot,
        moisture: row.moisture,
        planned: row.planned,
        status: row.status,
        lastRun: row.lastRun,
      }
    })
    .filter((item): item is IrrigationPlot => item !== null),
)

const todayWater = irrigationSummary.todayWater
const todayArea = irrigationSummary.todayArea
const savingRate = irrigationSummary.savingRate
const runningCount = computed(() => cards.filter((item) => item.status === '运行中').length)

function moistureTone(moisture: number): 'ok' | 'warn' | 'danger' {
  if (moisture < 40) return 'danger'
  if (moisture < 45) return 'warn'
  return 'ok'
}

function moistureLabel(moisture: number): string {
  if (moisture < 40) return '异常'
  if (moisture < 45) return '缺水'
  return '正常'
}

function start(item: IrrigationPlot) {
  if (item.plot.status === '休耕') {
    toast.warn(`${item.plot.name} 处于休耕期，无需灌溉`)
    return
  }
  item.status = '运行中'
  item.lastRun = '刚刚'
  toast.success(`${item.plot.name} 已下发灌溉指令，计划灌溉 ${item.planned} m³`)
}

function stop(item: IrrigationPlot) {
  if (item.status !== '运行中') {
    toast.info(`${item.plot.name} 当前没有运行中的灌溉任务`)
    return
  }
  item.status = '已停止'
  toast.warn(`${item.plot.name} 灌溉已停止，本次用水将计入今日统计`)
}

const planOpen = ref(false)
const editing = ref<IrrigationPlot | null>(null)
const planForm = reactive({ planned: 0, duration: 30 })

function openPlan(item: IrrigationPlot) {
  editing.value = item
  planForm.planned = item.planned
  planForm.duration = 30
  planOpen.value = true
}

function savePlan() {
  if (!editing.value) return
  editing.value.planned = planForm.planned
  planOpen.value = false
  toast.success(`${editing.value.plot.name} 的灌溉计划已更新为 ${planForm.planned} m³ / ${planForm.duration} 分钟`)
}

const queue = computed(() => [
  ...cards
    .filter((item) => item.status === '运行中')
    .map((item) => ({
      key: `run-${item.plot.id}`,
      title: `${item.plot.name} · 灌溉中`,
      meta: `剩余约 ${Math.max(4, Math.round(item.planned / 4))} 分钟 · 目标 ${item.planned} m³`,
      tone: 'ok' as const,
    })),
  ...cards
    .filter((item) => item.status === '待灌溉')
    .map((item) => ({
      key: `wait-${item.plot.id}`,
      title: `${item.plot.name} · 待灌溉`,
      meta: `土壤水分 ${item.moisture}% · 计划 ${item.planned} m³`,
      tone: 'warn' as const,
    })),
  { key: 'plan-01', title: '1号智能大棚 · 明晨 06:00 定时灌溉', meta: '周期任务 · 预计用水 26 m³', tone: 'mute' as const },
  { key: 'plan-02', title: '露天 B 区稻田 · 11-07 08:30 定时灌溉', meta: '周期任务 · 预计用水 42 m³', tone: 'mute' as const },
])
</script>

<template>
  <div>
    <PageHeader title="灌溉控制" description="按地块查看土壤水分、计划灌溉量与任务队列，支持远程启停与计划调整">
      <template #actions>
        <RouterLink class="btn" to="/control/device">设备控制台</RouterLink>
        <button class="btn btn--primary" type="button" @click="toast.success('灌溉计划已同步至网关，夜间时段自动执行')">
          同步计划
        </button>
      </template>
    </PageHeader>

    <!-- 今日概览 -->
    <div class="kpi-row">
      <section class="kpi">
        <div class="kpi__label">今日用水量</div>
        <div class="kpi__value">{{ formatNumber(todayWater) }}<small>m³</small></div>
        <div class="kpi__meta">较昨日减少 12 m³</div>
      </section>
      <section class="kpi">
        <div class="kpi__label">灌溉面积</div>
        <div class="kpi__value">{{ todayArea }}<small>亩</small></div>
        <div class="kpi__meta">覆盖 {{ cards.length }} 个地块</div>
      </section>
      <section class="kpi">
        <div class="kpi__label">节水率</div>
        <div class="kpi__value">{{ savingRate }}<small>%</small></div>
        <div class="kpi__meta">滴灌 + 墒情联动</div>
      </section>
      <section class="kpi">
        <div class="kpi__label">运行中任务</div>
        <div class="kpi__value">{{ runningCount }}<small>个</small></div>
        <div class="kpi__meta">队列中 {{ queue.length }} 项</div>
      </section>
    </div>

    <div class="split">
      <!-- 地块灌溉卡片 -->
      <div class="irrigation-grid">
        <article v-for="item in cards" :key="item.plot.id" class="irrigation-card">
          <div class="irrigation-card__top">
            <div>
              <div class="irrigation-card__name">{{ item.plot.name }}</div>
              <div class="irrigation-card__crop">{{ item.plot.crop }} · {{ item.plot.area }} 亩 · {{ item.plot.manager }}</div>
            </div>
            <span class="pill" :class="`pill--${item.status === '运行中' ? 'brand' : item.status === '待灌溉' ? 'warn' : 'ok'}`">
              <i class="dot" :class="item.status === '运行中' ? 'dot--info' : item.status === '待灌溉' ? 'dot--warn' : 'dot--ok'" />
              {{ item.status }}
            </span>
          </div>

          <div class="moisture">
            <div class="moisture__head">
              <span>土壤水分 · <em :class="`text-${moistureTone(item.moisture)}`">{{ moistureLabel(item.moisture) }}</em></span>
              <span class="moisture__value">{{ item.moisture }}%</span>
            </div>
            <div class="progress">
              <div
                class="progress__bar"
                :class="{
                  'progress__bar--ok': moistureTone(item.moisture) === 'ok',
                  'progress__bar--warn': moistureTone(item.moisture) === 'warn',
                  'progress__bar--danger': moistureTone(item.moisture) === 'danger',
                }"
                :style="{ width: `${item.moisture}%` }"
              />
            </div>
          </div>

          <div class="irrigation-card__meta">
            <span>计划灌溉量 <b>{{ item.planned }} m³</b></span>
            <span>上次灌溉 <b>{{ item.lastRun }}</b></span>
          </div>

          <div class="irrigation-card__actions">
            <button class="btn btn--primary btn--sm" type="button" @click="start(item)">立即灌溉</button>
            <button class="btn btn--sm" type="button" @click="stop(item)">停止</button>
            <button class="btn btn--sm btn--ghost" type="button" @click="openPlan(item)">编辑计划</button>
          </div>
        </article>
      </div>

      <!-- 任务队列 -->
      <div class="stack">
        <section class="card">
          <div class="card__head">
            <div class="card__title">灌溉任务队列</div>
            <span class="tag">{{ queue.length }} 项</span>
          </div>
          <div class="card__body task-queue">
            <div v-for="task in queue" :key="task.key" class="task-item">
              <span class="task-item__dot" :class="`task-item__dot--${task.tone}`" />
              <div>
                <div class="task-item__title">{{ task.title }}</div>
                <div class="task-item__meta">{{ task.meta }}</div>
              </div>
            </div>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">用水提示</div>
          </div>
          <div class="card__body">
            <div class="notice notice--brand">
              3 号黄瓜棚土壤水分偏低，建议在 10:00 前完成一次 24 m³ 的滴灌。
            </div>
            <div class="notice" style="margin-top: 8px">
              夜间灌溉改为清晨时段，可减少蒸发损耗约 5%。
            </div>
          </div>
        </section>
      </div>
    </div>

    <AppModal v-model="planOpen" title="编辑灌溉计划">
      <div v-if="editing">
        <div class="kv" style="margin-bottom: 16px">
          <div class="kv__item"><span>地块</span><b>{{ editing.plot.name }}</b></div>
          <div class="kv__item"><span>作物</span><b>{{ editing.plot.crop }}</b></div>
        </div>
        <label class="field" style="margin-bottom: 14px">
          <span class="field__label">计划灌溉量（m³）</span>
          <input v-model.number="planForm.planned" class="input" type="number" min="1" />
        </label>
        <label class="field">
          <span class="field__label">单次灌溉时长（分钟）</span>
          <input v-model.number="planForm.duration" class="input" type="number" min="5" step="5" />
        </label>
        <div class="notice" style="margin-top: 14px">计划保存后将同步至自动联动策略，墒情低于阈值时自动执行。</div>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="planOpen = false">取消</button>
        <button class="btn btn--primary" type="button" @click="savePlan">保存计划</button>
      </template>
    </AppModal>
  </div>
</template>

<style scoped>
.irrigation-card__crop {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.moisture__head em {
  font-style: normal;
  font-weight: 500;
}

.text-ok {
  color: var(--success);
}

.text-warn {
  color: var(--warning);
}

.text-danger {
  color: var(--danger);
}

@media (max-width: 720px) {
  .irrigation-card__actions .btn {
    flex: 1;
  }
}
</style>
