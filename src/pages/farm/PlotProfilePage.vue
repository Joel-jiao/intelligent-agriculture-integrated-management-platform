<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import GisMap from '@/components/ui/GisMap.vue'
import { useToast } from '@/composables/useToast'
import { ApiError } from '@/api/http'
import { ENDPOINTS, createResource, deleteResource, updateResource } from '@/api/endpoints'
import { devices, plots } from '@/api/store'
import type { MapPoint, Plot } from '@/data/types'
import { buildCsv, downloadText, formatNumber, pad } from '@/utils/format'
import { formatAreaSqm, polygonAreaSqm, type DrawnBoundary } from '@/utils/geo'

const toast = useToast()

/** 直接使用全局数据仓库，写操作成功后同步刷新，避免页面内出现第二份副本 */
const plotList = plots
const mapRef = ref<InstanceType<typeof GisMap> | null>(null)

const selectedId = ref(plotList[0]?.id ?? '')
const keyword = ref('')
const statusFilter = ref('全部')
const cropFilter = ref('全部')

watch(
  () => plotList.map((plot) => plot.id).join(','),
  () => {
    if (!plotList.some((plot) => plot.id === selectedId.value)) selectedId.value = plotList[0]?.id ?? ''
  },
)

const cropOptions = computed(() => Array.from(new Set(plotList.map((item) => item.crop))))

const selectedPlot = computed<Plot | undefined>(() => plotList.find((item) => item.id === selectedId.value))

const filteredPlots = computed(() =>
  plotList.filter((plot) => {
    if (statusFilter.value !== '全部' && plot.status !== statusFilter.value) return false
    if (cropFilter.value !== '全部' && plot.crop !== cropFilter.value) return false
    if (!keyword.value.trim()) return true
    const key = keyword.value.trim()
    return plot.name.includes(key) || plot.code.includes(key) || plot.manager.includes(key) || plot.crop.includes(key)
  }),
)

const totalArea = computed(() => plotList.reduce((sum, plot) => sum + plot.area, 0))
const totalGeometryArea = computed(() => plotList.reduce((sum, plot) => sum + polygonAreaSqm(plot.polygon), 0))
const warningCount = computed(() => plotList.filter((plot) => plot.status === '预警').length)
const greenhouseCount = computed(() => plotList.filter((plot) => plot.greenhouse !== '露天种植').length)

function statusTone(status: Plot['status']): 'ok' | 'warn' | 'mute' {
  if (status === '预警') return 'warn'
  if (status === '休耕') return 'mute'
  return 'ok'
}

const plotDevices = computed(() => devices.filter((device) => device.plotId === selectedId.value))

function locatePlot(id: string) {
  selectedId.value = id
  mapRef.value?.fitToPlot(id)
}

/* ------------------------------ 新增 / 编辑 ------------------------------ */

const modalOpen = ref(false)
const saving = ref(false)
const editingId = ref('')
const modalMapRef = ref<InstanceType<typeof GisMap> | null>(null)

interface PlotForm {
  name: string
  crop: string
  variety: string
  area: string
  greenhouse: string
  stage: string
  soil: string
  manager: string
  plantedAt: string
  expectedHarvest: string
  polygon: MapPoint[]
}

function emptyForm(): PlotForm {
  return {
    name: '',
    crop: '',
    variety: '',
    area: '',
    greenhouse: '连栋薄膜温室',
    stage: '苗期',
    soil: '壤土',
    manager: '',
    plantedAt: '2026-11-06',
    expectedHarvest: '2027-02-01',
    polygon: [],
  }
}

const form = ref<PlotForm>(emptyForm())
const formGeometryArea = computed(() => polygonAreaSqm(form.value.polygon))

const deleteOpen = ref(false)
const deleteTarget = ref<Plot | null>(null)

const palette = ['#4fae74', '#d56b6b', '#3d8f5c', '#c9973f', '#6a9e3f', '#8fb05f', '#2f6fae']

function nextCode(): string {
  const max = plotList.reduce((acc, plot) => {
    const value = Number(plot.code.replace('P-', ''))
    return Number.isNaN(value) ? acc : Math.max(acc, value)
  }, 0)
  return `P-${pad(max + 1)}`
}

function openCreate() {
  editingId.value = ''
  form.value = emptyForm()
  modalOpen.value = true
}

