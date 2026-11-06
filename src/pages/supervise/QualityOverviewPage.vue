<script setup lang="ts">
import { computed, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import LineChart from '@/components/ui/LineChart.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { inspections, qualityOverview } from '@/data/mock'
import type { InspectReport } from '@/data/types'
import { buildCsv, downloadText } from '@/utils/format'

const toast = useToast()

const monthLabels = ['6月', '7月', '8月', '9月', '10月', '11月']
const passSeries = [{ name: '抽检合格率', color: '#2f5fa8', data: qualityOverview.trend }]

const keyword = ref('')
const cropFilter = ref('')
const resultFilter = ref('')

const cropOptions = computed(() => Array.from(new Set(inspections.map((item) => item.crop))))

const filteredInspections = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  return inspections.filter((item) => {
    const matchCrop = !cropFilter.value || item.crop === cropFilter.value
    const matchResult = !resultFilter.value || item.result === resultFilter.value
    const matchKeyword =
      !kw ||
      [item.batchNo, item.crop, item.reportNo, item.agency].some((value) => value.toLowerCase().includes(kw))
    return matchCrop && matchResult && matchKeyword
  })
})

const detailOpen = ref(false)
const detail = ref<InspectReport | null>(null)

function openDetail(row: InspectReport) {
  detail.value = row
  detailOpen.value = true
}

function resetFilters() {
  keyword.value = ''
  cropFilter.value = ''
  resultFilter.value = ''
  toast.info('筛选条件已重置')
}

function exportCsv() {
  const rows = filteredInspections.value.map((item) => [
    item.batchNo,
    item.crop,
    item.agency,
    item.testedAt,
    item.pesticide,
    item.heavyMetal,
    item.result,
    item.file,
  ])
  downloadText(
    '辖区质量检测批次_20261106.csv',
    buildCsv(['批次号', '作物', '检测机构', '检测日期', '农药残留', '重金属', '结论', '报告文件'], rows),
  )
  toast.success(`已导出 ${rows.length} 条质量检测记录`)
}

function resultTone(result: string): 'ok' | 'danger' {
  return result === '合格' ? 'ok' : 'danger'
}
</script>

