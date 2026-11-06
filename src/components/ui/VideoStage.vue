<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { pad } from '@/utils/format'

const props = withDefaults(
  defineProps<{
    title: string
    plot: string
    live?: boolean
    hue?: number
  }>(),
  { live: true, hue: 145 },
)

const clock = ref('09:42:18')
let timer = 0

function tick() {
  const date = new Date()
  clock.value = `${pad(date.getHours())}:${pad(date.getMinutes())}:${pad(date.getSeconds())}`
}

onMounted(() => {
  tick()
  timer = window.setInterval(tick, 1000)
})

onBeforeUnmount(() => {
  window.clearInterval(timer)
})

const sceneStyle = computed(() => ({
  background: `radial-gradient(420px 240px at 50% 12%, hsla(${props.hue}, 55%, 42%, 0.35), transparent 70%), linear-gradient(170deg, hsl(${props.hue}, 30%, 16%), hsl(${props.hue}, 35%, 9%))`,
}))
</script>

<template>
  <div class="video-stage" :style="sceneStyle">
    <svg class="video-stage__scene" viewBox="0 0 800 450" preserveAspectRatio="xMidYMid slice" aria-hidden="true">
      <path d="M 0 300 Q 180 250 360 290 T 800 270 L 800 450 L 0 450 Z" fill="rgba(120,200,150,0.12)" />
      <path d="M 0 350 Q 220 300 430 340 T 800 330 L 800 450 L 0 450 Z" fill="rgba(120,200,150,0.1)" />
      <g stroke="rgba(180,240,200,0.18)" stroke-width="2" fill="none">
        <path d="M 40 430 L 360 300" />
        <path d="M 110 440 L 390 320" />
        <path d="M 190 448 L 425 338" />
        <path d="M 620 440 L 500 318" />
        <path d="M 700 436 L 550 330" />
      </g>
      <g fill="rgba(140,230,170,0.22)">
        <circle cx="220" cy="345" r="17" />
        <circle cx="260" cy="330" r="22" />
        <circle cx="305" cy="350" r="15" />
        <circle cx="530" cy="340" r="20" />
        <circle cx="575" cy="352" r="16" />
        <circle cx="640" cy="338" r="24" />
      </g>
      <g stroke="rgba(180,240,200,0.3)" stroke-width="3" fill="none">
        <path d="M 300 180 L 300 300" />
        <path d="M 300 200 Q 360 210 390 250" />
        <path d="M 300 230 Q 250 240 220 280" />
        <path d="M 520 170 L 520 300" />
        <path d="M 520 195 Q 570 205 600 250" />
      </g>
      <g fill="rgba(160,235,185,0.35)">
        <ellipse cx="390" cy="250" rx="26" ry="13" />
        <ellipse cx="220" cy="280" rx="24" ry="12" />
        <ellipse cx="600" cy="250" rx="25" ry="12" />
      </g>
    </svg>
    <div class="video-stage__grid" />
    <div class="video-stage__scan" />
    <div class="video-stage__top">
      <span class="video-stage__live" :class="{ 'is-off': !live }">
        <i />{{ live ? 'LIVE' : 'OFFLINE' }}
      </span>
      <span class="video-stage__title">{{ title }}</span>
    </div>
    <div class="video-stage__bottom">
      <span>{{ plot }}</span>
      <span>{{ clock }}</span>
      <span>1080P · 25fps</span>
    </div>
  </div>
</template>

<style scoped>
.video-stage {
  position: relative;
  aspect-ratio: 16 / 9;
  border-radius: 12px;
  overflow: hidden;
  background: #08150e;
}

.video-stage__scene {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
}

.video-stage__grid {
  position: absolute;
  inset: 0;
  background-image:
    linear-gradient(rgba(180, 240, 200, 0.05) 1px, transparent 1px),
    linear-gradient(90deg, rgba(180, 240, 200, 0.05) 1px, transparent 1px);
  background-size: 44px 44px;
}

.video-stage__scan {
  position: absolute;
  left: 0;
  right: 0;
  height: 1px;
  background: rgba(140, 240, 175, 0.5);
  box-shadow: 0 0 12px rgba(140, 240, 175, 0.7);
  animation: scan 4.2s linear infinite;
}

@keyframes scan {
  0% {
    top: 0;
    opacity: 0;
  }
  12% {
    opacity: 1;
  }
  88% {
    opacity: 1;
  }
  100% {
    top: 100%;
    opacity: 0;
  }
}

.video-stage__top,
.video-stage__bottom {
  position: absolute;
  left: 12px;
  right: 12px;
  display: flex;
  align-items: center;
  gap: 10px;
  font-size: 10px;
  color: rgba(220, 245, 230, 0.72);
  font-family: var(--font-num);
}

.video-stage__top {
  top: 10px;
  justify-content: space-between;
}

.video-stage__bottom {
  bottom: 10px;
  justify-content: space-between;
}

.video-stage__live {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 3px 8px;
  border-radius: 4px;
  background: rgba(201, 62, 62, 0.8);
  color: #fff;
  font-size: 9.5px;
  letter-spacing: 1px;
}

.video-stage__live i {
  width: 5px;
  height: 5px;
  border-radius: 50%;
  background: #fff;
  animation: blink 1.2s infinite;
}

.video-stage__live.is-off {
  background: rgba(90, 110, 100, 0.8);
}

@keyframes blink {
  50% {
    opacity: 0.2;
  }
}

.video-stage__title {
  padding: 3px 8px;
  border-radius: 4px;
  background: rgba(10, 30, 18, 0.45);
  color: #d8f5e4;
  font-family: var(--font);
  font-size: 10.5px;
}
</style>
