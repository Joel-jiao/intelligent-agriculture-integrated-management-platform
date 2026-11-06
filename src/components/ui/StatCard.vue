<script setup lang="ts">
withDefaults(
  defineProps<{
    label: string
    value: string | number
    unit?: string
    icon?: string
    trend?: string
    trendUp?: boolean
    note?: string
    accent?: boolean
  }>(),
  {
    unit: '',
    icon: '数',
    trend: '',
    trendUp: true,
    note: '',
    accent: false,
  },
)
</script>

<template>
  <div class="stat" :class="{ 'stat--accent': accent }">
    <div class="stat__top">
      <span class="stat__label">{{ label }}</span>
      <span class="stat__icon">{{ icon }}</span>
    </div>
    <div class="stat__value">{{ value }}<small v-if="unit">{{ unit }}</small></div>
    <div class="stat__foot">
      <span v-if="trend" class="stat__trend" :class="trendUp ? 'stat__trend--up' : 'stat__trend--down'">{{ trend }}</span>
      <span v-if="note">{{ note }}</span>
    </div>
  </div>
</template>
