<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { batches, inspections } from '@/data/mock'
import type { InspectReport } from '@/data/types'
import { buildCsv, downloadText, formatNumber, today } from '@/utils/format'

const toast = useToast()

const rows = ref<InspectReport[]>(inspections.map((item) => ({ ...item })))

const resultFilter = ref('全部')
const batchFilter = ref('全部')
const keyword = ref('')
const resultOptions = ['全部', '合格', '不合格']
const batchOptions = computed(() => ['全部', ...Array.from(new Set(rows.value.map((item) => item.batchNo)))])

const filtered = computed(() => {
  const text = keyword.value.trim().toLowerCase()
  return rows.value.filter((row) => {
    const matchResult = resultFilter.value === '全部' || row.result === resultFilter.value
    const matchBatch = batchFilter.value === '全部' || row.batchNo === batchFilter.value
    const matchKeyword =
      !text || [row.reportNo, row.batchNo, row.crop, row.agency, row.file].some((value) => value.toLowerCase().includes(text))
    return matchResult && matchBatch && matchKeyword
  })
})

const qualifiedCount = computed(() => rows.value.filter((item) => item.result === '合格').length)
const unqualifiedCount = computed(() => rows.value.filter((item) => item.result === '不合格').length)
const passRate = computed(() => (rows.value.length === 0 ? 0 : (qualifiedCount.value / rows.value.length) * 100))

const detailOpen = ref(false)
const selected = ref<InspectReport | null>(null)

const uploadOpen = ref(false)
const form = reactive({
  batchNo: batches[0]?.batchNo ?? '',
  agency: '重庆市农产品质量检测中心',
  testedAt: today(),
  pesticide: '未检出',
  heavyMetal: '合格',
  result: '合格',
  file: '',
})

const deleteOpen = ref(false)
const deleting = ref<InspectReport | null>(null)

function openDetail(row: InspectReport) {
  selected.value = row
  detailOpen.value = true
}

function openUpload() {
  form.file = `${form.batchNo.replace(/[^0-9A-Za-z-]/g, '')}_检测报告.pdf`
  uploadOpen.value = true
}

function submitUpload() {
  if (!form.batchNo) {
    toast.error('请选择批次')
    return
  }
  if (!form.file.trim()) {
    toast.error('请填写附件文件名')
    return
  }
  const batch = batches.find((item) => item.batchNo === form.batchNo)
  const batchTag = form.testedAt.replace(/-/g, '')
  rows.value.unshift({
    id: `IR-${String(rows.value.length + 1).padStart(2, '0')}`,
    batchNo: form.batchNo,
    crop: batch?.crop ?? '未知作物',
    reportNo: `CQ-JC-${batchTag}-${String(rows.value.length + 1).padStart(3, '0')}`,
    agency: form.agency.trim() || '未填写机构',
    testedAt: form.testedAt,
    pesticide: form.pesticide.trim() || '未检出',
    heavyMetal: form.heavyMetal.trim() || '合格',
    result: form.result === '不合格' ? '不合格' : '合格',
    file: form.file.trim(),
  })
  uploadOpen.value = false
  toast.success(`批次 ${form.batchNo} 的检测报告已上传`)
}

function askDelete(row: InspectReport) {
  deleting.value = row
  deleteOpen.value = true
}

function confirmDelete() {
  if (!deleting.value) return
  const reportNo = deleting.value.reportNo
  rows.value = rows.value.filter((item) => item.id !== deleting.value?.id)
  deleteOpen.value = false
  deleting.value = null
  toast.success(`检测报告 ${reportNo} 已删除`)
}

function viewFile(row: InspectReport) {
  toast.info(`正在打开附件 ${row.file}`)
}

function exportCsv() {
  const data = filtered.value.map((row) => [
    row.reportNo,
    row.batchNo,
    row.crop,
    row.agency,
    row.testedAt,
    row.pesticide,
    row.heavyMetal,
    row.result,
    row.file,
  ])
  downloadText(
    `检测报告_${today()}.csv`,
    buildCsv(['报告编号', '批次号', '作物', '检测机构', '检测日期', '农残', '重金属', '结论', '附件'], data),
  )
  toast.success(`已导出 ${data.length} 条检测报告`)
}
</script>

