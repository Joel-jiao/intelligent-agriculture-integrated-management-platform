<script setup lang="ts">
import { useToast } from '@/composables/useToast'

const { toasts } = useToast()

const marks: Record<string, string> = {
  success: '✓',
  error: '!',
  warn: '!',
  info: 'i',
}
</script>

<template>
  <div class="toast-host">
    <div v-for="toast in toasts" :key="toast.id" class="toast" :class="`toast--${toast.type}`">
      <span class="toast__mark">{{ marks[toast.type] }}</span>
      <span>{{ toast.message }}</span>
    </div>
  </div>
</template>
