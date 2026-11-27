<script setup lang="ts">
import { computed, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import GisMap from '@/components/ui/GisMap.vue'
import { useToast } from '@/composables/useToast'
import { plotAudits as seedAudits, users } from '@/api/store'
import type { AuditStatus, Plot, PlotAudit } from '@/data/types'
import { formatAreaSqm, isBoundaryClosed, polygonAreaSqm } from '@/utils/geo'

const toast = useToast()

const rows = ref<PlotAudit[]>(seedAudits.map((item) => ({ ...item, polygon: item.polygon.map((p) => ({ ...p })) })))
const statusTab = ref<AuditStatus | ''>('')
const keyword = ref('')
const farmerFilter = ref('')

const farmerOptions = computed(() => Array.from(new Set(rows.value.map((item) => item.submitBy))))

const filtered = computed(() => {
  const kw = keyword.value.trim()
  return rows.value.filter((item) => {
    if (statusTab.value && item.status !== statusTab.value) return false
    if (farmerFilter.value && item.submitBy !== farmerFilter.value) return false
    if (!kw) return true
    return item.plotName.includes(kw) || item.plotCode.includes(kw) || item.crop.includes(kw)
  })
})

const pendingCount = computed(() => rows.value.filter((item) => item.status === '待审核').length)
const passedCount = computed(() => rows.value.filter((item) => item.status === '已通过').length)
const rejectedCount = computed(() => rows.value.filter((item) => item.status === '已驳回').length)
const unclosedCount = computed(() => rows.value.filter((item) => item.status === '待审核' && !item.boundaryClosed).length)

function statusTone(status: AuditStatus): 'warn' | 'ok' | 'danger' {
  if (status === '待审核') return 'warn'
  if (status === '已驳回') return 'danger'
  return 'ok'
}

const drawerOpen = ref(false)
const selectedId = ref(rows.value[0]?.id ?? '')
const selected = computed<PlotAudit | undefined>(() => rows.value.find((item) => item.id === selectedId.value))

const previewPlot = computed<Plot | undefined>(() => {
  const audit = selected.value
  if (!audit) return undefined
  return {
    id: audit.plotCode,
    code: audit.plotCode,
    name: audit.plotName,
    crop: audit.crop,
    variety: audit.variety,
    area: audit.area,
    greenhouse: audit.greenhouse,
    stage: '—',
    soil: '—',
    manager: audit.submitBy,
    plantedAt: '—',
    expectedHarvest: '—',
    status: audit.boundaryClosed ? '正常' : '预警',
    color: audit.boundaryClosed ? '#2f8f5b' : '#c9973f',
    polygon: audit.polygon,
  }
})

const assignFarmer = ref('')
const rejectReason = ref('')

/** GIS 校验：真实几何是否闭合、量算面积与申报面积偏差 */
const boundaryValid = computed(() => isBoundaryClosed(selected.value?.polygon ?? []))
const geometryArea = computed(() => polygonAreaSqm(selected.value?.polygon ?? []))
const areaDeviation = computed(() => {
  const declared = selected.value?.area ?? 0
  if (declared <= 0 || geometryArea.value <= 0) return 0
  return Math.abs(geometryArea.value / 666.6667 - declared) / declared
})

function openAudit(audit: PlotAudit) {
  selectedId.value = audit.id
  assignFarmer.value = audit.farmerId
  rejectReason.value = ''
  drawerOpen.value = true
}

function auditPass() {
  const audit = selected.value
  if (!audit) return
  if (!audit.boundaryClosed || !boundaryValid.value) {
    toast.error('GIS 边界未闭合或图形退化，无法通过审核')
    return
  }
  audit.status = '已通过'
  toast.success(`地块「${audit.plotName}」已审核通过并正式生效`)
  drawerOpen.value = false
}

function auditReject() {
  const audit = selected.value
  if (!audit) return
  if (!rejectReason.value.trim()) {
    toast.warn('请填写驳回原因')
    return
  }
  audit.status = '已驳回'
  audit.rejectReason = rejectReason.value.trim()
  toast.success(`地块「${audit.plotName}」已驳回，退回农户修改`)
  drawerOpen.value = false
}

function confirmAssign() {
  const audit = selected.value
  if (!audit) return
  const farmer = users.find((item) => item.id === assignFarmer.value)
  audit.farmerId = assignFarmer.value
  audit.submitBy = farmer?.name ?? audit.submitBy
  toast.success(`已指定归属农户：${farmer?.name ?? '未命名'}`)
}
</script>

<template>
  <div>
    <PageHeader eyebrow="PLOT AUDIT" title="地块档案审核" description="审核农户自助录入或变更的地块档案，校验边界闭合与面积作物一致性，指定归属农户">
      <template #actions>
        <span class="tag tag--brand">共 {{ rows.length }} 条提交记录</span>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="待审核" :value="pendingCount" unit="个" note="等待管理员处理" trend="今日新增 2" trend-up accent />
      <StatCard label="超时未审" :value="unclosedCount" unit="个" note="边界未闭合需退回" trend="需优先处理" :trend-up="false" />
      <StatCard label="已通过" :value="passedCount" unit="个" note="已正式生效" trend="审核通过率 75%" />
      <StatCard label="已驳回" :value="rejectedCount" unit="个" note="退回农户修改" trend="较上月下降" />
    </div>

    <section class="card">
      <div class="card__body" style="padding-bottom: 0">
        <div class="toolbar">
          <div class="field">
            <span class="field__label">审核状态</span>
            <select v-model="statusTab" class="select" style="width: 120px">
              <option value="">全部状态</option>
              <option value="待审核">待审核</option>
              <option value="已通过">已通过</option>
              <option value="已驳回">已驳回</option>
            </select>
          </div>
          <div class="field">
            <span class="field__label">提交农户</span>
            <select v-model="farmerFilter" class="select" style="width: 132px">
              <option value="">全部农户</option>
              <option v-for="farmer in farmerOptions" :key="farmer" :value="farmer">{{ farmer }}</option>
            </select>
          </div>
          <div class="field" style="flex: 1; min-width: 180px">
            <span class="field__label">关键词</span>
            <input v-model="keyword" class="input" placeholder="搜索地块名称 / 编号 / 作物" />
          </div>
          <button class="btn btn--sm" type="button" style="margin-top: 18px" @click="statusTab = ''; farmerFilter = ''; keyword = ''">重置筛选</button>
          <div class="toolbar__spacer" />
          <span class="tag" style="margin-top: 18px">筛选结果 {{ filtered.length }} 条</span>
        </div>

        <div class="table-wrap">
          <table class="data-table">
            <thead>
              <tr>
                <th>编号</th>
                <th>地块名称</th>
                <th>作物</th>
                <th>面积</th>
                <th>提交农户</th>
                <th>提交时间</th>
                <th>边界</th>
                <th>状态</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="audit in filtered" :key="audit.id" :class="{ 'is-selected': audit.id === selectedId }" @click="openAudit(audit)">
                <td class="num cell-strong">{{ audit.plotCode }}</td>
                <td class="cell-strong">{{ audit.plotName }}</td>
                <td>{{ audit.crop }} · {{ audit.variety }}</td>
                <td class="num">{{ audit.area }} 亩</td>
                <td>{{ audit.submitBy }}</td>
                <td class="num">{{ audit.submittedAt }}</td>
                <td>
                  <span class="tag" :class="audit.boundaryClosed ? 'tag--ok' : 'tag--danger'">{{ audit.boundaryClosed ? '闭合' : '未闭合' }}</span>
                </td>
                <td><StatusTag :text="audit.status" :tone="statusTone(audit.status)" dot /></td>
                <td>
                  <div class="table-actions" @click.stop>
                    <button class="btn btn--sm" type="button" @click="openAudit(audit)">{{ audit.status === '待审核' ? '审核' : '查看' }}</button>
                  </div>
                </td>
              </tr>
              <tr v-if="filtered.length === 0">
                <td colspan="9">
                  <div class="empty"><span class="empty__mark">空</span>暂无符合条件的地块提交记录</div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>

    <section class="card" style="margin-top: 16px">
      <div class="card__head">
        <div class="card__title">审核记录</div>
        <span class="card__sub">审核全过程留存操作日志，用于事后追溯</span>
      </div>
      <div class="card__body">
        <div class="timeline">
          <div v-for="audit in rows.filter((item) => item.status !== '待审核')" :key="audit.id" class="timeline__item">
            <span class="dot" :class="audit.status === '已通过' ? 'dot--ok' : 'dot--danger'" />
            <div>
              <b>{{ audit.plotName }}（{{ audit.plotCode }}）</b>
              <span class="cell-muted">{{ audit.submittedAt }} 提交 · 管理员已{{ audit.status === '已通过' ? '通过' : '驳回' }}</span>
              <span v-if="audit.rejectReason" class="timeline__reason">驳回原因：{{ audit.rejectReason }}</span>
            </div>
          </div>
        </div>
      </div>
    </section>

    <AppModal v-model="drawerOpen" :title="`地块审核 · ${selected?.plotName ?? ''}`" size="lg">
      <div class="audit-grid">
        <div>
          <div class="audit-block-title">GIS 边界预览（真实底图）</div>
          <GisMap
            v-if="previewPlot"
            :plots="[previewPlot]"
            :devices="[]"
            :show-devices="false"
            :height="248"
            :zoom="17"
            :show-coords="false"
          />
          <div class="kv" style="margin-top: 10px">
            <div class="kv__item"><span>边界顶点</span><b>{{ selected?.polygon.length ?? 0 }} 个</b></div>
            <div class="kv__item"><span>图形量算</span><b>{{ formatAreaSqm(geometryArea) }}</b></div>
            <div class="kv__item"><span>申报面积</span><b>{{ selected?.area }} 亩</b></div>
            <div class="kv__item">
              <span>面积偏差</span>
              <b :style="{ color: areaDeviation > 0.15 ? 'var(--danger)' : 'var(--success)' }">
                {{ (areaDeviation * 100).toFixed(1) }}%
              </b>
            </div>
          </div>
          <div v-if="selected && (!selected.boundaryClosed || !boundaryValid)" class="notice notice--danger" style="margin-top: 10px">
            <span>该地块边界未闭合或图形退化，无法通过审核，需驳回并退回农户重新绘制。</span>
          </div>
          <div v-else-if="areaDeviation > 0.15" class="notice notice--warn" style="margin-top: 10px">
            <span>图形量算面积与申报面积偏差超过 15%，建议现场复核后再通过。</span>
          </div>
        </div>
        <div>
          <div class="audit-block-title">档案信息</div>
          <div class="kv">
            <div class="kv__item"><span>地块编号</span><b>{{ selected?.plotCode }}</b></div>
            <div class="kv__item"><span>地块名称</span><b>{{ selected?.plotName }}</b></div>
            <div class="kv__item"><span>种植作物</span><b>{{ selected?.crop }} · {{ selected?.variety }}</b></div>
            <div class="kv__item"><span>地块面积</span><b>{{ selected?.area }} 亩</b></div>
            <div class="kv__item"><span>温室类型</span><b>{{ selected?.greenhouse }}</b></div>
            <div class="kv__item"><span>提交农户</span><b>{{ selected?.submitBy }}</b></div>
            <div class="kv__item"><span>提交时间</span><b>{{ selected?.submittedAt }}</b></div>
            <div class="kv__item"><span>审核状态</span><b>{{ selected?.status }}</b></div>
          </div>
        </div>
      </div>

      <template v-if="selected?.status === '待审核'">
        <div class="audit-block-title" style="margin-top: 16px">归属农户与审核意见</div>
        <div class="form-grid">
          <label class="field">
            <span class="field__label">归属农户</span>
            <select v-model="assignFarmer" class="select">
              <option v-for="user in users.filter((u) => u.role === '农户')" :key="user.id" :value="user.id">{{ user.name }}（{{ user.plotScope }}）</option>
            </select>
          </label>
          <label class="field">
            <span class="field__label">驳回原因（驳回时填写）</span>
            <input v-model="rejectReason" class="input" placeholder="如：边界未闭合 / 面积与作物不一致" />
          </label>
        </div>
        <div class="audit-actions" style="margin-top: 16px">
          <button class="btn btn--sm" type="button" @click="confirmAssign">分配农户</button>
          <button class="btn btn--sm btn--danger" type="button" @click="auditReject">驳回</button>
          <button class="btn btn--sm btn--primary" type="button" @click="auditPass">审核通过</button>
        </div>
      </template>
    </AppModal>
  </div>
</template>

<style scoped>
.data-table tbody tr.is-selected {
  background: var(--brand-soft);
}

.audit-grid {
  display: grid;
  grid-template-columns: 1.1fr 1fr;
  gap: 18px;
}

.audit-block-title {
  margin-bottom: 8px;
  font-size: 12px;
  font-weight: 650;
  color: var(--ink-2);
}

.audit-actions {
  display: flex;
  justify-content: flex-end;
  gap: 8px;
}

.timeline {
  display: grid;
  gap: 10px;
}

.timeline__item {
  display: flex;
  gap: 10px;
  align-items: flex-start;
  padding: 8px 0;
  border-bottom: 1px dashed var(--line);
  font-size: 12px;
  color: var(--ink-2);
}

.timeline__item:last-child {
  border-bottom: 0;
}

.timeline__item b {
  display: block;
  color: var(--ink);
}

.timeline__item .cell-muted {
  font-size: 11px;
}

.timeline__reason {
  display: block;
  margin-top: 2px;
  font-size: 11px;
  color: var(--danger);
}

@media (max-width: 900px) {
  .audit-grid {
    grid-template-columns: 1fr;
  }
}
</style>
