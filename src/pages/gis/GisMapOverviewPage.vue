<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import GisMap from '@/components/ui/GisMap.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import { useToast } from '@/composables/useToast'
import { useTheme } from '@/composables/useTheme'
import { devices, envSeries, park, plots } from '@/api/store'
import type { Plot } from '@/data/types'
import { buildCsv, downloadText, formatNumber, today } from '@/utils/format'

const toast = useToast()
const { theme } = useTheme()

interface AreaRect {
  x: number
  y: number
  width: number
  height: number
}

const layers = reactive({ plots: true, devices: true, weather: true, remote: true })

const localDark = ref(false)
const isDark = computed(() => localDark.value || theme.value === 'dark')
const keyword = ref('')
const statusFilter = ref<'全部' | '正常' | '预警' | '休耕'>('全部')
const selectedPlotId = ref('')
const selectedArea = ref<AreaRect | null>(null)
const drawerOpen = ref(false)

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

const selectionArea = computed(() => selectedPlots.value.reduce((sum, plot) => sum + plot.area, 0))

const filteredPlots = computed(() =>
  plots.filter((plot) => {
    if (statusFilter.value !== '全部' && plot.status !== statusFilter.value) return false
    if (keyword.value.trim() === '') return true
    const text = keyword.value.trim().toLowerCase()
    return plot.name.toLowerCase().includes(text) || plot.crop.toLowerCase().includes(text) || plot.code.toLowerCase().includes(text)
  }),
)

const selectedPlot = computed(() => plots.find((item) => item.id === selectedPlotId.value))
const selectedPlotDeviceCount = computed(() =>
  selectedPlot.value ? devices.filter((item) => item.plotId === selectedPlot.value?.id).length : 0,
)
const selectedPlotIrrigation = computed(() => {
  const plot = selectedPlot.value
  if (!plot) return '—'
  if (plot.status === '预警') return '待灌溉'
  if (plot.status === '休耕') return '已停灌'
  return '灌溉正常'
})

const onlineCount = (list: typeof devices) => list.filter((item) => item.status === '在线').length
const irrigationDevices = computed(() => devices.filter((item) => item.type === '水泵' || item.type === '电磁阀'))
const sensorDevices = computed(() => devices.filter((item) => item.type === '传感器'))
const droneTotal = 2
const droneOnline = 2

const envNow = computed(() => ({
  temperature: envSeries.temperature[envSeries.temperature.length - 1] ?? 0,
  humidity: envSeries.humidity[envSeries.humidity.length - 1] ?? 0,
  light: envSeries.light[13] ?? 0,
  soil: envSeries.soilMoisture[envSeries.soilMoisture.length - 1] ?? 0,
}))

function selectPlot(id: string) {
  selectedPlotId.value = id
  drawerOpen.value = true
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
  drawerOpen.value = false
  toast.info('已清除地图框选与地块选中状态')
}

function toggleDark() {
  localDark.value = !localDark.value
  toast.info(localDark.value ? '已切换至深色底图' : '已切换至浅色底图')
}

function plotStatusTone(status: Plot['status']): 'ok' | 'warn' | 'mute' {
  if (status === '正常') return 'ok'
  if (status === '预警') return 'warn'
  return 'mute'
}

function exportSelection() {
  const list = selectedPlots.value.length > 0 ? selectedPlots.value : plots
  const data = list.map((plot) => [
    plot.code,
    plot.name,
    plot.crop,
    plot.variety,
    plot.area,
    plot.stage,
    plot.status,
    plot.manager,
  ])
  downloadText(
    `GIS空间统计_${today()}.csv`,
    buildCsv(['地块编号', '地块名称', '作物', '品种', '面积(亩)', '生育期', '状态', '负责人'], data),
  )
  toast.success(`已导出 ${data.length} 个地块的空间统计结果`)
}
</script>

