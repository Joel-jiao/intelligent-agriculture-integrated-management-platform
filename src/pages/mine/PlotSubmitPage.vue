<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { farmerPlots } from '@/api/store'
import type { MapPoint } from '@/data/types'

const route = useRoute()
const router = useRouter()
const toast = useToast()

const editId = computed(() => {
  const raw = route.params.id
  const value = Array.isArray(raw) ? raw[0] : raw
  return value ?? ''
})

const isResubmit = computed(() => Boolean(editId.value))
const sourcePlot = computed(() => farmerPlots.find((item) => item.id === editId.value))

const form = reactive({
  name: sourcePlot.value?.name ?? '',
  crop: sourcePlot.value?.crop ?? '',
  variety: sourcePlot.value?.variety ?? '',
  area: sourcePlot.value ? String(sourcePlot.value.area) : '',
  greenhouse: sourcePlot.value?.greenhouse ?? '连栋薄膜温室',
  plantedAt: sourcePlot.value?.plantedAt ?? '2026-11-06',
  expectedHarvest: sourcePlot.value?.expectedHarvest ?? '',
})

const points = ref<MapPoint[]>(sourcePlot.value?.polygon.map((p) => ({ ...p })) ?? [])
const photos = ref<string[]>(['现场照片-1', '现场照片-2'])
const submitOpen = ref(false)

const boundaryClosed = computed(() => points.value.length >= 3)

const polygonString = computed(() => points.value.map((p) => `${p.x},${p.y}`).join(' '))

function onMapClick(event: MouseEvent) {
  const target = event.currentTarget as SVGSVGElement | null
  if (!target) return
  const rect = target.getBoundingClientRect()
  const x = ((event.clientX - rect.left) / rect.width) * 1000
  const y = ((event.clientY - rect.top) / rect.height) * 600
  points.value.push({ x: Math.round(x), y: Math.round(y) })
}

function clearBoundary() {
  points.value = []
}

function addPhoto() {
  photos.value.push(`现场照片-${photos.value.length + 1}`)
  toast.success('照片已添加')
}

function removePhoto(index: number) {
  photos.value.splice(index, 1)
}

function validate(): boolean {
  if (!form.name.trim() || !form.crop.trim()) {
    toast.warn('请填写地块名称与种植作物')
    return false
  }
  const area = Number(form.area)
  if (!form.area || Number.isNaN(area) || area <= 0) {
    toast.warn('地块面积需为大于 0 的数字')
    return false
  }
  if (!boundaryClosed.value) {
    toast.warn('请在地图上点击绘制并闭合地块边界')
    return false
  }
  return true
}

function submit() {
  if (!validate()) return
  submitOpen.value = true
}

function confirmSubmit() {
  submitOpen.value = false
  toast.success(isResubmit.value ? '地块档案已重新提交审核' : '地块档案已提交，等待管理员审核')
  router.push('/app/plots')
}
</script>

