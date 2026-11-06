<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import Pager from '@/components/ui/Pager.vue'
import { useToast } from '@/composables/useToast'
import { batches, inspections, plotName, traceTimeline } from '@/data/mock'
import type { TraceBatch } from '@/data/types'
import { buildCsv, downloadText, formatNumber } from '@/utils/format'

type Tone = 'ok' | 'warn' | 'danger' | 'info' | 'brand' | 'mute'

const toast = useToast()

const keyword = ref('')
const cropFilter = ref('')
const activeKeyword = ref('')
const activeCrop = ref('')
const currentPage = ref(1)
const pageSize = 5

const cropOptions = computed(() => Array.from(new Set(batches.map((item) => item.crop))))

const resultRows = computed(() => {
  const kw = activeKeyword.value.trim().toLowerCase()
  return batches.filter((item) => {
    const haystack = [item.batchNo, item.crop, item.variety, item.plot, plotName(item.plot), `trace-${item.batchNo}`]
    const matchCrop = !activeCrop.value || item.crop === activeCrop.value
    const matchKeyword = !kw || haystack.some((value) => value.toLowerCase().includes(kw))
    return matchCrop && matchKeyword
  })
})

const pagedRows = computed(() => {
  const start = (currentPage.value - 1) * pageSize
  return resultRows.value.slice(start, start + pageSize)
})

const summary = computed(() => ({
  total: resultRows.value.length,
  coded: resultRows.value.filter((item) => item.status === '已赋码').length,
  scans: resultRows.value.reduce((sum, item) => sum + item.scans, 0),
  recalls: resultRows.value.filter((item) => item.status === '已召回').length,
}))

watch([activeKeyword, activeCrop], () => {
  currentPage.value = 1
})

const detailOpen = ref(false)
const selected = ref<TraceBatch | null>(null)
const selectedInspection = computed(() =>
  selected.value ? inspections.find((item) => item.batchNo === selected.value?.batchNo) ?? null : null,
)
const selectedPath = computed(() => (selected.value ? `/trace/h5/${selected.value.batchNo}` : '/sup/trace'))

function search() {
  activeKeyword.value = keyword.value
  activeCrop.value = cropFilter.value
  currentPage.value = 1
  if (resultRows.value.length === 0) {
    toast.warn('未匹配到溯源批次，请更换溯源码或作物')
    return
  }
  toast.success(`查询完成，共匹配 ${resultRows.value.length} 个批次`)
}

function resetFilters() {
  keyword.value = ''
  cropFilter.value = ''
  activeKeyword.value = ''
  activeCrop.value = ''
  currentPage.value = 1
  toast.info('查询条件已重置')
}

function openDetail(row: TraceBatch) {
  selected.value = row
  detailOpen.value = true
}

function exportCsv() {
  const rows = resultRows.value.map((item) => [
    item.batchNo,
    plotName(item.plot),
    item.crop,
    item.harvestedAt,
    item.weight,
    item.grade,
    item.qrCount,
    item.scans,
    item.status,
  ])
  downloadText(
    '辖区溯源批次台账_20261106.csv',
    buildCsv(['批次号', '地块', '作物', '采收日期', '重量(kg)', '等级', '赋码数', '扫码数', '状态'], rows),
  )
  toast.success(`已导出 ${rows.length} 条溯源批次台账`)
}

function statusTone(status: string): Tone {
  if (status === '已赋码') return 'ok'
  if (status === '待赋码') return 'warn'
  return 'danger'
}
</script>

