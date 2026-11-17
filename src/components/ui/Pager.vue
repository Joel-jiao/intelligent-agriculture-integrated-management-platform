<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{
    total: number
    page: number
    pageSize?: number
  }>(),
  { pageSize: 8 },
)

const emit = defineEmits<{ 'update:page': [value: number] }>()

const current = computed({
  get: () => props.page,
  set: (value: number) => emit('update:page', value),
})

function showTotal(total: number, range: [number, number]) {
  return `共 ${total} 条，当前 ${range[0]}-${range[1]} 条`
}
</script>

<template>
  <div class="pager">
    <a-pagination
      v-model:current="current"
      :total="total"
      :page-size="pageSize"
      :show-total="showTotal"
    />
  </div>
</template>
