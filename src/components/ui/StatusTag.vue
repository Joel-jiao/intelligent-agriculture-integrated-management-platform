<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{
    text: string
    tone?: 'ok' | 'warn' | 'danger' | 'info' | 'brand' | 'mute'
    dot?: boolean
  }>(),
  { tone: 'mute', dot: false },
)

/** 平台语义 tone → AntD 预置 Tag 色 */
const TONE_COLOR = {
  ok: 'success',
  warn: 'warning',
  danger: 'error',
  info: 'processing',
  brand: 'blue',
  mute: 'default',
} as const

const color = computed(() => TONE_COLOR[props.tone])
</script>

<template>
  <a-tag class="status-tag" :color="color">
    <i v-if="dot" class="dot" :class="`dot--${tone === 'mute' ? 'info' : tone}`" />
    {{ text }}
  </a-tag>
</template>

<style scoped>
.status-tag {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  margin-inline-end: 0;
  font-size: 12px;
  line-height: 20px;
  border-radius: var(--radius-pill);
}
</style>
