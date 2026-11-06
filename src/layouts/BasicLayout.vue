<script setup lang="ts">
import GlobalHeader from '@/components/GlobalHeader.vue'
import GlobalFooter from '../components/GlobalFooter.vue'
</script>

<template>
  <div class="basic-layout">
    <GlobalHeader />
    <main class="basic-layout__main">
      <RouterView />
    </main>
    <GlobalFooter />
  </div>
</template>

<style scoped>
.basic-layout {
  display: flex;
  flex-direction: column;
  min-height: 100vh;
}

.basic-layout__main {
  flex: 1;
}
</style>
