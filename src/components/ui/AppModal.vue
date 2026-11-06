<script setup lang="ts">
import { useSlots } from 'vue'

withDefaults(
  defineProps<{
    modelValue: boolean
    title: string
    size?: 'md' | 'lg'
  }>(),
  { size: 'md' },
)

const emit = defineEmits<{ 'update:modelValue': [value: boolean] }>()
const slots = useSlots()

function close() {
  emit('update:modelValue', false)
}
</script>

<template>
  <Teleport to="body">
    <Transition name="fade">
      <div v-if="modelValue" class="modal-mask" @click.self="close">
        <div class="modal" :class="{ 'modal--lg': size === 'lg' }">
          <div class="modal__head">
            <h3>{{ title }}</h3>
            <button class="modal__close" type="button" @click="close">×</button>
          </div>
          <div class="modal__body">
            <slot />
          </div>
          <div v-if="slots.footer" class="modal__foot">
            <slot name="footer" />
          </div>
        </div>
      </div>
    </Transition>
  </Teleport>
</template>

<style scoped>
.fade-enter-active,
.fade-leave-active {
  transition: opacity 0.18s;
}

.fade-enter-from,
.fade-leave-to {
  opacity: 0;
}
</style>
