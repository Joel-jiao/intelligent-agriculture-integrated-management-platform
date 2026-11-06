<script setup lang="ts">
import { computed, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import GisMap from '@/components/ui/GisMap.vue'
import { useToast } from '@/composables/useToast'
import { devices, plots as seedPlots } from '@/data/mock'
import type { MapPoint, Plot } from '@/data/types'
import { buildCsv, downloadText, formatNumber, pad } from '@/utils/format'

const toast = useToast()

const plotList = ref<Plot[]>(
  seedPlots.map((item) => ({
    ...item,
    polygon: item.polygon.map((point) => ({ ...point })),
  })),
)

const selectedId = ref(plotList.value[0]?.id ?? '')
const keyword = ref('')
const statusFilter = ref('全部')
const cropFilter = ref('全部')

const cropOptions = computed(() => Array.from(new Set(plotList.value.map((item) => item.crop))))

const selectedPlot = computed<Plot | undefined>(() => plotList.value.find((item) => item.id === selectedId.value))

const filteredPlots = computed(() =>
  plotList.value.filter((plot) => {
    if (statusFilter.value !== '全部' && plot.status !== statusFilter.value) return false
    if (cropFilter.value !== '全部' && plot.crop !== cropFilter.value) return false
    if (!keyword.value.trim()) return true
    const key = keyword.value.trim()
    return plot.name.includes(key) || plot.code.includes(key) || plot.manager.includes(key) || plot.crop.includes(key)
  }),
)

const totalArea = computed(() => plotList.value.reduce((sum, plot) => sum + plot.area, 0))
const warningCount = computed(() => plotList.value.filter((plot) => plot.status === '预警').length)
const greenhouseCount = computed(() => plotList.value.filter((plot) => plot.greenhouse !== '露天种植').length)

function statusTone(status: Plot['status']): 'ok' | 'warn' | 'mute' {
  if (status === '预警') return 'warn'
  if (status === '休耕') return 'mute'
  return 'ok'
}

const plotDevices = computed(() => devices.filter((device) => device.plotId === selectedId.value))

const modalOpen = ref(false)
const editingId = ref('')
const form = ref({
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
})

const deleteOpen = ref(false)
const deleteTarget = ref<Plot | null>(null)

const palette = ['#4fae74', '#d56b6b', '#3d8f5c', '#c9973f', '#6a9e3f', '#8fb05f', '#2f6fae']

function nextCode(): string {
  const max = plotList.value.reduce((acc, plot) => {
    const value = Number(plot.code.replace('P-', ''))
    return Number.isNaN(value) ? acc : Math.max(acc, value)
  }, 0)
  return `P-${pad(max + 1)}`
}

function makePolygon(index: number): MapPoint[] {
  const col = index % 3
  const row = Math.floor(index / 3) % 2
  const x = 70 + col * 300
  const y = 90 + row * 230
  return [
    { x, y },
    { x: x + 236, y: y - 6 },
    { x: x + 246, y: y + 150 },
    { x: x + 10, y: y + 156 },
  ]
}

function openCreate() {
  editingId.value = ''
  form.value = {
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
  }
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
  }
  modalOpen.value = true
}

function submitPlot() {
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

  if (editingId.value) {
    const index = plotList.value.findIndex((item) => item.id === editingId.value)
    const current = plotList.value[index]
    if (current) {
      plotList.value[index] = {
        ...current,
        name: form.value.name.trim(),
        crop: form.value.crop.trim(),
        variety: form.value.variety.trim(),
        area,
        greenhouse: form.value.greenhouse,
        stage: form.value.stage,
        soil: form.value.soil,
        manager: form.value.manager.trim(),
        plantedAt: form.value.plantedAt,
        expectedHarvest: form.value.expectedHarvest,
      }
    }
    toast.success(`地块「${form.value.name.trim()}」档案已更新`)
  } else {
    const code = nextCode()
    const created: Plot = {
      id: code,
      code,
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
      status: '正常',
      color: palette[plotList.value.length % palette.length] ?? '#4fae74',
      polygon: makePolygon(plotList.value.length),
    }
    plotList.value.push(created)
    selectedId.value = created.id
    toast.success(`地块「${created.name}」已创建，编号 ${code}`)
  }
  modalOpen.value = false
}

function askDelete(plot: Plot | undefined) {
  if (!plot) return
  deleteTarget.value = plot
  deleteOpen.value = true
}

function confirmDelete() {
  const target = deleteTarget.value
  if (!target) return
  plotList.value = plotList.value.filter((item) => item.id !== target.id)
  if (selectedId.value === target.id) selectedId.value = plotList.value[0]?.id ?? ''
  deleteOpen.value = false
  toast.success(`地块「${target.name}」已删除`)
  deleteTarget.value = null
}

