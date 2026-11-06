<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import GisMap from '@/components/ui/GisMap.vue'
import DonutChart from '@/components/ui/DonutChart.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import { useToast } from '@/composables/useToast'
import { devices, park, plots, weather } from '@/data/mock'
import type { Plot } from '@/data/types'
import { buildCsv, downloadText, formatNumber, today } from '@/utils/format'

const toast = useToast()

interface AreaRect {
  x: number
  y: number
  width: number
  height: number
}

interface CropGroup {
  crop: string
  area: number
  count: number
  color: string
}

const layers = reactive({
  plots: true,
  devices: true,
  weather: true,
  remote: true,
})

const dark = ref(false)
const tab = ref<'plots' | 'devices'>('plots')
const selectedPlotId = ref('')
const selectedArea = ref<AreaRect | null>(null)

const visiblePlots = computed(() => (layers.plots ? plots : []))
const visibleDevices = computed(() => (layers.devices ? devices : []))

function centroid(plot: Plot): { x: number; y: number } {
  if (plot.polygon.length === 0) return { x: 0, y: 0 }
  const sum = plot.polygon.reduce((acc, point) => ({ x: acc.x + point.x, y: acc.y + point.y }), { x: 0, y: 0 })
  return { x: sum.x / plot.polygon.length, y: sum.y / plot.polygon.length }
}

const selectedPlots = computed(() => {
  const area = selectedArea.value
  if (!area) return []
  return plots.filter((plot) => {
    const center = centroid(plot)
    return (
      center.x >= area.x &&
      center.x <= area.x + area.width &&
      center.y >= area.y &&
      center.y <= area.y + area.height
    )
  })
})

const selectionArea = computed(() =>
  selectedPlots.value.reduce((sum, plot) => sum + plot.area, 0),
)

function groupCrops(list: Plot[]): CropGroup[] {
  const groups: CropGroup[] = []
  list.forEach((plot) => {
    const group = groups.find((item) => item.crop === plot.crop)
    if (group) {
      group.area += plot.area
      group.count += 1
    } else {
      groups.push({ crop: plot.crop, area: plot.area, count: 1, color: plot.color })
    }
  })
  return groups
}

const allCropGroups = computed(() => groupCrops(plots))
const selectionCropGroups = computed(() => groupCrops(selectedPlots.value))

const donutSegments = computed(() =>
  allCropGroups.value.map((item) => ({
    label: item.crop,
    value: Math.round(item.area * 10) / 10,
    color: item.color,
  })),
)

const selectedPlot = computed(() => plots.find((item) => item.id === selectedPlotId.value))
const selectedPlotDeviceCount = computed(() =>
  selectedPlot.value ? devices.filter((item) => item.plotId === selectedPlot.value?.id).length : 0,
)
const onlineDevices = computed(() => devices.filter((item) => item.status === '在线').length)

const deviceRows = computed(() => (layers.devices ? devices : []))

function selectPlot(id: string) {
  selectedPlotId.value = id
}

function selectArea(rect: AreaRect) {
  selectedArea.value = rect
  const total = selectionArea.value
  if (selectedPlots.value.length === 0) {
    toast.warn('框选区域内没有地块，请重新选择范围')
    return
  }
  toast.success(`框选完成：${selectedPlots.value.length} 个地块，总面积 ${formatNumber(total, 1)} 亩`)
}

function selectDevice(id: string) {
  const device = devices.find((item) => item.id === id)
  if (!device) return
  toast.info(`${device.name} · ${device.status} · 最近上报 ${device.lastSeen}`)
}

function resetSelection() {
  selectedArea.value = null
  selectedPlotId.value = ''
  toast.info('已清除地图框选与地块选中状态')
}

function toggleDark() {
  dark.value = !dark.value
  toast.info(dark.value ? '已切换至深色底图' : '已切换至浅色底图')
}

function plotStatusTone(status: Plot['status']): 'ok' | 'warn' | 'mute' {
  if (status === '正常') return 'ok'
  if (status === '预警') return 'warn'
  return 'mute'
}

function exportSelection() {
  const list = selectedPlots.value.length > 0 ? selectedPlots.value : plots
  const data = list.map((plot) => [plot.code, plot.name, plot.crop, plot.variety, plot.area, plot.stage, plot.status, plot.manager])
  downloadText(
    `GIS空间统计_${today()}.csv`,
    buildCsv(['地块编号', '地块名称', '作物', '品种', '面积(亩)', '生育期', '状态', '负责人'], data),
  )
  toast.success(`已导出 ${data.length} 个地块的空间统计结果`)
}
</script>

