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

const totalPages = computed(() => Math.max(1, Math.ceil(props.total / props.pageSize)))
const pages = computed(() => {
  const list: number[] = []
  const start = Math.max(1, props.page - 2)
  const end = Math.min(totalPages.value, start + 4)
  for (let i = start; i <= end; i += 1) list.push(i)
  return list
})
const from = computed(() => (props.total === 0 ? 0 : (props.page - 1) * props.pageSize + 1))
const to = computed(() => Math.min(props.total, props.page * props.pageSize))

function go(page: number) {
  if (page < 1 || page > totalPages.value) return
  emit('update:page', page)
}
</script>

<template>
  <div class="pager">
    <span>共 {{ total }} 条，当前 {{ from }}-{{ to }} 条</span>
    <div class="pager__buttons">
      <button class="pager__btn" type="button" :disabled="page <= 1" @click="go(page - 1)">上一页</button>
      <button
        v-for="item in pages"
        :key="item"
        class="pager__btn"
        :class="{ 'is-active': item === page }"
        type="button"
        @click="go(item)"
      >
        {{ item }}
      </button>
      <button class="pager__btn" type="button" :disabled="page >= totalPages" @click="go(page + 1)">下一页</button>
    </div>
  </div>
</template>