function openEdit(plot: Plot | undefined) {
  if (!plot) return
  editingId.value = plot.id
  form.value = {
    name: plot.name,
    crop: plot.crop,
    variety: plot.variety,
    area: String(plot.area),
    greenhouse: plot.greenhouse,
    stage: plot.stage,
    soil: plot.soil,
    manager: plot.manager,
    plantedAt: plot.plantedAt,
    expectedHarvest: plot.expectedHarvest,
    polygon: plot.polygon.map((point) => ({ ...point })),
  }
  modalOpen.value = true
}

function onModalMapReady() {
  if (editingId.value) modalMapRef.value?.fitToPlot(editingId.value)
}

/** 绘制完成：面积按球面几何自动回填，用户仍可手工微调 */
function onBoundaryDrawn(boundary: DrawnBoundary) {
  form.value.polygon = boundary.polygon
  form.value.area = boundary.areaMu.toFixed(2)
  toast.success(`边界已绘制：${boundary.polygon.length} 个顶点 · ${boundary.areaMu.toFixed(2)} 亩`)
}

function clearBoundary() {
  form.value.polygon = []
}

async function submitPlot() {
  const area = Number(form.value.area)
  if (!form.value.name.trim() || !form.value.crop.trim()) {
    toast.warn('请填写地块名称与种植作物')
    return
  }
  if (Number.isNaN(area) || area <= 0) {
    toast.warn('地块面积需为大于 0 的数字')
    return
  }
  if (!form.value.manager.trim()) {
    toast.warn('请指定地块负责人')
    return
  }
  if (form.value.polygon.length < 3) {
    toast.warn('请在地图上绘制闭合的地块边界，GIS 档案需要真实图形')
    return
  }

  const base = {
    name: form.value.name.trim(),
    crop: form.value.crop.trim(),
    variety: form.value.variety.trim() || '未填写',
    area,
    greenhouse: form.value.greenhouse,
    stage: form.value.stage,
    soil: form.value.soil,
    manager: form.value.manager.trim(),
    plantedAt: form.value.plantedAt,
    expectedHarvest: form.value.expectedHarvest,
    polygon: form.value.polygon,
  }

  saving.value = true
  try {
    if (editingId.value) {
      const updated = await updateResource<Plot>(ENDPOINTS.plots, editingId.value, base)
      const index = plotList.findIndex((item) => item.id === editingId.value)
      if (index >= 0) {
        Object.assign(plotList[index] as Plot, updated ?? base)
      }
      toast.success(`地块「${base.name}」档案已更新并落库`)
    } else {
      const code = nextCode()
      const payload = {
        ...base,
        id: code,
        code,
        status: '正常' as const,
        color: palette[plotList.length % palette.length] ?? '#4fae74',
      }
      await createResource<Plot>(ENDPOINTS.plots, payload)
      plotList.push(payload as Plot)
      selectedId.value = code
      mapRef.value?.fitToPlot(code)
      toast.success(`地块「${payload.name}」已创建，编号 ${code}`)
    }
    modalOpen.value = false
  } catch (error) {
    toast.error(error instanceof ApiError ? error.message : '保存失败，请稍后重试')
  } finally {
    saving.value = false
  }
}

function askDelete(plot: Plot | undefined) {
  if (!plot) return
  deleteTarget.value = plot
  deleteOpen.value = true
}

async function confirmDelete() {
  const target = deleteTarget.value
  if (!target) return
  saving.value = true
  try {
    await deleteResource(ENDPOINTS.plots, target.id)
    const index = plotList.findIndex((item) => item.id === target.id)
    if (index >= 0) plotList.splice(index, 1)
    toast.success(`地块「${target.name}」已删除`)
    deleteOpen.value = false
    deleteTarget.value = null
  } catch (error) {
    toast.error(error instanceof ApiError ? error.message : '删除失败，请稍后重试')
  } finally {
    saving.value = false
  }
}

function exportPlots() {
  const rows = filteredPlots.value.map((plot) => [
    plot.code,
    plot.name,
    plot.crop,
    plot.variety,
    plot.area,
    polygonAreaSqm(plot.polygon).toFixed(2),
    plot.greenhouse,
    plot.stage,
    plot.soil,
    plot.manager,
    plot.plantedAt,
    plot.expectedHarvest,
    plot.status,
  ])
  downloadText(
    '地块档案_20261106.csv',
    buildCsv(
      ['编号', '名称', '作物', '品种', '档案面积(亩)', '图形面积(㎡)', '温室类型', '生育期', '土壤', '负责人', '定植日期', '预计采收', '状态'],
      rows,
    ),
  )
  toast.success(`已导出 ${rows.length} 条地块档案`)
}
</script>

