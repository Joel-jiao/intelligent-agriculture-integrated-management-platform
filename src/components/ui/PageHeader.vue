<script setup lang="ts">
defineProps<{
  eyebrow?: string
  title: string
  description?: string
}>()
</script>

<template>
  <div class="page-head">
    <div>
      <div v-if="eyebrow" class="page-head__eyebrow">{{ eyebrow }}</div>
      <h1>{{ title }}</h1>
      <p v-if="description">{{ description }}</p>
    </div>
    <div class="page-head__actions">
      <slot name="actions" />
    </div>
  </div>
</template>
