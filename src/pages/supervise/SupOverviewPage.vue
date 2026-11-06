<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import LineChart from '@/components/ui/LineChart.vue'
import DonutChart from '@/components/ui/DonutChart.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import { useToast } from '@/composables/useToast'
import { batches, inspections, plots, qualityOverview, recalls, supWarnings } from '@/data/mock'
import { formatNumber } from '@/utils/format'

type Tone = 'ok' | 'warn' | 'danger' | 'info' | 'brand' | 'mute'

const router = useRouter()
const toast = useToast()
const quickCode = ref('')

const pendingWarnings = computed(() => supWarnings.filter((item) => item.status !== '已办结').length)

const monthLabels = ['6月', '7月', '8月', '9月', '10月', '11月']
const passSeries = computed(() => [{ name: '抽检合格率', color: '#2f5fa8', data: qualityOverview.trend }])

const categoryColors = ['#2f5fa8', '#4fae74', '#b8862f', '#7ba6d9', '#9aa9a0']
const categorySegments = computed(() =>
  qualityOverview.categories.map((item, index) => ({
    label: item.name,
    value: item.batches,
    color: categoryColors[index] ?? '#9aa9a0',
  })),
)

const latestWarnings = computed(() => supWarnings.slice(0, 5))

const weekActivities = computed(() => {
  const rows: Array<{ time: string; title: string; desc: string; state: 'done' | 'active' }> = []
  const warning = supWarnings[0]
  if (warning) {
    rows.push({
      time: warning.createdAt,
      title: `${warning.type}预警：${warning.title}`,
      desc: `${warning.entity} · 当前状态 ${warning.status}`,
      state: warning.status === '已办结' ? 'done' : 'active',
    })
  }
  const recall = recalls[0]
  if (recall) {
    rows.push({
      time: recall.createdAt,
      title: `批次 ${recall.batchNo} 产品召回进行中`,
      desc: `${recall.reason}；已回收 ${recall.recovered} / ${recall.affected} kg`,
      state: 'active',
    })
  }
  const report = inspections[0]
  if (report) {
    rows.push({
      time: report.testedAt,
      title: `抽检报告 ${report.reportNo} 出具`,
      desc: `${report.crop} · ${report.agency} · 结论${report.result}`,
      state: 'done',
    })
  }
  rows.push({
    time: '2026-11-04 10:12',
    title: '草莓采收分级台账核查完成',
    desc: 'P-02 草莓批次分级登记已补录，相关预警已办结。',
    state: 'done',
  })
  return rows
})

const parkRows = computed(() =>
  plots.map((plot) => ({
    id: plot.id,
    name: plot.name,
    crop: `${plot.crop} · ${plot.variety}`,
    area: plot.area,
    manager: plot.manager,
    level: plot.status === '预警' ? 'B' : 'A',
    status: plot.status,
  })),
)

function refresh() {
  toast.success('辖区监管数据已刷新至 2026-11-06 09:42')
}

function quickQuery() {
  const code = quickCode.value.trim()
  if (!code) {
    toast.warn('请输入溯源码或批次号后再查询')
    return
  }
  const hit = batches.find((item) => item.batchNo === code || `TRACE-${item.batchNo}` === code)
  if (hit) {
    toast.success(`已匹配批次 ${hit.batchNo}，正在跳转溯源查询`)
  } else {
    toast.warn(`未直接匹配到 ${code}，已跳转溯源查询页继续检索`)
  }
  router.push('/sup/trace')
}

function levelTone(level: string): Tone {
  if (level === '高') return 'danger'
  if (level === '中') return 'warn'
  return 'info'
}

function statusTone(status: string): Tone {
  if (status === '待处理') return 'warn'
  if (status === '处理中') return 'brand'
  return 'ok'
}

function plotTone(status: string): Tone {
  if (status === '预警') return 'warn'
  if (status === '休耕') return 'info'
  return 'ok'
}
</script>