<template>
  <div class="mobile-page">
    <header class="page-head">
      <div>
        <h2>{{ isResubmit ? '重新提交地块' : '地块录入' }}</h2>
        <p>{{ isResubmit ? '按驳回意见修改后重新提交' : '自助录入地块档案并提交审核' }}</p>
      </div>
      <button class="mobile-btn mobile-btn--ghost" type="button" @click="router.back()">返回</button>
    </header>

    <div v-if="sourcePlot?.rejectReason" class="notice notice--danger" style="margin-bottom: 10px">
      <span>驳回意见：{{ sourcePlot.rejectReason }}</span>
    </div>

    <div class="notice notice--brand" style="margin-bottom: 12px">
      <span>请依次填写地块基本信息，绘制 GIS 边界并上传现场照片，提交后由管理员审核，通过后正式生效。</span>
    </div>

    <section class="mobile-section">
      <div class="mobile-section__head"><h3>基本信息</h3></div>
      <div class="mobile-card">
        <label class="mobile-field">
          <span>地块名称</span>
          <input v-model="form.name" type="text" placeholder="如：7号番茄新棚" />
        </label>
        <label class="mobile-field">
          <span>种植作物</span>
          <input v-model="form.crop" type="text" placeholder="如：番茄" />
        </label>
        <label class="mobile-field">
          <span>品种</span>
          <input v-model="form.variety" type="text" placeholder="如：云粉 10 号" />
        </label>
        <label class="mobile-field">
          <span>面积（亩）</span>
          <input v-model="form.area" type="number" min="0" step="0.1" placeholder="0.0" />
        </label>
        <label class="mobile-field">
          <span>温室类型</span>
          <select v-model="form.greenhouse">
            <option>连栋薄膜温室</option>
            <option>日光温室</option>
            <option>育苗温室</option>
            <option>露天种植</option>
          </select>
        </label>
        <label class="mobile-field">
          <span>种植日期</span>
          <input v-model="form.plantedAt" type="date" />
        </label>
        <label class="mobile-field">
          <span>预计采收</span>
          <input v-model="form.expectedHarvest" type="date" />
        </label>
      </div>
    </section>

    <section class="mobile-section">
      <div class="mobile-section__head">
        <h3>GIS 边界绘制</h3>
        <button type="button" @click="clearBoundary">重新绘制</button>
      </div>
      <div class="mobile-card">
        <div class="boundary-map" :class="{ 'is-incomplete': !boundaryClosed }">
          <svg viewBox="0 0 1000 600" preserveAspectRatio="xMidYMid meet" @click="onMapClick">
            <rect width="1000" height="600" fill="#f2f6f3" />
            <polygon v-if="points.length >= 3" :points="polygonString" fill="rgba(47,143,91,0.22)" stroke="#2f8f5b" stroke-width="2.5" />
            <polyline v-else-if="points.length >= 2" :points="polygonString" fill="none" stroke="#2f8f5b" stroke-width="2" stroke-dasharray="6 5" />
            <circle v-for="(point, index) in points" :key="index" :cx="point.x" :cy="point.y" r="6" fill="#2f8f5b" stroke="#fff" stroke-width="2" />
            <text v-if="points.length < 3" x="500" y="300" text-anchor="middle" fill="#94a69b" font-size="15">
              点击地图依次添加边界顶点
            </text>
          </svg>
        </div>
        <div class="boundary-meta">
          <span :class="boundaryClosed ? 'tag--ok' : 'tag--warn'" class="tag">{{ boundaryClosed ? `已闭合 · ${points.length} 个顶点` : `未闭合 · ${points.length} 个顶点` }}</span>
          <span class="cell-muted">至少 3 个顶点才能闭合边界</span>
        </div>
      </div>
    </section>

    <section class="mobile-section">
      <div class="mobile-section__head">
        <h3>现场照片</h3>
        <button type="button" @click="addPhoto">+ 添加</button>
      </div>
      <div class="mobile-card">
        <div class="mobile-upload">
          <div v-for="(photo, index) in photos" :key="photo" class="upload-thumb">
            <span>照</span>
            <em>{{ photo }}</em>
            <button type="button" @click="removePhoto(index)">×</button>
          </div>
          <button class="upload-add" type="button" @click="addPhoto">+</button>
        </div>
      </div>
    </section>

    <section class="mobile-section">
      <button class="mobile-btn mobile-btn--primary mobile-btn--full" type="button" @click="submit">
        {{ isResubmit ? '重新提交审核' : '提交审核' }}
      </button>
      <div class="submit-note">提交后地块将进入待审核状态，管理员审核通过后正式生效。</div>
    </section>

    <AppModal v-model="submitOpen" title="确认提交">
      <p class="confirm-text">确认提交地块「{{ form.name }}」档案吗？提交后将进入待审核状态。</p>
      <div class="detail-row"><span>面积</span><b class="font-num">{{ form.area }} 亩</b></div>
      <div class="detail-row"><span>作物</span><b>{{ form.crop }} · {{ form.variety }}</b></div>
      <div class="detail-row"><span>边界</span><b>{{ points.length }} 个顶点</b></div>
      <template #footer>
        <button class="mobile-btn mobile-btn--ghost" type="button" @click="submitOpen = false">取消</button>
        <button class="mobile-btn mobile-btn--primary" type="button" @click="confirmSubmit">确认提交</button>
      </template>
    </AppModal>

    <div class="page-spacer" />
  </div>
</template>

<style scoped>
.font-num {
  font-family: var(--font-num);
}

.page-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  margin: 6px 0 12px;
  padding: 0 2px;
}

.page-head h2 {
  font-size: 20px;
  font-weight: 700;
  color: var(--ink);
}

.page-head p {
  margin-top: 3px;
  font-size: 11.5px;
  color: var(--muted);
}

.boundary-map {
  border: 1px solid var(--line);
  border-radius: 10px;
  overflow: hidden;
}

.boundary-map.is-incomplete {
  border-color: var(--warn);
}

.boundary-map svg {
  display: block;
  width: 100%;
  height: 200px;
  cursor: crosshair;
}

.boundary-meta {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  margin-top: 10px;
  font-size: 10.5px;
}

.mobile-upload {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.upload-thumb {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 3px;
  width: 72px;
  height: 72px;
  border: 1px solid var(--line);
  border-radius: 9px;
  background: var(--brand-soft);
}

.upload-thumb span {
  font-size: 16px;
  color: var(--brand);
}

.upload-thumb em {
  font-style: normal;
  font-size: 9px;
  color: var(--muted);
}

.upload-thumb button {
  position: absolute;
  top: 2px;
  right: 4px;
  border: 0;
  background: none;
  color: var(--faint);
  cursor: pointer;
}

.upload-add {
  width: 72px;
  height: 72px;
  border: 1px dashed var(--line-strong);
  border-radius: 9px;
  background: var(--bg-card-solid);
  color: var(--faint);
  font-size: 20px;
  cursor: pointer;
}

.submit-note {
  margin-top: 8px;
  text-align: center;
  font-size: 10px;
  color: var(--faint);
}

.confirm-text {
  font-size: 12.5px;
  line-height: 1.7;
  color: var(--ink-2);
}

.detail-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 8px 0;
  border-bottom: 1px dashed var(--line);
  font-size: 12px;
  color: var(--muted);
}

.detail-row b {
  font-weight: 600;
  color: var(--ink-2);
}
</style>
