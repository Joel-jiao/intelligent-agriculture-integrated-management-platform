<script setup lang="ts">
import { computed, ref } from 'vue'

export interface ChartSeries {
  name: string
  color: string
  data: number[]
}

const props = withDefaults(
  defineProps<{
    labels: string[]
    series: ChartSeries[]
    height?: number
    unit?: string
    fill?: boolean
  }>(),
  { height: 210, unit: '', fill: true },
)

const width = 720
const pad = { left: 40, right: 14, top: 16, bottom: 26 }
const plotW = width - pad.left - pad.right
const plotH = props.height - pad.top - pad.bottom
const hover = ref<number | null>(null)
const uid = `line-${Math.random().toString(36).slice(2, 8)}`

const values = computed(() => props.series.flatMap((item) => item.data))
const minValue = computed(() => {
  if (values.value.length === 0) return 0
  return Math.min(...values.value)
})
const maxValue = computed(() => {
  if (values.value.length === 0) return 1
  return Math.max(...values.value)
})
const range = computed(() => maxValue.value - minValue.value || 1)

function x(index: number): number {
  const count = Math.max(1, props.labels.length - 1)
  return pad.left + (index / count) * plotW
}

function y(value: number): number {
  return pad.top + (1 - (value - minValue.value) / range.value) * plotH
}

const lines = computed(() =>
  props.series.map((item) => {
    const points = item.data.map((value, index) => `${x(index)},${y(value)}`).join(' ')
    return { ...item, points }
  }),
)

const areaPath = computed(() => {
  const first = props.series[0]
  if (!first || first.data.length === 0) return ''
  const points = first.data.map((value, index) => `${x(index)},${y(value)}`).join(' L ')
  const lastX = x(first.data.length - 1)
  return `M ${pad.left},${pad.top + plotH} L ${points} L ${lastX},${pad.top + plotH} Z`
})

const yTicks = computed(() => {
  const list: { value: number; y: number }[] = []
  for (let i = 0; i <= 4; i += 1) {
    const value = maxValue.value - (range.value / 4) * i
    list.push({ value, y: pad.top + (plotH / 4) * i })
  }
  return list
})

const xTicks = computed(() => {
  const count = props.labels.length
  const step = Math.max(1, Math.ceil(count / 6))
  const list: { label: string; x: number; index: number }[] = []
  for (let i = 0; i < count; i += step) {
    const label = props.labels[i]
    if (label) list.push({ label, x: x(i), index: i })
  }
  return list
})

function onMove(event: MouseEvent) {
  const target = event.currentTarget as HTMLElement | null
  if (!target) return
  const rect = target.getBoundingClientRect()
  const ratio = (event.clientX - rect.left) / rect.width
  const raw = ((ratio * width - pad.left) / plotW) * (props.labels.length - 1)
  const index = Math.min(props.labels.length - 1, Math.max(0, Math.round(raw)))
  hover.value = index
}

function pointAt(series: ChartSeries, index: number): string {
  return `${x(index)},${y(series.data[index] ?? 0)}`
}

const hoverLabel = computed(() => {
  if (hover.value === null) return ''
  return props.labels[hover.value] ?? ''
})
</script>

<template>
  <div class="line-chart">
    <div class="legend line-chart__legend">
      <span v-for="item in series" :key="item.name"><i :style="{ background: item.color }" />{{ item.name }}</span>
    </div>
    <div class="line-chart__canvas" :style="{ height: `${height}px` }" @mousemove="onMove" @mouseleave="hover = null">
      <svg :viewBox="`0 0 ${width} ${height}`" preserveAspectRatio="none" role="img" aria-label="趋势图">
        <defs>
          <linearGradient :id="uid" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0%" :stop-color="series[0]?.color ?? '#2f8f5b'" stop-opacity="0.22" />
            <stop offset="100%" :stop-color="series[0]?.color ?? '#2f8f5b'" stop-opacity="0" />
          </linearGradient>
        </defs>
        <line
          v-for="tick in yTicks"
          :key="`y-${tick.y}`"
          :x1="pad.left"
          :x2="width - pad.right"
          :y1="tick.y"
          :y2="tick.y"
          stroke="#e7efe9"
          stroke-dasharray="3 5"
        />
        <text v-for="tick in yTicks" :key="`t-${tick.y}`" :x="pad.left - 8" :y="tick.y + 3" text-anchor="end" class="axis-text">
          {{ Math.round(tick.value) }}
        </text>
        <text v-for="tick in xTicks" :key="`x-${tick.index}`" :x="tick.x" :y="height - 6" text-anchor="middle" class="axis-text">
          {{ tick.label }}
        </text>
        <path v-if="fill && areaPath" :d="areaPath" :fill="`url(#${uid})`" />
        <polyline
          v-for="item in lines"
          :key="item.name"
          :points="item.points"
          fill="none"
          :stroke="item.color"
          stroke-width="2.2"
          stroke-linecap="round"
          stroke-linejoin="round"
          vector-effect="non-scaling-stroke"
        />
        <line
          v-if="hover !== null"
          :x1="x(hover)"
          :x2="x(hover)"
          :y1="pad.top"
          :y2="pad.top + plotH"
          stroke="#b8c9be"
          stroke-dasharray="4 4"
        />
        <circle
          v-for="item in series"
          v-show="hover !== null"
          :key="`dot-${item.name}`"
          :cx="hover === null ? 0 : x(hover)"
          :cy="hover === null ? 0 : y(item.data[hover] ?? 0)"
          r="4"
          :fill="item.color"
          stroke="#fff"
          stroke-width="2"
        />
      </svg>
      <div v-if="hover !== null" class="line-chart__tip" :style="{ left: `${(x(hover) / width) * 100}%` }">
        <b>{{ hoverLabel }}</b>
        <span v-for="item in series" :key="`tip-${item.name}`">
          <i :style="{ background: item.color }" />{{ item.name }}：{{ item.data[hover] ?? 0 }}{{ unit }}
        </span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.line-chart__legend {
  margin-bottom: 6px;
}

.line-chart__canvas {
  position: relative;
  width: 100%;
}

.line-chart__canvas svg {
  width: 100%;
  height: 100%;
  overflow: visible;
}

.axis-text {
  font-size: 9px;
  fill: #9aa9a0;
  font-family: var(--font-num);
}

.line-chart__tip {
  position: absolute;
  top: 2px;
  z-index: 2;
  min-width: 110px;
  padding: 8px 10px;
  border-radius: 8px;
  background: rgba(20, 40, 28, 0.92);
  color: #fff;
  font-size: 11px;
  transform: translateX(-50%);
  pointer-events: none;
  box-shadow: 0 8px 20px rgba(10, 30, 18, 0.2);
}

.line-chart__tip b {
  display: block;
  margin-bottom: 3px;
  font-size: 10.5px;
  color: #a7e8bf;
  font-family: var(--font-num);
}

.line-chart__tip span {
  display: flex;
  align-items: center;
  gap: 5px;
  line-height: 1.7;
  white-space: nowrap;
}

.line-chart__tip i {
  display: inline-block;
  width: 6px;
  height: 6px;
  border-radius: 50%;
}
</style>