<template>
  <div class="cockpit">
    <div class="cockpit__map">
      <GisMap
        :plots="visiblePlots"
        :devices="visibleDevices"
        :selected-id="selectedPlotId"
        :show-devices="layers.devices"
        :box-select="true"
        :dark="isDark"
        :hide-legend="true"
        :height="600"
        @select-plot="selectPlot"
        @select-area="selectArea"
        @select-device="selectDevice"
      />
    </div>

    <!-- 左上：地块筛选 -->
    <div class="cockpit__left">
      <section class="panel">
        <div class="panel__head">
          <div class="panel__title">地块筛选</div>
          <span class="tag">{{ filteredPlots.length }} / {{ plots.length }}</span>
        </div>
        <div class="panel__body">
          <input v-model="keyword" class="input input--sm" placeholder="搜索地块 / 作物" />
          <div class="segmented" style="margin-top: 10px; width: 100%">
            <button
              v-for="item in ['全部', '正常', '预警'] as const"
              :key="item"
              type="button"
              :class="{ 'is-active': statusFilter === item }"
              style="flex: 1"
              @click="statusFilter = item"
            >
              {{ item }}
            </button>
          </div>

          <div class="plot-list">
            <button
              v-for="plot in filteredPlots"
              :key="plot.id"
              class="plot-item"
              :class="{ 'is-active': plot.id === selectedPlotId }"
              type="button"
              @click="selectPlot(plot.id)"
            >
              <i
                class="dot"
                :class="plot.status === '正常' ? 'dot--ok' : plot.status === '预警' ? 'dot--warn' : 'dot--mute'"
              />
              <span class="plot-item__name">{{ plot.name }}</span>
              <span class="plot-item__meta">{{ plot.area }} 亩</span>
            </button>
            <div v-if="filteredPlots.length === 0" class="empty" style="padding: 24px 8px">没有匹配的地块</div>
          </div>

          <div class="layer-row">
            <span>图层</span>
            <label class="switch switch--sm">
              <input v-model="layers.plots" type="checkbox" />
              <span class="switch__track" />
              <span>地块</span>
            </label>
            <label class="switch switch--sm">
              <input v-model="layers.devices" type="checkbox" />
              <span class="switch__track" />
              <span>设备</span>
            </label>
            <label class="switch switch--sm">
              <input v-model="layers.weather" type="checkbox" />
              <span class="switch__track" />
              <span>气象</span>
            </label>
          </div>

          <div v-if="selectedArea" class="selection-summary">
            <span>已框选 <b>{{ selectedPlots.length }}</b> 个地块 · {{ formatNumber(selectionArea, 1) }} 亩</span>
            <button class="link-action" type="button" @click="resetSelection">清除</button>
          </div>

          <div class="panel__actions">
            <button class="btn btn--sm" type="button" @click="toggleDark">
              {{ localDark ? '浅色底图' : '深色底图' }}
            </button>
            <button class="btn btn--sm btn--primary" type="button" @click="exportSelection">导出</button>
          </div>
        </div>
      </section>
    </div>

    <!-- 右上：环境监测 -->
    <section v-if="layers.weather" class="panel cockpit__weather">
      <div class="panel__head">
        <div class="panel__title">环境监测</div>
        <span class="tag tag--ok">实时</span>
      </div>
      <div class="panel__body">
        <div class="cockpit__metrics">
          <div class="cockpit-metric">
            <span>温度</span>
            <b>{{ envNow.temperature }}<small>℃</small></b>
          </div>
          <div class="cockpit-metric">
            <span>湿度</span>
            <b>{{ envNow.humidity }}<small>%</small></b>
          </div>
          <div class="cockpit-metric">
            <span>光照</span>
            <b>{{ formatNumber(envNow.light) }}<small>lux</small></b>
          </div>
          <div class="cockpit-metric">
            <span>土壤水分</span>
            <b>{{ envNow.soil }}<small>%</small></b>
          </div>
        </div>
        <div class="weather-foot">
          <span>气象站 {{ park.plots }} 号点位</span>
          <span>09:42 更新</span>
        </div>
      </div>
    </section>

    <!-- 底部：设备状态 -->
    <section class="panel cockpit__device">
      <div class="device-strip">
        <div class="device-strip__item">
          <i class="dot dot--ok" />
          无人机在线
          <b>{{ droneOnline }}<small> / {{ droneTotal }}</small></b>
        </div>
        <span class="device-strip__divider" />
        <div class="device-strip__item">
          <i class="dot dot--ok" />
          灌溉设备
          <b>{{ onlineCount(irrigationDevices) }}<small> / {{ irrigationDevices.length }}</small></b>
        </div>
        <span class="device-strip__divider" />
        <div class="device-strip__item">
          <i class="dot dot--ok" />
          传感器
          <b>{{ onlineCount(sensorDevices) }}<small> / {{ sensorDevices.length }}</small></b>
        </div>
      </div>
    </section>

    <div class="cockpit__hint">
      <i class="dot dot--info" />
      按住在图上拖拽可框选区域 · 点击地块查看详情
    </div>

    <!-- 右侧详情抽屉 -->
    <template v-if="selectedPlot">
      <div v-if="drawerOpen" class="drawer-mask" @click="drawerOpen = false" />
      <aside v-if="drawerOpen" class="drawer">
        <div class="drawer__head">
          <div>
            <h3>{{ selectedPlot.name }}</h3>
            <div class="drawer__sub">{{ selectedPlot.code }} · {{ selectedPlot.greenhouse }}</div>
          </div>
          <button class="icon-btn" type="button" aria-label="关闭" @click="drawerOpen = false">
            <svg viewBox="0 0 24 24">
              <path d="M6 6l12 12M18 6L6 18" />
            </svg>
          </button>
        </div>
        <div class="drawer__body">
          <div class="drawer__status">
            <StatusTag :text="selectedPlot.status" :tone="plotStatusTone(selectedPlot.status)" dot />
            <span class="drawer__irrigation">灌溉状态 · {{ selectedPlotIrrigation }}</span>
          </div>

          <div class="drawer__section">
            <div class="side-panel__section-title">地块信息</div>
            <div class="kv">
              <div class="kv__item"><span>作物 / 品种</span><b>{{ selectedPlot.crop }} / {{ selectedPlot.variety }}</b></div>
              <div class="kv__item"><span>种植面积</span><b>{{ selectedPlot.area }} 亩</b></div>
              <div class="kv__item"><span>土壤类型</span><b>{{ selectedPlot.soil }}</b></div>
              <div class="kv__item"><span>生育期</span><b>{{ selectedPlot.stage }}</b></div>
              <div class="kv__item"><span>定植日期</span><b>{{ selectedPlot.plantedAt }}</b></div>
              <div class="kv__item"><span>预计采收</span><b>{{ selectedPlot.expectedHarvest }}</b></div>
              <div class="kv__item"><span>负责人</span><b>{{ selectedPlot.manager }}</b></div>
              <div class="kv__item"><span>接入设备</span><b>{{ selectedPlotDeviceCount }} 台</b></div>
            </div>
          </div>

          <div class="drawer__section">
            <div class="side-panel__section-title">土壤水分</div>
            <div class="moisture">
              <div class="moisture__head">
                <span>当前含水量</span>
                <span class="moisture__value">{{ envNow.soil }}%</span>
              </div>
              <div class="progress">
                <div
                  class="progress__bar"
                  :class="envNow.soil < 45 ? 'progress__bar--warn' : 'progress__bar--ok'"
                  :style="{ width: `${envNow.soil}%` }"
                />
              </div>
              <div class="moisture__note">适宜区间 45% – 70%，低于 45% 建议灌溉</div>
            </div>
          </div>

          <div v-if="selectedPlotDeviceCount > 0" class="drawer__section">
            <div class="side-panel__section-title">地块设备</div>
            <div class="drawer__device" v-for="device in devices.filter((item) => item.plotId === selectedPlot?.id)" :key="device.id">
              <span>{{ device.name }}</span>
              <StatusTag
                :text="device.status"
                :tone="device.status === '在线' ? 'ok' : device.status === '故障' ? 'danger' : 'warn'"
                dot
              />
            </div>
          </div>
        </div>
        <div class="drawer__foot">
          <button class="btn btn--full" type="button" @click="drawerOpen = false">关闭</button>
          <button class="btn btn--primary btn--full" type="button" @click="exportSelection">导出地块数据</button>
        </div>
      </aside>
    </template>
  </div>