<template>
  <div>
    <PageHeader
      eyebrow="SUPERVISION OVERVIEW"
      title="辖区监管总览"
      description="辖区 12 个农业园区的质量安全、溯源台账与预警处置态势汇总 · 数据更新于 2026-11-06 09:42"
    >
      <template #actions>
        <button class="btn" type="button" @click="refresh">刷新数据</button>
        <RouterLink class="btn btn--primary" to="/sup/reports">生成监管报表</RouterLink>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="辖区园区数" :value="12" unit="个" icon="园" note="覆盖 3 个镇街 · 6 个示范基地" trend="+1 本季度新增" />
      <StatCard label="辖区种植面积" :value="formatNumber(3860)" unit="亩" icon="地" note="蔬菜 62% · 水果 27%" trend="+3.1% 同比" />
      <StatCard label="抽检合格率" :value="qualityOverview.passRate" unit="%" icon="检" note="近 6 个月累计抽检 72 批次" trend="+0.2% 环比" />
      <StatCard label="待处理预警" :value="pendingWarnings" unit="条" icon="警" note="质量异常 1 · 台账缺失 2" trend="较上周 -2" trend-up accent />
    </div>

    <div class="grid grid--main">
      <div class="stack">
        <section class="card">
          <div class="card__head">
            <div class="card__title">
              质量合格率趋势
              <span class="card__sub">近 6 个月抽检合格率</span>
            </div>
            <RouterLink class="link-action" to="/sup/quality">质量安全总览</RouterLink>
          </div>
          <div class="card__body">
            <LineChart :labels="monthLabels" :series="passSeries" :height="220" unit="%" />
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">异常预警 <span class="card__sub">按创建时间排序</span></div>
            <RouterLink class="link-action" to="/sup/warnings">全部预警</RouterLink>
          </div>
          <div class="table-wrap" style="border: 0; border-radius: 0 0 14px 14px">
            <table class="data-table">
              <thead>
                <tr>
                  <th>预警内容</th>
                  <th>类型</th>
                  <th>等级</th>
                  <th>状态</th>
                  <th>时间</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in latestWarnings" :key="item.id">
                  <td>{{ item.title }}</td>
                  <td class="cell-muted">{{ item.type }}</td>
                  <td><StatusTag :text="item.level" :tone="levelTone(item.level)" dot /></td>
                  <td><StatusTag :text="item.status" :tone="statusTone(item.status)" /></td>
                  <td class="num cell-muted">{{ item.createdAt }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>
      </div>

      <div class="stack">
        <section class="card card--tint">
          <div class="card__head">
            <div class="card__title">溯源批次快速查询</div>
            <span class="tag tag--brand">一物一码</span>
          </div>
          <div class="card__body">
            <div class="row" style="gap: 8px">
              <input
                v-model="quickCode"
                class="input"
                style="flex: 1"
                placeholder="输入批次号或溯源码"
                @keyup.enter="quickQuery"
              />
              <button class="btn btn--primary" type="button" @click="quickQuery">查询</button>
            </div>
            <div class="quick-hint">示例：B20261105-03 / TRACE-B20261105-03</div>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">品类质量分布</div>
            <span class="tag tag--outline">抽检批次数</span>
          </div>
          <div class="card__body">
            <DonutChart
              :segments="categorySegments"
              :size="142"
              :center-value="`${qualityOverview.inspectedBatches}`"
              center-label="抽检批次"
            />
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">近期监管动态</div>
            <span class="tag tag--outline">本周</span>
          </div>
          <div class="card__body">
            <div class="timeline">
              <div
                v-for="(item, index) in weekActivities"
                :key="`${item.time}-${index}`"
                class="timeline__item"
                :class="item.state === 'active' ? 'timeline__item--active' : 'timeline__item--done'"
              >
                <div class="timeline__title">{{ item.title }}</div>
                <div class="timeline__desc">{{ item.desc }}</div>
                <div class="timeline__desc num">{{ item.time }}</div>
              </div>
            </div>
          </div>
        </section>
      </div>
    </div>

    <section class="card" style="margin-top: 16px">
      <div class="card__head">
        <div class="card__title">辖区园区列表 <span class="card__sub">按辖区备案顺序</span></div>
        <RouterLink class="link-action" to="/sup/quality">查看质量档案</RouterLink>
      </div>
      <div class="table-wrap" style="border: 0; border-radius: 0 0 14px 14px">
        <table class="data-table">
          <thead>
            <tr>
              <th>园区/基地</th>
              <th>种植作物</th>
              <th>面积（亩）</th>
              <th>负责人</th>
              <th>质量评级</th>
              <th>运行状态</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="item in parkRows" :key="item.id">
              <td class="cell-strong">{{ item.name }}</td>
              <td>{{ item.crop }}</td>
              <td class="num">{{ item.area }}</td>
              <td>{{ item.manager }}</td>
              <td><span class="tag" :class="item.level === 'A' ? 'tag--ok' : 'tag--warn'">{{ item.level }} 级</span></td>
              <td><StatusTag :text="item.status" :tone="plotTone(item.status)" dot /></td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  </div>
</template>

<style scoped>
.quick-hint {
  margin-top: 8px;
  font-size: 11px;
  color: var(--faint);
}
</style>
