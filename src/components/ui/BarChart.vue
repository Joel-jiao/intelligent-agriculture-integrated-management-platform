<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{
    labels: string[]
    values: number[]
    color?: string
    unit?: string
    height?: number
    showValue?: boolean
  }>(),
  { color: '#2f8f5b', unit: '', height: 190, showValue: true },
)

const max = computed(() => {
  if (props.values.length === 0) return 1
  return Math.max(...props.values) || 1
})

function barHeight(value: number): string {
  return `${Math.max(4, (value / max.value) * 100)}%`
}
</script>

<template>
  <div class="bar-chart" :style="{ height: `${height}px` }">
    <div v-for="(label, index) in labels" :key="label" class="bar-chart__col">
      <div class="bar-chart__value" v-if="showValue">{{ values[index] ?? 0 }}{{ unit }}</div>
      <div class="bar-chart__track">
        <div class="bar-chart__bar" :style="{ height: barHeight(values[index] ?? 0), background: color }" />
      </div>
      <div class="bar-chart__label">{{ label }}</div>
    </div>
  </div>
</template>

<style scoped>
.bar-chart {
  display: flex;
  align-items: flex-end;
  gap: 12px;
  padding-top: 6px;
}

.bar-chart__col {
  display: flex;
  flex: 1;
  flex-direction: column;
  align-items: center;
  height: 100%;
  min-width: 0;
}

.bar-chart__value {
  margin-bottom: 4px;
  font-size: 10.5px;
  color: var(--muted);
  font-family: var(--font-num);
  white-space: nowrap;
}

.bar-chart__track {
  display: flex;
  flex: 1;
  align-items: flex-end;
  width: 100%;
  max-width: 46px;
  border-radius: 5px 5px 2px 2px;
  background: linear-gradient(180deg, var(--surface-2), transparent);
}

.bar-chart__bar {
  width: 100%;
  border-radius: 5px 5px 2px 2px;
  opacity: 0.92;
  transition: height 0.4s ease, opacity 0.2s;
}

.bar-chart__col:hover .bar-chart__bar {
  opacity: 1;
}

.bar-chart__label {
  margin-top: 7px;
  font-size: 10.5px;
  color: var(--muted);
  white-space: nowrap;
}
</style>
