<script setup lang="ts">
import { computed, useSlots } from 'vue'

const props = withDefaults(
  defineProps<{
    modelValue: boolean
    title: string
    size?: 'md' | 'lg'
  }>(),
  { size: 'md' },
)

const emit = defineEmits<{ 'update:modelValue': [value: boolean] }>()
const slots = useSlots()

/** 与原设计一致：内容超高时在弹窗内部滚动，不撑破视口 */
const bodyStyle = { maxHeight: '72vh', overflowY: 'auto' } as const

/** 与原设计一致：md 560px / lg 780px */
const width = computed(() => (props.size === 'lg' ? 780 : 560))

const open = computed({
  get: () => props.modelValue,
  set: (value: boolean) => emit('update:modelValue', value),
})
</script>

<template>
  <a-modal
    v-model:open="open"
    :title="title"
    :width="width"
    centered
    destroy-on-close
    :body-style="bodyStyle"
    :footer="slots.footer ? undefined : null"
  >
    <slot />
    <template v-if="slots.footer" #footer>
      <slot name="footer" />
    </template>
  </a-modal>
</template>