</template>

<style scoped>
.input--sm {
  height: 32px;
  font-size: 12.5px;
}

.plot-list {
  margin-top: 12px;
}

.layer-row {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
  margin-top: 12px;
  padding-top: 12px;
  border-top: 1px solid var(--border-card);
  font-size: 11.5px;
  color: var(--text-secondary);
}

.switch--sm {
  gap: 5px;
  font-size: 11.5px;
}

.switch--sm .switch__track {
  width: 28px;
  height: 16px;
}

.switch--sm .switch__track::after {
  width: 12px;
  height: 12px;
}

.switch--sm input:checked + .switch__track::after {
  transform: translateX(12px);
}

.selection-summary {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  margin-top: 12px;
  padding: 8px 10px;
  border-radius: var(--radius-sm);
  background: var(--primary-soft);
  font-size: 11.5px;
  color: var(--primary);
}

.selection-summary b {
  font-family: var(--font-num), monospace;
}

.panel__actions {
  display: flex;
  gap: 8px;
  margin-top: 12px;
}

.panel__actions .btn {
  flex: 1;
}

.weather-foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  margin-top: 12px;
  font-size: 10.5px;
  color: var(--text-tertiary);
}

.drawer__sub {
  margin-top: 4px;
  font-size: 12px;
  color: var(--text-secondary);
}

.drawer__status {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 12px 0 2px;
}

.drawer__irrigation {
  font-size: 12px;
  color: var(--text-secondary);
}

.drawer__section {
  padding-top: 14px;
  margin-top: 14px;
  border-top: 1px solid var(--border-card);
}

.drawer__device {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 7px 0;
  font-size: 12.5px;
  color: var(--text-primary);
}

.moisture__note {
  margin-top: 6px;
  font-size: 11px;
  color: var(--text-tertiary);
}
</style>