<template>
  <div>
    <PageHeader
      eyebrow="QUALITY SAFETY"
      title="辖区质量安全总览"
      description="辖区农产品抽检、合格率趋势与品类质量分布 · 统计周期 2026-06 至 2026-11"
    >
      <template #actions>
        <RouterLink class="btn" to="/sup/trace">溯源台账</RouterLink>
        <button class="btn btn--primary" type="button" @click="exportCsv">导出 CSV</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="抽检批次" :value="qualityOverview.inspectedBatches" unit="批" icon="检" note="覆盖蔬菜、水果、粮油" trend="+6 环比" />
      <StatCard label="合格批次" :value="qualityOverview.qualified" unit="批" icon="合" note="合格率 98.6%" trend="+1 环比" />
      <StatCard label="不合格批次" :value="qualityOverview.unqualified" unit="批" icon="异" note="黄瓜批次农残超标" trend="持平" trend-up accent />
      <StatCard label="产品召回" :value="qualityOverview.recalls" unit="起" icon="召" note="进行中 1 起 · 已完成 2 起" trend="-1 环比" />
    </div>

    <div class="grid grid--main">
      <section class="card">
        <div class="card__head">
          <div class="card__title">
            质量合格率趋势
            <span class="card__sub">近 6 个月抽检合格率</span>
          </div>
          <span class="tag tag--ok">年度目标 98%</span>
        </div>
        <div class="card__body">
          <LineChart :labels="monthLabels" :series="passSeries" :height="228" unit="%" />
        </div>
      </section>

      <section class="card">
        <div class="card__head">
          <div class="card__title">品类质量分布 <span class="card__sub">抽检批次与合格率</span></div>
        </div>
        <div class="card__body" style="padding-top: 10px">
          <div class="table-wrap" style="border: 0">
            <table class="data-table">
              <thead>
                <tr>
                  <th>品类</th>
                  <th>批次数</th>
                  <th>合格率</th>
                  <th>达标情况</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in qualityOverview.categories" :key="item.name">
                  <td class="cell-strong">{{ item.name }}</td>
                  <td class="num">{{ item.batches }}</td>
                  <td>
                    <div class="progress" style="width: 96px">
                      <div
                        class="progress__bar"
                        :class="{ 'progress__bar--warn': item.passRate < 98 }"
                        :style="{ width: `${item.passRate}%` }"
                      />
                    </div>
                  </td>
                  <td class="num">{{ item.passRate }}%</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>
    </div>

    <section class="card" style="margin-top: 16px">
      <div class="card__head">
        <div class="card__title">质量检测批次 <span class="card__sub">共 {{ filteredInspections.length }} 条</span></div>
        <button class="link-action" type="button" @click="exportCsv">导出当前结果</button>
      </div>
      <div class="card__body">
        <div class="toolbar">
          <div class="field field--inline">
            <span class="field__label">品类</span>
            <select v-model="cropFilter" class="select" style="width: 130px">
              <option value="">全部品类</option>
              <option v-for="item in cropOptions" :key="item" :value="item">{{ item }}</option>
            </select>
          </div>
          <div class="field field--inline">
            <span class="field__label">结论</span>
            <select v-model="resultFilter" class="select" style="width: 120px">
              <option value="">全部结论</option>
              <option value="合格">合格</option>
              <option value="不合格">不合格</option>
            </select>
          </div>
          <div class="field field--inline" style="flex: 1; min-width: 220px">
            <span class="field__label">关键词</span>
            <input v-model="keyword" class="input" style="flex: 1" placeholder="批次号 / 检测机构 / 报告编号" />
          </div>
          <button class="btn btn--sm" type="button" @click="resetFilters">重置</button>
        </div>

        <div v-if="filteredInspections.length === 0" class="empty">
          <div class="empty__mark">检</div>
          未找到符合条件的检测批次，请调整筛选条件
        </div>
        <div v-else class="table-wrap">
          <table class="data-table">
            <thead>
              <tr>
                <th>批次号</th>
                <th>作物</th>
                <th>检测机构</th>
                <th>检测日期</th>
                <th>农药残留</th>
                <th>重金属</th>
                <th>结论</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in filteredInspections" :key="item.id">
                <td class="cell-strong num">{{ item.batchNo }}</td>
                <td>{{ item.crop }}</td>
                <td>{{ item.agency }}</td>
                <td class="num">{{ item.testedAt }}</td>
                <td>{{ item.pesticide }}</td>
                <td>{{ item.heavyMetal }}</td>
                <td><StatusTag :text="item.result" :tone="resultTone(item.result)" dot /></td>
                <td>
                  <button class="link-action" type="button" @click="openDetail(item)">查看详情</button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>

    <AppModal v-model="detailOpen" title="质量检测报告详情" size="lg">
      <template v-if="detail">
        <div class="kv kv--3" style="margin-bottom: 16px">
          <div class="kv__item"><span>报告编号</span><b>{{ detail.reportNo }}</b></div>
          <div class="kv__item"><span>批次号</span><b>{{ detail.batchNo }}</b></div>
          <div class="kv__item"><span>作物</span><b>{{ detail.crop }}</b></div>
          <div class="kv__item"><span>检测机构</span><b>{{ detail.agency }}</b></div>
          <div class="kv__item"><span>检测日期</span><b>{{ detail.testedAt }}</b></div>
          <div class="kv__item"><span>结论</span><b>{{ detail.result }}</b></div>
          <div class="kv__item"><span>农药残留</span><b>{{ detail.pesticide }}</b></div>
          <div class="kv__item"><span>重金属</span><b>{{ detail.heavyMetal }}</b></div>
          <div class="kv__item"><span>报告文件</span><b>{{ detail.file }}</b></div>
        </div>
        <div v-if="detail.result === '不合格'" class="notice notice--danger">
          该批次检测结论为不合格，已触发监管预警并纳入产品召回流程，请持续跟踪整改进度。
        </div>
        <div v-else class="notice notice--brand">
          该批次各项指标符合食品安全国家标准，可作为合格产品质量档案留存。
        </div>
      </template>
      <template #footer>
        <button class="btn" type="button" @click="detailOpen = false">关闭</button>
      </template>
    </AppModal>
  </div>
</template>
