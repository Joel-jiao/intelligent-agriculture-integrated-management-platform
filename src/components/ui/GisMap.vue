<script setup lang="ts">
import { computed, ref } from 'vue'
import type { Device, MapPoint, Plot } from '@/data/types'

const props = withDefaults(
  defineProps<{
    plots: Plot[]
    devices?: Device[]
    selectedId?: string
    showDevices?: boolean
    boxSelect?: boolean
    dark?: boolean
    height?: number
  }>(),
  { devices: () => [], selectedId: '', showDevices: true, boxSelect: false, dark: false, height: 360 },
)

const emit = defineEmits<{
  'select-plot': [id: string]
  'select-device': [id: string]
  'select-area': [rect: { x: number; y: number; width: number; height: number }]
}>()

const hoverId = ref('')
const dragging = ref(false)
const startPoint = ref<MapPoint | null>(null)
const endPoint = ref<MapPoint | null>(null)

function centroid(plot: Plot): MapPoint {
  if (plot.polygon.length === 0) return { x: 0, y: 0 }
  const sum = plot.polygon.reduce(
    (acc, point) => ({ x: acc.x + point.x, y: acc.y + point.y }),
    { x: 0, y: 0 },
  )
  return { x: sum.x / plot.polygon.length, y: sum.y / plot.polygon.length }
}

const shapes = computed(() =>
  props.plots.map((plot) => ({
    plot,
    points: plot.polygon.map((point) => `${point.x},${point.y}`).join(' '),
    center: centroid(plot),
  })),
)

const deviceMarkers = computed(() => {
  const counters: Record<string, number> = {}
  return props.devices
    .filter((device) => device.type !== '传感器' && device.type !== '网关')
    .map((device) => {
      const plot = props.plots.find((item) => item.id === device.plotId)
      if (!plot) return null
      const center = centroid(plot)
      const index = counters[device.plotId] ?? 0
      counters[device.plotId] = index + 1
      return {
        device,
        x: center.x - 18 + (index % 3) * 18,
        y: center.y + 18 + Math.floor(index / 3) * 16,
      }
    })
    .filter((item) => item !== null)
})

function polygonPoints(plot: Plot): string {
  return plot.polygon.map((point) => `${point.x},${point.y}`).join(' ')
}

function pointFromEvent(event: MouseEvent): MapPoint {
  const target = event.currentTarget as HTMLElement | null
  if (!target) return { x: 0, y: 0 }
  const rect = target.getBoundingClientRect()
  return {
    x: ((event.clientX - rect.left) / rect.width) * 1000,
    y: ((event.clientY - rect.top) / rect.height) * 600,
  }
}

function onDown(event: MouseEvent) {
  if (!props.boxSelect) return
  dragging.value = true
  startPoint.value = pointFromEvent(event)
  endPoint.value = startPoint.value
}

function onMove(event: MouseEvent) {
  if (!dragging.value) return
  endPoint.value = pointFromEvent(event)
}

function onUp() {
  if (!dragging.value) return
  dragging.value = false
  if (!startPoint.value || !endPoint.value) return
  const x = Math.min(startPoint.value.x, endPoint.value.x)
  const y = Math.min(startPoint.value.y, endPoint.value.y)
  const width = Math.abs(endPoint.value.x - startPoint.value.x)
  const height = Math.abs(endPoint.value.y - startPoint.value.y)
  if (width > 12 && height > 12) emit('select-area', { x, y, width, height })
  startPoint.value = null
  endPoint.value = null
}

const selectionRect = computed(() => {
  if (!dragging.value || !startPoint.value || !endPoint.value) return null
  return {
    x: Math.min(startPoint.value.x, endPoint.value.x),
    y: Math.min(startPoint.value.y, endPoint.value.y),
    width: Math.abs(endPoint.value.x - startPoint.value.x),
    height: Math.abs(endPoint.value.y - startPoint.value.y),
  }
})
</script>