function exportPlots() {
  const rows = filteredPlots.value.map((plot) => [
    plot.code,
    plot.name,
    plot.crop,
    plot.variety,
    plot.area,
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
    buildCsv(['编号', '名称', '作物', '品种', '面积(亩)', '温室类型', '生育期', '土壤', '负责人', '定植日期', '预计采收', '状态'], rows),
  )
  toast.success(`已导出 ${rows.length} 条地块档案`)
}
</script>

<template>
  <div>
    <PageHeader eyebrow="FARM GIS" title="GIS 地块管理" description="园区地块分布、作物档案与责任人一图统管 · 共 {{ plotList.length }} 个地块">
      <template #actions>
        <button class="btn" type="button" @click="exportPlots">导出地块</button>
        <button class="btn btn--primary" type="button" @click="openCreate">新增地块</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="地块数量" :value="plotList.length" unit="个" icon="地" :note="`温室 ${greenhouseCount} 个 · 露天 ${plotList.length - greenhouseCount} 个`" trend="档案完整率 100%" />
      <StatCard label="种植总面积" :value="formatNumber(totalArea, 1)" unit="亩" icon="亩" note="园区规划面积 286 亩" trend="+2.4% 环比" />
      <StatCard label="预警地块" :value="warningCount" unit="个" icon="警" note="需重点巡查的作物地块" trend="较昨日持平" :trend-up="false" accent />
      <StatCard label="接入设备" :value="devices.length" unit="台" icon="设" note="水泵、风机、卷帘与传感器" trend="在线率 90%" />
    </div>

    <div class="grid grid--main">
      <div class="stack">
        <section class="card">
          <div class="card__head">
            <div class="card__title">园区地块分布 <span class="card__sub">点击色块可查看地块详情</span></div>
            <StatusTag :text="`${filteredPlots.length} 个地块`" tone="brand" dot />
          </div>
          <div class="card__body">
            <GisMap :plots="plotList" :devices="devices" :selected-id="selectedId" :height="330" @select-plot="selectedId = $event" />
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
                    <th>负责人</th>
                    <th>状态</th>
                    <th>操作</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-if="filteredPlots.length === 0">
                    <td colspan="7">
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
                    <td>{{ plot.manager }}</td>
                    <td><StatusTag :text="plot.status" :tone="statusTone(plot.status)" dot /></td>
                    <td>
                      <div class="table-actions" @click.stop>
                        <button class="btn btn--sm" type="button" @click="selectedId = plot.id">定位</button>
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
                <button class="btn btn--sm" type="button" @click="openEdit(selectedPlot)">编辑</button>
                <button class="btn btn--sm btn--danger" type="button" @click="askDelete(selectedPlot)">删除</button>
              </div>
            </div>

            <div class="kv">
              <div class="kv__item"><span>种植作物</span><b>{{ selectedPlot.crop }}</b></div>
              <div class="kv__item"><span>品种</span><b>{{ selectedPlot.variety }}</b></div>
              <div class="kv__item"><span>地块面积</span><b>{{ formatNumber(selectedPlot.area, 1) }} 亩</b></div>
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
            <div class="notice notice--brand">地块档案变更后，工单派发与采收登记将同步引用最新作物与负责人信息。</div>
            <div class="notice notice--warn">预警地块需在当日完成现场巡查，并在工单中上传处置照片。</div>
          </div>
        </section>
      </div>
    </div>

    <AppModal v-model="modalOpen" :title="editingId ? '编辑地块档案' : '新增地块'" size="lg">
      <div class="form-grid">
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
          <input v-model="form.area" class="input" type="number" min="0" step="0.1" placeholder="0.0" />
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
        <button class="btn btn--primary" type="button" @click="submitPlot">{{ editingId ? '保存修改' : '创建地块' }}</button>
      </template>
    </AppModal>

    <AppModal v-model="deleteOpen" title="删除地块">
      <div class="notice notice--danger" style="margin-bottom: 12px">删除后该地块将从地图与档案列表中移除，关联设备需重新指派。</div>
      <p style="font-size: 13px">确认删除地块「{{ deleteTarget?.name }}」吗？</p>
      <template #footer>
        <button class="btn" type="button" @click="deleteOpen = false">取消</button>
        <button class="btn btn--danger" type="button" @click="confirmDelete">确认删除</button>
      </template>
    </AppModal>
  </div>
</template>

<style scoped>
.plot-code {
  font-family: var(--font-num);
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
</style>