<template>
  <div>
    <PageHeader
      eyebrow="GIS OVERVIEW"
      title="GIS 综合地图"
      description="园区地块、设备、气象与遥感图层叠加展示，支持框选空间统计与地块详情查看"
    >
      <template #actions>
        <button class="btn" type="button" @click="toggleDark">{{ dark ? '浅色底图' : '深色底图' }}</button>
        <button class="btn" type="button" @click="resetSelection">清除框选</button>
        <button class="btn btn--primary" type="button" @click="exportSelection">导出空间统计</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="园区种植总面积" :value="formatNumber(park.area)" unit="亩" icon="地" note="6 个地块 · 3 座温室" />
      <StatCard label="地块数量" :value="plots.length" unit="个" icon="块" note="含露天种植区" />
      <StatCard label="在线设备" :value="`${onlineDevices}/${devices.length}`" icon="设" note="网关与传感器在线" trend="在线率 90%" />
      <StatCard
        label="框选地块"
        :value="selectedArea ? selectedPlots.length : 0"
        unit="个"
        icon="选"
        :note="selectedArea ? `面积 ${formatNumber(selectionArea, 1)} 亩` : '在地图上拖拽进行框选'"
        accent
      />
    </div>

    <div class="grid grid--main">
      <div class="stack">
        <section class="card">
          <div class="card__head">
            <div class="card__title">园区地图 <span class="card__sub">支持框选 · 点击地块查看详情</span></div>
            <div class="legend">
              <span><i style="background: #4fae74" />正常</span>
              <span><i style="background: #c9973f" />预警</span>
              <span><i style="background: #c93e3e" />离线设备</span>
            </div>
          </div>
          <div class="card__body">
            <div class="map-stage">
              <GisMap
                :plots="visiblePlots"
                :devices="visibleDevices"
                :selected-id="selectedPlotId"
                :show-devices="layers.devices"
                :box-select="true"
                :dark="dark"
                :height="500"
                @select-plot="selectPlot"
                @select-area="selectArea"
                @select-device="selectDevice"
              />
              <div v-if="layers.weather" class="map-overlay map-overlay--weather">
                <span>气象监测点</span>
                <b>{{ weather.temperature }}℃</b>
                <small>{{ weather.condition }} · 湿度 {{ weather.humidity }}%</small>
              </div>
              <div v-if="layers.remote" class="map-overlay map-overlay--remote">
                遥感影像图层 · 2026-11-05 多光谱
              </div>
            </div>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">图层对象明细</div>
            <div class="tabs">
              <button class="tab" :class="{ 'tab--active': tab === 'plots' }" type="button" @click="tab = 'plots'">
                地块列表
              </button>
              <button class="tab" :class="{ 'tab--active': tab === 'devices' }" type="button" @click="tab = 'devices'">
                设备列表
              </button>
            </div>
          </div>
          <div class="table-wrap" style="border: 0; border-radius: 0 0 14px 14px; margin-top: 14px">
            <table v-if="tab === 'plots'" class="data-table">
              <thead>
                <tr>
                  <th>编号</th>
                  <th>地块名称</th>
                  <th>作物 / 品种</th>
                  <th>面积</th>
                  <th>生育期</th>
                  <th>负责人</th>
                  <th>状态</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="plot in plots" :key="plot.id">
                  <td class="num cell-strong">
                    <button class="link-action" type="button" style="font-weight: 600" @click="selectPlot(plot.id)">
                      {{ plot.code }}
                    </button>
                  </td>
                  <td>{{ plot.name }}</td>
                  <td>{{ plot.crop }}<span class="cell-muted"> / {{ plot.variety }}</span></td>
                  <td class="num">{{ plot.area }} 亩</td>
                  <td>{{ plot.stage }}</td>
                  <td>{{ plot.manager }}</td>
                  <td><StatusTag :text="plot.status" :tone="plotStatusTone(plot.status)" dot /></td>
                </tr>
              </tbody>
            </table>
            <table v-else class="data-table">
              <thead>
                <tr>
                  <th>设备编号</th>
                  <th>设备名称</th>
                  <th>类型</th>
                  <th>所属地块</th>
                  <th>状态</th>
                  <th>协议</th>
                  <th>最近上报</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="device in deviceRows" :key="device.id">
                  <td class="num cell-strong">{{ device.id }}</td>
                  <td>{{ device.name }}</td>
                  <td>{{ device.type }}</td>
                  <td>{{ device.plotId }}</td>
                  <td><StatusTag :text="device.status" :tone="device.status === '在线' ? 'ok' : 'danger'" dot /></td>
                  <td>{{ device.protocol }}</td>
                  <td class="num cell-muted">{{ device.lastSeen }}</td>
                </tr>
                <tr v-if="deviceRows.length === 0">
                  <td colspan="7">
                    <div class="empty">
                      <div class="empty__mark">关</div>
                      <span>设备图层已关闭，请在图层面板开启后查看</span>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>
      </div>

      <div class="stack">
        <section class="card">
          <div class="card__head">
            <div class="card__title">图层控制</div>
            <span class="tag tag--brand">{{ dark ? '深色底图' : '浅色底图' }}</span>
          </div>
          <div class="card__body layer-list">
            <label class="switch">
              <input v-model="layers.plots" type="checkbox" />
              <span class="switch__track" />
              <span>地块图层</span>
            </label>
            <label class="switch">
              <input v-model="layers.devices" type="checkbox" />
              <span class="switch__track" />
              <span>设备点位</span>
            </label>
            <label class="switch">
              <input v-model="layers.weather" type="checkbox" />
              <span class="switch__track" />
              <span>气象监测点</span>
            </label>
            <label class="switch">
              <input v-model="layers.remote" type="checkbox" />
              <span class="switch__track" />
              <span>遥感影像</span>
            </label>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">框选结果 <span class="card__sub">{{ selectedArea ? '已框选' : '待框选' }}</span></div>
            <button v-if="selectedArea" class="link-action" type="button" @click="resetSelection">清除</button>
          </div>
          <div class="card__body">
            <template v-if="selectedArea">
              <div class="kv">
                <div class="kv__item"><span>选中地块</span><b>{{ selectedPlots.length }} 个</b></div>
                <div class="kv__item"><span>选中总面积</span><b>{{ formatNumber(selectionArea, 1) }} 亩</b></div>
              </div>
              <div class="selection-crops">
                <div v-for="group in selectionCropGroups" :key="group.crop" class="selection-crop">
                  <span><i :style="{ background: group.color }" />{{ group.crop }} · {{ group.count }} 块</span>
                  <b>{{ formatNumber(group.area, 1) }} 亩</b>
                </div>
                <div v-if="selectionCropGroups.length === 0" class="cell-muted" style="font-size: 12px">
                  框选区域暂无地块，请调整选择范围
                </div>
              </div>
              <button class="btn btn--sm btn--full" type="button" style="margin-top: 12px" @click="exportSelection">
                导出框选结果
              </button>
            </template>
            <div v-else class="empty">
              <div class="empty__mark">框</div>
              <span>在左侧地图按住鼠标拖拽框选区域</span>
            </div>
          </div>
        </section>

        <section v-if="selectedPlot" class="card card--tint">
          <div class="card__head">
            <div class="card__title">地块详情</div>
            <button class="link-action" type="button" @click="selectedPlotId = ''">关闭</button>
          </div>
          <div class="card__body">
            <div class="row row--between" style="margin-bottom: 10px">
              <div>
                <div style="font-size: 15px; font-weight: 700">{{ selectedPlot.name }}</div>
                <div class="cell-muted" style="font-size: 11.5px">{{ selectedPlot.code }} · {{ selectedPlot.greenhouse }}</div>
              </div>
              <StatusTag :text="selectedPlot.status" :tone="plotStatusTone(selectedPlot.status)" dot />
            </div>
            <div class="kv">
              <div class="kv__item"><span>作物 / 品种</span><b>{{ selectedPlot.crop }} / {{ selectedPlot.variety }}</b></div>
              <div class="kv__item"><span>种植面积</span><b>{{ selectedPlot.area }} 亩</b></div>
              <div class="kv__item"><span>生育期</span><b>{{ selectedPlot.stage }}</b></div>
              <div class="kv__item"><span>土壤类型</span><b>{{ selectedPlot.soil }}</b></div>
              <div class="kv__item"><span>定植日期</span><b>{{ selectedPlot.plantedAt }}</b></div>
              <div class="kv__item"><span>预计采收</span><b>{{ selectedPlot.expectedHarvest }}</b></div>
              <div class="kv__item"><span>负责人</span><b>{{ selectedPlot.manager }}</b></div>
              <div class="kv__item"><span>设备数量</span><b>{{ selectedPlotDeviceCount }} 台</b></div>
            </div>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">空间统计 <span class="card__sub">按作物面积</span></div>
          </div>
          <div class="card__body">
            <DonutChart
              :segments="donutSegments"
              :size="148"
              :center-value="`${formatNumber(park.area)}`"
              center-label="园区总亩数"
            />
            <div class="legend" style="margin-top: 12px">
              <span>地块 {{ plots.length }} 个</span>
              <span>温室 3 座</span>
              <span>露天 2 区</span>
            </div>
          </div>
        </section>
      </div>
    </div>
  </div>
