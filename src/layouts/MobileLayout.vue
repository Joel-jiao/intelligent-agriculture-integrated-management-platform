<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { RouterLink } from 'vue-router'
import { mobileTabs } from '@/config/menus'
import { pad } from '@/utils/format'

const clock = ref('09:41')
let timer = 0

function tick() {
  const date = new Date()
  clock.value = `${pad(date.getHours())}:${pad(date.getMinutes())}`
}

onMounted(() => {
  tick()
  timer = window.setInterval(tick, 30000)
})

onBeforeUnmount(() => window.clearInterval(timer))
</script>

<template>
  <div class="mobile-stage">
    <div class="phone">
      <div class="phone__notch" />
      <div class="phone__statusbar">
        <span>{{ clock }}</span>
        <span style="font-size: 10px; letter-spacing: 1px">5G ▮▮▮</span>
      </div>
      <div class="phone__view">
        <RouterView />
      </div>
      <nav class="phone__tabbar">
        <RouterLink v-for="tab in mobileTabs" :key="tab.to" :to="tab.to" class="phone__tab">
          <span class="phone__tab-icon">{{ tab.icon }}</span>
          <span>{{ tab.label }}</span>
        </RouterLink>
      </nav>
    </div>
    <RouterLink to="/portals" class="mobile-stage__exit">退出演示 · 业务端总览</RouterLink>
    <div class="mobile-stage__hint">农户移动端 · 390 × 844 演示视口</div>
  </div>
</template>

<style scoped>
.mobile-stage {
  position: relative;
}

.mobile-stage__exit {
  position: fixed;
  top: 22px;
  right: 28px;
  padding: 7px 13px;
  border: 1px solid var(--line-strong);
  border-radius: 9px;
  background: #fff;
  font-size: 11.5px;
  color: var(--muted);
  box-shadow: 0 4px 12px rgba(24, 68, 44, 0.08);
}

.mobile-stage__exit:hover {
  color: var(--brand);
  border-color: var(--brand);
}

.mobile-stage__hint {
  position: fixed;
  bottom: 18px;
  left: 50%;
  transform: translateX(-50%);
  font-size: 10.5px;
  color: #94a69b;
  letter-spacing: 1px;
}

@media (max-width: 600px) {
  .mobile-stage__exit,
  .mobile-stage__hint {
    display: none;
  }

  .mobile-stage {
    padding: 0;
  }

  .phone {
    width: 100%;
    height: 100vh;
    border: 0;
    border-radius: 0;
  }

  .phone__notch {
    display: none;
  }
}
</style>