<template>
  <div>
    <PageHeader eyebrow="FARM GIS" title="GIS 地块管理" :description="'真实底图上的园区地块分布、作物档案与责任人统管 · 共 ' + plotList.length + ' 个地块'">
      <template #actions>
        <button class="btn" type="button" @click="exportPlots">导出地块</button>
        <button class="btn btn--primary" type="button" @click="openCreate">新增地块</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="地块数量" :value="plotList.length" unit="个" :note="`温室 ${greenhouseCount} 个 · 露天 ${plotList.length - greenhouseCount} 个`" trend="档案完整率 100%" />
      <StatCard label="档案总面积" :value="formatNumber(totalArea, 1)" unit="亩" :note="`图形量算 ${formatAreaSqm(totalGeometryArea)}`" trend="按户均分摊" />
      <StatCard label="预警地块" :value="warningCount" unit="个" note="需重点巡查的作物地块" trend="较昨日持平" :trend-up="false" accent />
      <StatCard label="接入设备" :value="devices.length" unit="台" note="水泵、风机、卷帘与传感器" trend="在线率 90%" />
    </div>

    <div class="grid grid--main">
      <div class="stack">
        <section class="card">
          <div class="card__head">
            <div class="card__title">
              园区地块分布
              <span class="card__sub">高德真实底图 · 支持缩放漫游，点击地块可查看详情</span>
            </div>
            <div class="row" style="gap: 6px">
              <StatusTag :text="`${filteredPlots.length} 个地块`" tone="brand" dot />
              <button class="btn btn--sm" type="button" @click="mapRef?.fitAll()">全园视野</button>
            </div>
          </div>
          <div class="card__body">
            <GisMap
              ref="mapRef"
              :plots="plotList"
              :devices="devices"
              :selected-id="selectedId"
              :height="360"
              :zoom="16"
              @select-plot="selectedId = $event"
            />
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">地块列表</div>
            <button class="link-action" type="button" @click="keyword = ''; statusFilter = '全部'; cropFilter = '全部'">重置筛选</button>
          </div>
          <div class="card__body">
            <div class="toolbar">
              <label class="field" style="flex: 1; min-width: 180px">
                <span class="field__label">关键词</span>
                <input v-model="keyword" class="input" type="text" placeholder="地块名称 / 编号 / 负责人" />
              </label>
              <label class="field" style="width: 140px">
                <span class="field__label">地块状态</span>
                <select v-model="statusFilter" class="select">
                  <option value="全部">全部状态</option>
                  <option value="正常">正常</option>
                  <option value="预警">预警</option>
                  <option value="休耕">休耕</option>
                </select>
              </label>
              <label class="field" style="width: 140px">
                <span class="field__label">作物</span>
                <select v-model="cropFilter" class="select">
                  <option value="全部">全部作物</option>
                  <option v-for="crop in cropOptions" :key="crop" :value="crop">{{ crop }}</option>
                </select>
              </label>
            </div>

            <div class="table-wrap">
              <table class="data-table">
                <thead>
                  <tr>
                    <th>编号</th>
                    <th>地块名称</th>
                    <th>作物</th>
                    <th>面积</th>
                    <th>图形面积</th>
                    <th>负责人</th>
                    <th>状态</th>
                    <th>操作</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-if="filteredPlots.length === 0">
                    <td colspan="8">
                      <div class="empty">
                        <span class="empty__mark">空</span>
                        当前筛选条件下没有地块
                      </div>
                    </td>
                  </tr>
                  <tr v-for="plot in filteredPlots" :key="plot.id" :class="{ 'is-selected': plot.id === selectedId }" @click="selectedId = plot.id">
                    <td class="num cell-strong">{{ plot.code }}</td>
                    <td class="cell-strong">{{ plot.name }}</td>
                    <td>{{ plot.crop }} · {{ plot.variety }}</td>
                    <td class="num">{{ formatNumber(plot.area, 1) }} 亩</td>
                    <td class="num">{{ formatAreaSqm(polygonAreaSqm(plot.polygon)) }}</td>
                    <td>{{ plot.manager }}</td>
                    <td><StatusTag :text="plot.status" :tone="statusTone(plot.status)" dot /></td>
                    <td>
                      <div class="table-actions" @click.stop>
                        <button class="btn btn--sm" type="button" @click="locatePlot(plot.id)">定位</button>
                        <button class="btn btn--sm" type="button" @click="openEdit(plot)">编辑</button>
                        <button class="btn btn--sm btn--danger" type="button" @click="askDelete(plot)">删除</button>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </section>
      </div>

      <div class="stack">
        <section v-if="selectedPlot" class="card card--tint">
          <div class="card__head">
            <div class="card__title">{{ selectedPlot.name }}</div>
            <StatusTag :text="selectedPlot.status" :tone="statusTone(selectedPlot.status)" dot />
          </div>
          <div class="card__body">
            <div class="row row--between" style="margin-bottom: 14px">
              <div>
                <div class="plot-code">{{ selectedPlot.code }}</div>
                <div style="font-size: 11.5px; color: var(--muted)">{{ selectedPlot.greenhouse }} · {{ selectedPlot.stage }}</div>
              </div>
              <div class="row" style="gap: 6px">
                <button class="btn btn--sm" type="button" @click="locatePlot(selectedPlot.id)">定位</button>
                <button class="btn btn--sm" type="button" @click="openEdit(selectedPlot)">编辑</button>
                <button class="btn btn--sm btn--danger" type="button" @click="askDelete(selectedPlot)">删除</button>
              </div>
            </div>

            <div class="kv">
              <div class="kv__item"><span>种植作物</span><b>{{ selectedPlot.crop }}</b></div>
              <div class="kv__item"><span>品种</span><b>{{ selectedPlot.variety }}</b></div>
              <div class="kv__item"><span>档案面积</span><b>{{ formatNumber(selectedPlot.area, 1) }} 亩</b></div>
              <div class="kv__item"><span>图形面积</span><b>{{ formatAreaSqm(polygonAreaSqm(selectedPlot.polygon)) }}</b></div>
              <div class="kv__item"><span>边界顶点</span><b>{{ selectedPlot.polygon.length }} 个</b></div>
              <div class="kv__item"><span>温室类型</span><b>{{ selectedPlot.greenhouse }}</b></div>
              <div class="kv__item"><span>生育期</span><b>{{ selectedPlot.stage }}</b></div>
              <div class="kv__item"><span>土壤类型</span><b>{{ selectedPlot.soil }}</b></div>
              <div class="kv__item"><span>负责人</span><b>{{ selectedPlot.manager }}</b></div>
              <div class="kv__item"><span>地块状态</span><b>{{ selectedPlot.status }}</b></div>
              <div class="kv__item"><span>定植日期</span><b>{{ selectedPlot.plantedAt }}</b></div>
              <div class="kv__item"><span>预计采收</span><b>{{ selectedPlot.expectedHarvest }}</b></div>
            </div>

            <div class="notice" style="margin-top: 16px">
              <span>该地块共接入 {{ plotDevices.length }} 台设备，作物进入{{ selectedPlot.stage }}，建议按水肥一体化方案执行日常管理。</span>
            </div>

            <div v-if="plotDevices.length" class="device-list">
              <div v-for="device in plotDevices.slice(0, 4)" :key="device.id" class="device-list__item">
                <span class="dot" :class="device.status === '在线' ? 'dot--ok' : 'dot--danger'" />
                <span style="flex: 1; min-width: 0">{{ device.name }}</span>
                <span class="tag" :class="device.status === '在线' ? 'tag--ok' : 'tag--danger'">{{ device.status }}</span>
              </div>
            </div>
          </div>
        </section>

        <section v-else class="card">
          <div class="card__body">
            <div class="empty">
              <span class="empty__mark">地</span>
              暂无地块，可通过「新增地块」建立档案
            </div>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">管理提示</div>
          </div>
          <div class="card__body" style="display: grid; gap: 10px">
            <div class="notice notice--brand">新增或编辑地块时必须绘制闭合边界，图形面积由球面几何实时量算，可直接用于补贴与流转核算。</div>
            <div class="notice notice--warn">预警地块需在当日完成现场巡查，并在工单中上传处置照片。</div>
          </div>
        </section>
      </div>
    </div>

    <AppModal v-model="modalOpen" :title="editingId ? '编辑地块档案' : '新增地块'" size="lg">
      <div class="boundary-block">
        <div class="boundary-block__head">
          <div class="audit-block-title">GIS 边界</div>
          <div class="row" style="gap: 8px">
            <span class="tag" :class="form.polygon.length >= 3 ? 'tag--ok' : 'tag--warn'">
              {{ form.polygon.length >= 3 ? `已闭合 · ${form.polygon.length} 顶点 · ${formatAreaSqm(formGeometryArea)}` : '未绘制边界' }}
            </span>
            <button v-if="form.polygon.length > 0" class="link-action" type="button" @click="clearBoundary">清除</button>
          </div>
        </div>
        <GisMap
          ref="modalMapRef"
          :plots="plotList"
          :devices="[]"
          :show-devices="false"
          :selected-id="editingId"
          :drawable="true"
          :pending="form.polygon"
          :height="286"
          :show-coords="false"
          :hide-legend="true"
          @draw-complete="onBoundaryDrawn"
          @ready="onModalMapReady"
        />
        <div class="boundary-block__tip">点击地图上的「绘制边界」逐个落点圈画，回到首个顶点或点「完成」闭合，面积自动回填</div>
      </div>

      <div class="form-grid" style="margin-top: 16px">
        <label class="field">
          <span class="field__label">地块名称</span>
          <input v-model="form.name" class="input" type="text" placeholder="如：4号番茄棚" />
        </label>
        <label class="field">
          <span class="field__label">种植作物</span>
          <input v-model="form.crop" class="input" type="text" placeholder="如：番茄" />
        </label>
        <label class="field">
          <span class="field__label">品种</span>
          <input v-model="form.variety" class="input" type="text" placeholder="如：云粉 9 号" />
        </label>
        <label class="field">
          <span class="field__label">面积（亩）</span>
          <input v-model="form.area" class="input" type="number" min="0" step="0.01" placeholder="0.00" />
        </label>
        <label class="field">
          <span class="field__label">温室类型</span>
          <select v-model="form.greenhouse" class="select">
            <option value="连栋薄膜温室">连栋薄膜温室</option>
            <option value="日光温室">日光温室</option>
            <option value="育苗温室">育苗温室</option>
            <option value="露天种植">露天种植</option>
          </select>
        </label>
        <label class="field">
          <span class="field__label">生育期</span>
          <select v-model="form.stage" class="select">
            <option value="苗期">苗期</option>
            <option value="开花期">开花期</option>
            <option value="结果期">结果期</option>
            <option value="果实膨大期">果实膨大期</option>
            <option value="采收期">采收期</option>
            <option value="灌浆期">灌浆期</option>
            <option value="休耕期">休耕期</option>
          </select>
        </label>
        <label class="field">
          <span class="field__label">土壤类型</span>
          <input v-model="form.soil" class="input" type="text" placeholder="如：壤土" />
        </label>
        <label class="field">
          <span class="field__label">负责人</span>
          <input v-model="form.manager" class="input" type="text" placeholder="如：王强" />
        </label>
        <label class="field">
          <span class="field__label">定植日期</span>
          <input v-model="form.plantedAt" class="input" type="date" />
        </label>
        <label class="field">
          <span class="field__label">预计采收</span>
          <input v-model="form.expectedHarvest" class="input" type="date" />
        </label>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="modalOpen = false">取消</button>
        <button class="btn btn--primary" type="button" :disabled="saving" @click="submitPlot">
          {{ saving ? '保存中…' : editingId ? '保存修改' : '创建地块' }}
        </button>
      </template>
    </AppModal>

    <AppModal v-model="deleteOpen" title="删除地块">
      <div class="notice notice--danger" style="margin-bottom: 12px">删除后该地块将从地图与档案列表中移除，关联设备需重新指派。</div>
      <p style="font-size: 13px">确认删除地块「{{ deleteTarget?.name }}」吗？</p>
      <template #footer>
        <button class="btn" type="button" @click="deleteOpen = false">取消</button>
        <button class="btn btn--danger" type="button" :disabled="saving" @click="confirmDelete">确认删除</button>
      </template>
    </AppModal>
  </div>
</template>

<style scoped>
.plot-code {
  font-family: var(--font-num), monospace;
  font-size: 20px;
  font-weight: 700;
  color: var(--brand-dark);
  letter-spacing: 0.5px;
}

.device-list {
  display: grid;
  gap: 7px;
  margin-top: 12px;
}

.device-list__item {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 7px 10px;
  border: 1px solid var(--line);
  border-radius: 7px;
  background: rgba(255, 255, 255, 0.72);
  font-size: 12px;
  color: var(--ink-2);
}

.data-table tbody tr.is-selected {
  background: var(--brand-soft);
}

.boundary-block__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  margin-bottom: 8px;
}

.boundary-block__tip {
  margin-top: 8px;
  font-size: 10.5px;
  color: var(--text-tertiary);
}
</style>