</template>

<style scoped>
.map-stage {
  position: relative;
}

.map-overlay {
  position: absolute;
  display: flex;
  flex-direction: column;
  gap: 1px;
  padding: 7px 10px;
  border-radius: 8px;
  font-size: 10.5px;
  line-height: 1.5;
  pointer-events: none;
  backdrop-filter: blur(4px);
}

.map-overlay--weather {
  top: 12px;
  left: 12px;
  background: rgba(255, 255, 255, 0.88);
  border: 1px solid var(--line);
  color: var(--muted);
}

.map-overlay--weather b {
  font-size: 16px;
  color: var(--ink);
}

.map-overlay--weather small {
  color: var(--faint);
}

.map-overlay--remote {
  top: 12px;
  right: 12px;
  border: 1px dashed rgba(47, 143, 91, 0.5);
  background: rgba(47, 143, 91, 0.1);
  color: var(--brand-dark);
  letter-spacing: 0.5px;
}

.layer-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.selection-crops {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px dashed var(--line);
}

.selection-crop {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  font-size: 12px;
  color: var(--muted);
}

.selection-crop span {
  display: flex;
  align-items: center;
  gap: 6px;
}

.selection-crop i {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

.selection-crop b {
  color: var(--ink);
  font-family: var(--font-num);
}
</style>