<template>
  <div>
    <PageHeader
      eyebrow="INSPECTION"
      title="检测报告管理"
      description="管理批次农残与重金属检测报告，支撑溯源档案与质量判定"
    >
      <template #actions>
        <button class="btn" type="button" @click="exportCsv">导出 CSV</button>
        <button class="btn btn--primary" type="button" @click="openUpload">上传报告</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="检测报告总数" :value="rows.length" unit="份" icon="检" note="覆盖 5 个批次" trend="本月新增 3 份" />
      <StatCard label="合格报告" :value="qualifiedCount" unit="份" icon="合" note="农残与重金属均达标" />
      <StatCard label="不合格报告" :value="unqualifiedCount" unit="份" icon="警" note="需跟进召回与整改" accent />
      <StatCard
        label="检测合格率"
        :value="formatNumber(passRate, 1)"
        unit="%"
        icon="率"
        note="目标值 ≥ 98%"
        trend="较上月 +0.4%"
      />
    </div>

    <div class="toolbar">
      <div class="field field--inline">
        <span class="field__label">结论</span>
        <select v-model="resultFilter" class="select" style="width: 118px">
          <option v-for="item in resultOptions" :key="item" :value="item">{{ item }}</option>
        </select>
      </div>
      <div class="field field--inline">
        <span class="field__label">批次</span>
        <select v-model="batchFilter" class="select" style="width: 160px">
          <option v-for="item in batchOptions" :key="item" :value="item">{{ item }}</option>
        </select>
      </div>
      <div class="field field--inline" style="flex: 1; min-width: 220px">
        <span class="field__label">关键词</span>
        <input v-model="keyword" class="input" type="search" placeholder="搜索报告编号、机构、作物或附件" />
      </div>
      <div class="toolbar__spacer" />
      <span class="tag tag--brand">共 {{ filtered.length }} 份</span>
    </div>

    <section class="card">
      <div class="card__head">
        <div class="card__title">检测报告列表 <span class="card__sub">按检测日期倒序</span></div>
        <button class="link-action" type="button" @click="openUpload">上传新报告</button>
      </div>
      <div class="table-wrap" style="border: 0; border-radius: 0; margin-top: 14px">
        <table class="data-table">
          <thead>
            <tr>
              <th>报告编号</th>
              <th>批次号</th>
              <th>作物</th>
              <th>检测机构</th>
              <th>检测日期</th>
              <th>农残</th>
              <th>重金属</th>
              <th>结论</th>
              <th>附件</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in filtered" :key="row.id">
              <td class="num cell-strong">{{ row.reportNo }}</td>
              <td class="num">{{ row.batchNo }}</td>
              <td>{{ row.crop }}</td>
              <td class="cell-muted">{{ row.agency }}</td>
              <td class="num">{{ row.testedAt }}</td>
              <td>
                <span class="tag" :class="row.pesticide === '未检出' ? 'tag--ok' : 'tag--danger'">{{ row.pesticide }}</span>
              </td>
              <td>
                <span class="tag" :class="row.heavyMetal === '合格' ? 'tag--ok' : 'tag--danger'">{{ row.heavyMetal }}</span>
              </td>
              <td><StatusTag :text="row.result" :tone="row.result === '合格' ? 'ok' : 'danger'" dot /></td>
              <td><button class="link-action" type="button" @click="viewFile(row)">查看附件</button></td>
              <td>
                <div class="table-actions">
                  <button class="link-action" type="button" @click="openDetail(row)">详情</button>
                  <button class="link-action" type="button" style="color: var(--danger)" @click="askDelete(row)">删除</button>
                </div>
              </td>
            </tr>
            <tr v-if="filtered.length === 0">
              <td colspan="10">
                <div class="empty">
                  <div class="empty__mark">空</div>
                  <span>没有符合条件的检测报告</span>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <AppModal v-model="detailOpen" title="检测报告详情" size="lg">
      <div v-if="selected">
        <div class="row row--between" style="margin-bottom: 14px">
          <div class="num" style="font-size: 16px; font-weight: 700">{{ selected.reportNo }}</div>
          <StatusTag :text="selected.result" :tone="selected.result === '合格' ? 'ok' : 'danger'" dot />
        </div>
        <div class="kv kv--3">
          <div class="kv__item"><span>批次号</span><b>{{ selected.batchNo }}</b></div>
          <div class="kv__item"><span>作物</span><b>{{ selected.crop }}</b></div>
          <div class="kv__item"><span>检测日期</span><b>{{ selected.testedAt }}</b></div>
          <div class="kv__item"><span>检测机构</span><b>{{ selected.agency }}</b></div>
          <div class="kv__item"><span>农药残留</span><b>{{ selected.pesticide }}</b></div>
          <div class="kv__item"><span>重金属</span><b>{{ selected.heavyMetal }}</b></div>
        </div>
        <div class="notice" :class="selected.result === '合格' ? 'notice--brand' : 'notice--danger'" style="margin-top: 16px">
          {{
            selected.result === '合格'
              ? '检测结论：农残未检出，重金属指标符合 GB 2762 限量要求，综合判定为合格，可用于溯源档案对外展示。'
              : '检测结论：农残指标超出内部验收标准，综合判定为不合格，建议暂停销售并启动召回评估。'
          }}
        </div>
        <div class="kv" style="margin-top: 16px">
          <div class="kv__item">
            <span>报告附件</span>
            <b>{{ selected.file }}</b>
          </div>
          <div class="kv__item">
            <span>归档状态</span>
            <b>{{ selected.result === '合格' ? '已归档至批次溯源档案' : '已标记异常待整改' }}</b>
          </div>
        </div>
      </div>
      <div class="form-foot">
        <button class="btn" type="button" @click="detailOpen = false">关闭</button>
        <button class="btn btn--primary" type="button" @click="selected && viewFile(selected)">下载报告</button>
      </div>
    </AppModal>

    <AppModal v-model="uploadOpen" title="上传检测报告" size="lg">
      <div class="form-grid">
        <label class="field">
          <span class="field__label">批次</span>
          <select v-model="form.batchNo" class="select">
            <option v-for="batch in batches" :key="batch.id" :value="batch.batchNo">
              {{ batch.batchNo }} · {{ batch.crop }}
            </option>
          </select>
        </label>
        <label class="field">
          <span class="field__label">检测机构</span>
          <input v-model="form.agency" class="input" type="text" placeholder="请输入检测机构名称" />
        </label>
        <label class="field">
          <span class="field__label">检测日期</span>
          <input v-model="form.testedAt" class="input" type="date" />
        </label>
        <label class="field">
          <span class="field__label">结论</span>
          <select v-model="form.result" class="select">
            <option value="合格">合格</option>
            <option value="不合格">不合格</option>
          </select>
        </label>
        <label class="field">
          <span class="field__label">农药残留</span>
          <input v-model="form.pesticide" class="input" type="text" placeholder="如 未检出 / 检出 0.03 mg/kg" />
        </label>
        <label class="field">
          <span class="field__label">重金属</span>
          <select v-model="form.heavyMetal" class="select">
            <option value="合格">合格</option>
            <option value="不合格">不合格</option>
          </select>
        </label>
        <label class="field span-2">
          <span class="field__label">附件文件名</span>
          <input v-model="form.file" class="input" type="text" placeholder="如 黄瓜检测报告_20261106.pdf" />
        </label>
        <div class="field span-2">
          <div class="notice">提交后报告将加入本地检测列表，并同步至对应批次的溯源档案。</div>
        </div>
      </div>
      <div class="form-foot">
        <button class="btn" type="button" @click="uploadOpen = false">取消</button>
        <button class="btn btn--primary" type="button" @click="submitUpload">提交报告</button>
      </div>
    </AppModal>

    <AppModal v-model="deleteOpen" title="删除检测报告">
      <div v-if="deleting">
        <p style="font-size: 13px; color: var(--ink-2)">
          确认删除报告 <b class="num">{{ deleting.reportNo }}</b>（批次 {{ deleting.batchNo }}）？
        </p>
        <div class="notice notice--warn" style="margin-top: 12px">删除后该报告将从批次溯源档案中移除，操作不可撤销。</div>
      </div>
      <div class="form-foot">
        <button class="btn" type="button" @click="deleteOpen = false">取消</button>
        <button class="btn btn--danger" type="button" @click="confirmDelete">确认删除</button>
      </div>
    </AppModal>
  </div>
</template>
