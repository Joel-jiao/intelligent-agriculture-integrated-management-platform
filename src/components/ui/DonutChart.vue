<script setup lang="ts">
import { computed } from 'vue'

export interface DonutSegment {
  label: string
  value: number
  color: string
}

const props = withDefaults(
  defineProps<{
    segments: DonutSegment[]
    size?: number
    centerValue?: string
    centerLabel?: string
    thickness?: number
  }>(),
  { size: 150, centerValue: '', centerLabel: '', thickness: 16 },
)

const radius = computed(() => props.size / 2)
const circumference = computed(() => 2 * Math.PI * (radius.value - props.thickness / 2))
const total = computed(() => props.segments.reduce((sum, item) => sum + item.value, 0) || 1)

const rings = computed(() => {
  let offset = 0
  return props.segments.map((item) => {
    const length = (item.value / total.value) * circumference.value
    const ring = {
      color: item.color,
      dash: `${length} ${circumference.value - length}`,
      offset: -offset,
    }
    offset += length
    return ring
  })
})
</script>

<template>
  <div class="donut">
    <div class="donut__ring" :style="{ width: `${size}px`, height: `${size}px` }">
      <svg :viewBox="`0 0 ${size} ${size}`">
        <circle
          :cx="radius"
          :cy="radius"
          :r="radius - thickness / 2"
          fill="none"
          stroke="var(--surface-2)"
          :stroke-width="thickness"
        />
        <circle
          v-for="(ring, index) in rings"
          :key="index"
          :cx="radius"
          :cy="radius"
          :r="radius - thickness / 2"
          fill="none"
          :stroke="ring.color"
          :stroke-width="thickness"
          :stroke-dasharray="ring.dash"
          :stroke-dashoffset="ring.offset"
          stroke-linecap="butt"
          :transform="`rotate(-90 ${radius} ${radius})`"
        />
      </svg>
      <div class="donut__center">
        <b>{{ centerValue }}</b>
        <span>{{ centerLabel }}</span>
      </div>
    </div>
    <div class="donut__legend">
      <div v-for="item in segments" :key="item.label" class="donut__item">
        <span><i :style="{ background: item.color }" />{{ item.label }}</span>
        <b>{{ item.value }}</b>
      </div>
    </div>
  </div>
</template>

<style scoped>
.donut {
  display: flex;
  align-items: center;
  gap: 18px;
  flex-wrap: wrap;
}

.donut__ring {
  position: relative;
  flex: 0 0 auto;
}

.donut__ring svg {
  width: 100%;
  height: 100%;
}

.donut__center {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0;
}

.donut__center b {
  font-size: 22px;
  font-weight: 700;
  color: var(--ink);
  font-variant-numeric: tabular-nums;
}

.donut__center span {
  font-size: 10.5px;
  color: var(--muted);
}

.donut__legend {
  flex: 1;
  min-width: 120px;
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.donut__item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  font-size: 12px;
  color: var(--muted);
}

.donut__item span {
  display: flex;
  align-items: center;
  gap: 6px;
}

.donut__item i {
  display: inline-block;
  width: 8px;
  height: 8px;
  border-radius: 50%;
}

.donut__item b {
  color: var(--ink);
  font-family: var(--font-num);
  font-weight: 600;
}
</style>