<template>
  <div>
    <PageHeader
      eyebrow="TRACE LEDGER"
      title="农产品溯源查询"
      description="按溯源码、批次号或作物检索辖区农产品全流程溯源台账 · 支持消费者 H5 页面预览"
    >
      <template #actions>
        <RouterLink class="btn" to="/sup/quality">质量总览</RouterLink>
        <button class="btn btn--primary" type="button" @click="exportCsv">导出 CSV</button>
      </template>
    </PageHeader>

    <section class="card" style="margin-bottom: 16px">
      <div class="card__head">
        <div class="card__title">批次检索 <span class="card__sub">支持批次号、溯源码与作物名称</span></div>
        <span class="tag tag--brand">一物一码</span>
      </div>
      <div class="card__body">
        <div class="search-row">
          <div class="field" style="flex: 1.4; min-width: 240px">
            <span class="field__label">溯源码 / 批次号</span>
            <input v-model="keyword" class="input" placeholder="如 B20261105-03 或 TRACE-B20261105-03" @keyup.enter="search" />
          </div>
          <div class="field" style="flex: 1; min-width: 150px">
            <span class="field__label">作物</span>
            <select v-model="cropFilter" class="select">
              <option value="">全部作物</option>
              <option v-for="item in cropOptions" :key="item" :value="item">{{ item }}</option>
            </select>
          </div>
          <button class="btn btn--primary" type="button" @click="search">查询</button>
          <button class="btn" type="button" @click="resetFilters">重置</button>
        </div>
        <div v-if="activeKeyword || activeCrop" class="query-hint">
          当前条件：{{ activeCrop || '全部作物' }} / {{ activeKeyword || '全部批次' }}
        </div>
      </div>
    </section>

    <section class="card card--tint" style="margin-bottom: 16px">
      <div class="card__head">
        <div class="card__title">查询结果</div>
        <span class="tag tag--outline">实时汇总</span>
      </div>
      <div class="card__body">
        <div class="kv kv--3">
          <div class="kv__item"><span>匹配批次</span><b class="num">{{ summary.total }} 个</b></div>
          <div class="kv__item"><span>已赋码批次</span><b class="num">{{ summary.coded }} 个</b></div>
          <div class="kv__item"><span>累计扫码</span><b class="num">{{ formatNumber(summary.scans) }} 次</b></div>
          <div class="kv__item"><span>待赋码</span><b class="num">{{ resultRows.filter((item) => item.status === '待赋码').length }} 个</b></div>
          <div class="kv__item"><span>已召回</span><b class="num">{{ summary.recalls }} 个</b></div>
          <div class="kv__item"><span>累计赋码</span><b class="num">{{ formatNumber(resultRows.reduce((sum, item) => sum + item.qrCount, 0)) }} 枚</b></div>
        </div>
      </div>
    </section>

    <section class="card">
      <div class="card__head">
        <div class="card__title">批次台账 <span class="card__sub">共 {{ resultRows.length }} 条</span></div>
        <button class="link-action" type="button" @click="exportCsv">导出当前结果</button>
      </div>
      <div class="card__body" style="padding-bottom: 0">
        <div v-if="resultRows.length === 0" class="empty">
          <div class="empty__mark">溯</div>
          没有符合条件的溯源批次，请调整查询条件
        </div>
        <div v-else class="table-wrap" style="margin-bottom: 14px">
          <table class="data-table">
            <thead>
              <tr>
                <th>批次号</th>
                <th>地块</th>
                <th>作物</th>
                <th>采收日期</th>
                <th>重量（kg）</th>
                <th>等级</th>
                <th>赋码数</th>
                <th>扫码数</th>
                <th>状态</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="item in pagedRows" :key="item.id">
                <td class="cell-strong num">{{ item.batchNo }}</td>
                <td>{{ plotName(item.plot) }}</td>
                <td>{{ item.crop }}</td>
                <td class="num">{{ item.harvestedAt }}</td>
                <td class="num">{{ formatNumber(item.weight) }}</td>
                <td>{{ item.grade }}</td>
                <td class="num">{{ formatNumber(item.qrCount) }}</td>
                <td class="num">{{ formatNumber(item.scans) }}</td>
                <td><StatusTag :text="item.status" :tone="statusTone(item.status)" dot /></td>
                <td>
                  <div class="table-actions">
                    <button class="link-action" type="button" @click="openDetail(item)">查看详情</button>
                    <RouterLink class="link-action" :to="`/trace/h5/${item.batchNo}`">预览 H5</RouterLink>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      <Pager
        v-if="resultRows.length > 0"
        :total="resultRows.length"
        :page="currentPage"
        :page-size="pageSize"
        @update:page="currentPage = $event"
      />
    </section>

    <AppModal v-model="detailOpen" :title="`批次详情 · ${selected?.batchNo ?? ''}`" size="lg">
      <template v-if="selected">
        <div class="kv kv--3" style="margin-bottom: 18px">
          <div class="kv__item"><span>批次号</span><b>{{ selected.batchNo }}</b></div>
          <div class="kv__item"><span>作物 / 品种</span><b>{{ selected.crop }} · {{ selected.variety }}</b></div>
          <div class="kv__item"><span>地块</span><b>{{ plotName(selected.plot) }}（{{ selected.plot }}）</b></div>
          <div class="kv__item"><span>定植日期</span><b>{{ selected.plantedAt }}</b></div>
          <div class="kv__item"><span>采收日期</span><b>{{ selected.harvestedAt }}</b></div>
          <div class="kv__item"><span>等级 / 重量</span><b>{{ selected.grade }} · {{ formatNumber(selected.weight) }} kg</b></div>
          <div class="kv__item"><span>赋码数量</span><b>{{ formatNumber(selected.qrCount) }} 枚</b></div>
          <div class="kv__item"><span>扫码次数</span><b>{{ formatNumber(selected.scans) }} 次</b></div>
          <div class="kv__item"><span>批次状态</span><b>{{ selected.status }}</b></div>
        </div>

        <div class="detail-block">
          <div class="detail-block__title">检测报告</div>
          <div v-if="selectedInspection" class="kv kv--3">
            <div class="kv__item"><span>报告编号</span><b>{{ selectedInspection.reportNo }}</b></div>
            <div class="kv__item"><span>检测机构</span><b>{{ selectedInspection.agency }}</b></div>
            <div class="kv__item"><span>检测日期</span><b>{{ selectedInspection.testedAt }}</b></div>
            <div class="kv__item"><span>农药残留</span><b>{{ selectedInspection.pesticide }}</b></div>
            <div class="kv__item"><span>重金属</span><b>{{ selectedInspection.heavyMetal }}</b></div>
            <div class="kv__item"><span>结论</span><b>{{ selectedInspection.result }}</b></div>
          </div>
          <div v-else class="notice notice--warn">该批次尚未生成检测报告，请督促园区尽快送检归档。</div>
        </div>

        <div class="detail-block">
          <div class="detail-block__title">生长农事记录</div>
          <div class="timeline">
            <div
              v-for="(item, index) in traceTimeline"
              :key="`${item.date}-${index}`"
              class="timeline__item"
              :class="index === traceTimeline.length - 1 ? 'timeline__item--active' : 'timeline__item--done'"
            >
              <div class="timeline__title">{{ item.title }}</div>
              <div class="timeline__desc">{{ item.desc }}</div>
              <div class="timeline__desc num">{{ item.date }}</div>
            </div>
          </div>
        </div>

        <div v-if="selected.status === '已召回'" class="notice notice--danger">
          该批次已启动产品召回，消费者页面将同步展示召回提示，请关注回收进度。
        </div>
      </template>
      <template #footer>
        <RouterLink v-if="selected" class="btn" :to="selectedPath">预览消费者页面</RouterLink>
        <button class="btn btn--primary" type="button" @click="detailOpen = false">关闭</button>
      </template>
    </AppModal>
  </div>
</template>

<style scoped>
.search-row {
  display: flex;
  align-items: flex-end;
  gap: 10px;
  flex-wrap: wrap;
}

.query-hint {
  margin-top: 10px;
  font-size: 11.5px;
  color: var(--muted);
}

.detail-block {
  margin-bottom: 18px;
}

.detail-block__title {
  margin-bottom: 10px;
  font-size: 12.5px;
  font-weight: 650;
  color: var(--ink);
}
</style>
