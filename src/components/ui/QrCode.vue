<script setup lang="ts">
import { computed } from 'vue'

const props = withDefaults(
  defineProps<{
    text: string
    size?: number
    dark?: string
  }>(),
  { size: 170, dark: '#173024' },
)

const count = 25
const quiet = 2

function seedFrom(text: string): number {
  let seed = 0
  for (let i = 0; i < text.length; i += 1) {
    seed = (seed * 31 + text.charCodeAt(i)) % 2147483647
  }
  return seed || 123456789
}

function nextRandom(seed: number): number {
  return (seed * 16807) % 2147483647
}

const matrix = computed(() => {
  let seed = seedFrom(props.text)
  const cells: boolean[][] = []
  for (let y = 0; y < count; y += 1) {
    const row: boolean[] = []
    for (let x = 0; x < count; x += 1) {
      seed = nextRandom(seed)
      row.push((seed % 100) > 52)
    }
    cells.push(row)
  }
  const setFinder = (originX: number, originY: number) => {
    for (let y = 0; y < 7; y += 1) {
      for (let x = 0; x < 7; x += 1) {
        const border = x === 0 || x === 6 || y === 0 || y === 6
        const core = x >= 2 && x <= 4 && y >= 2 && y <= 4
        const row = cells[originY + y]
        if (row) row[originX + x] = border || core
      }
    }
    for (let y = -1; y <= 7; y += 1) {
      for (let x = -1; x <= 7; x += 1) {
        if (x === -1 || x === 7 || y === -1 || y === 7) {
          const px = originX + x
          const py = originY + y
          if (px >= 0 && px < count && py >= 0 && py < count) {
            const row = cells[py]
            if (row) row[px] = false
          }
        }
      }
    }
  }
  setFinder(0, 0)
  setFinder(count - 7, 0)
  setFinder(0, count - 7)
  for (let i = 8; i < count - 8; i += 1) {
    const rowTiming = cells[6]
    if (rowTiming) rowTiming[i] = i % 2 === 0
    const colTiming = cells[i]
    if (colTiming) colTiming[6] = i % 2 === 0
  }
  return cells
})

const cells = computed(() => {
  const list: { x: number; y: number }[] = []
  matrix.value.forEach((row, y) => {
    row.forEach((filled, x) => {
      if (filled) list.push({ x: x + quiet, y: y + quiet })
    })
  })
  return list
})
</script>

<template>
  <div class="qr-code" :style="{ width: `${size}px` }">
    <svg :viewBox="`0 0 ${count + quiet * 2} ${count + quiet * 2}`" role="img" aria-label="溯源二维码">
      <rect :width="count + quiet * 2" :height="count + quiet * 2" fill="#fff" />
      <rect v-for="cell in cells" :key="`${cell.x}-${cell.y}`" :x="cell.x" :y="cell.y" width="1" height="1" :fill="dark" />
    </svg>
  </div>
</template>

<style scoped>
.qr-code {
  padding: 8px;
  border-radius: 10px;
  background: #fff;
  border: 1px solid var(--line);
  aspect-ratio: 1;
}

.qr-code svg {
  display: block;
  width: 100%;
  height: 100%;
}
</style>
