<script setup lang="ts">
withDefaults(
  defineProps<{
    label: string
    value: string | number
    unit?: string
    trend?: string
    trendUp?: boolean
    note?: string
    accent?: boolean
  }>(),
  {
    unit: '',
    trend: '',
    trendUp: true,
    note: '',
    accent: false,
  },
)
</script>

<template>
  <div class="stat" :class="{ 'stat--accent': accent }">
    <a-statistic class="stat__figure" :title="label" :value="value">
      <template v-if="unit" #suffix>
        <small class="stat__unit">{{ unit }}</small>
      </template>
    </a-statistic>
    <div v-if="trend || note" class="stat__foot">
      <span v-if="trend" class="stat__trend" :class="trendUp ? 'stat__trend--up' : 'stat__trend--down'">
        {{ trend }}
      </span>
      <span v-if="note">{{ note }}</span>
    </div>
  </div>
</template>

<style scoped>
.stat__unit {
  margin-left: 3px;
  font-size: 13px;
  font-weight: 400;
  letter-spacing: 0;
  color: var(--text-secondary);
}
</style>
