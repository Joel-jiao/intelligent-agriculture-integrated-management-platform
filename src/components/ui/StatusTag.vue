<script setup lang="ts">
withDefaults(
  defineProps<{
    text: string
    tone?: 'ok' | 'warn' | 'danger' | 'info' | 'brand' | 'mute'
    dot?: boolean
  }>(),
  { tone: 'mute', dot: false },
)
</script>

<template>
  <span class="tag" :class="tone === 'mute' ? '' : `tag--${tone}`">
    <i v-if="dot" class="dot" :class="`dot--${tone === 'mute' ? 'info' : tone}`" />
    {{ text }}
  </span>
</template>