<template>
  <div class="gis-map" :class="{ 'gis-map--dark': dark }" :style="{ height: `${height}px` }">
    <svg
      viewBox="0 0 1000 600"
      preserveAspectRatio="xMidYMid meet"
      @mousedown="onDown"
      @mousemove="onMove"
      @mouseup="onUp"
      @mouseleave="onUp"
    >
      <defs>
        <pattern id="gis-grid" width="50" height="50" patternUnits="userSpaceOnUse">
          <path d="M 50 0 L 0 0 0 50" fill="none" :stroke="dark ? 'rgba(90,220,150,0.08)' : '#e5ede7'" stroke-width="1" />
        </pattern>
        <linearGradient id="gis-water" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0%" :stop-color="dark ? '#1a6b8f' : '#9cc7dd'" />
          <stop offset="100%" :stop-color="dark ? '#124e6b' : '#79abc5'" />
        </linearGradient>
      </defs>
      <rect width="1000" height="600" :fill="dark ? '#06180f' : '#f2f6f3'" />
      <rect width="1000" height="600" fill="url(#gis-grid)" />
      <path
        d="M 0 560 Q 180 520 350 548 T 700 520 T 1000 540 L 1000 600 L 0 600 Z"
        fill="url(#gis-water)"
        opacity="0.5"
      />
      <path
        d="M 0 286 Q 260 270 520 286 T 1000 268"
        :stroke="dark ? 'rgba(120,210,150,0.22)' : '#d9e3db'"
        stroke-width="10"
        fill="none"
      />
      <path
        d="M 420 0 Q 430 160 405 300 T 430 600"
        :stroke="dark ? 'rgba(120,210,150,0.18)' : '#dfe8e1'"
        stroke-width="8"
        fill="none"
      />
      <path
        v-for="item in shapes"
        :key="`glow-${item.plot.id}`"
        :points="item.points"
        fill="none"
        :stroke="item.plot.color"
        stroke-width="8"
        opacity="0.1"
      />
      <polygon
        v-for="item in shapes"
        :key="item.plot.id"
        :points="item.points"
        :fill="item.plot.color"
        :fill-opacity="selectedId === item.plot.id || hoverId === item.plot.id ? 0.32 : 0.16"
        :stroke="selectedId === item.plot.id ? '#ffffff' : item.plot.color"
        :stroke-width="selectedId === item.plot.id ? 2.5 : 1.4"
        class="gis-map__plot"
        @mouseenter="hoverId = item.plot.id"
        @mouseleave="hoverId = ''"
        @click.stop="emit('select-plot', item.plot.id)"
      />
      <g v-for="item in shapes" :key="`label-${item.plot.id}`" class="gis-map__label" pointer-events="none">
        <text
          :x="item.center.x"
          :y="item.center.y - 2"
          text-anchor="middle"
          :fill="dark ? '#d8f5e4' : '#253c2c'"
          font-size="15"
          font-weight="700"
        >
          {{ item.plot.name }}
        </text>
        <text
          :x="item.center.x"
          :y="item.center.y + 16"
          text-anchor="middle"
          :fill="dark ? 'rgba(200,247,221,0.6)' : '#73857a'"
          font-size="11"
        >
          {{ item.plot.crop }} · {{ item.plot.area }} 亩
        </text>
      </g>
      <g v-for="marker in deviceMarkers" :key="marker?.device.id" class="gis-map__device" @click.stop="marker && emit('select-device', marker.device.id)">
        <circle :cx="marker?.x" :cy="marker?.y" r="6" :fill="marker?.device.status === '在线' ? '#2f9e5a' : '#c93e3e'" />
        <circle :cx="marker?.x" :cy="marker?.y" r="10" :fill="marker?.device.status === '在线' ? '#2f9e5a' : '#c93e3e'" opacity="0.18" />
      </g>
      <rect
        v-if="selectionRect"
        :x="selectionRect.x"
        :y="selectionRect.y"
        :width="selectionRect.width"
        :height="selectionRect.height"
        fill="rgba(47,143,91,0.14)"
        stroke="#2f8f5b"
        stroke-width="1.5"
        stroke-dasharray="5 4"
        pointer-events="none"
      />
    </svg>
    <div class="gis-map__legend">
      <span><i style="background: #4fae74" />正常地块</span>
      <span><i style="background: #c9973f" />预警地块</span>
      <span><i style="background: #2f9e5a" />在线设备</span>
      <span><i style="background: #c93e3e" />离线设备</span>
    </div>
    <div v-if="boxSelect" class="gis-map__hint">按住鼠标拖拽可框选区域</div>
  </div>
</template>

<style scoped>
.gis-map {
  position: relative;
  border: 1px solid var(--line);
  border-radius: var(--radius-sm);
  background: #f2f6f3;
  overflow: hidden;
}

.gis-map--dark {
  border-color: rgba(90, 220, 150, 0.16);
  background: #06180f;
}

.gis-map svg {
  width: 100%;
  height: 100%;
  display: block;
  cursor: crosshair;
}

.gis-map__plot {
  cursor: pointer;
  transition: fill-opacity 0.18s;
}

.gis-map__legend {
  position: absolute;
  left: 12px;
  bottom: 10px;
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  padding: 5px 9px;
  border-radius: 7px;
  background: rgba(255, 255, 255, 0.86);
  font-size: 10.5px;
  color: var(--muted);
  backdrop-filter: blur(5px);
}

.gis-map--dark .gis-map__legend {
  background: rgba(6, 24, 15, 0.76);
  color: rgba(200, 247, 221, 0.66);
}

.gis-map__legend span {
  display: flex;
  align-items: center;
  gap: 5px;
}

.gis-map__legend i {
  width: 7px;
  height: 7px;
  border-radius: 50%;
}

.gis-map__hint {
  position: absolute;
  right: 12px;
  bottom: 10px;
  padding: 4px 8px;
  border-radius: 6px;
  background: rgba(255, 255, 255, 0.86);
  font-size: 10px;
  color: var(--muted);
}
</style>
