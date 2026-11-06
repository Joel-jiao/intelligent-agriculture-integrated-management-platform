<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'
import StatusTag from '@/components/ui/StatusTag.vue'
import { useToast } from '@/composables/useToast'
import { materials, plotName, workOrders as seedOrders } from '@/data/mock'
import type { WorkOrder } from '@/data/types'
import { nowDateTime, today } from '@/utils/format'

const route = useRoute()
const toast = useToast()

const orders = ref<WorkOrder[]>(seedOrders.map((item) => ({ ...item })))
const routeId = computed(() => String(route.params.id ?? ''))
const order = computed(() => orders.value.find((item) => item.id === routeId.value))

function statusTone(status: WorkOrder['status']): 'ok' | 'warn' | 'brand' | 'info' {
  if (status === '待接单') return 'warn'
  if (status === '进行中') return 'brand'
  if (status === '待验收') return 'info'
  return 'ok'
}

function priorityTone(priority: WorkOrder['priority']): 'danger' | 'warn' | 'mute' {
  if (priority === '高') return 'danger'
  if (priority === '中') return 'warn'
  return 'mute'
}

interface ActionRecord {
  id: number
  time: string
  title: string
  desc: string
}

const records = ref<ActionRecord[]>([])
let recordSeq = 0

function appendRecord(title: string, desc: string) {
  recordSeq += 1
  records.value.unshift({ id: recordSeq, time: nowDateTime(), title, desc })
}

function acceptOrder() {
  const current = order.value
  if (!current) return
  current.status = '进行中'
  current.progress = Math.max(current.progress, 15)
  appendRecord('接单确认', '已领取任务，作业要求已确认')
  toast.success('接单成功，请按时完成作业')
}

interface CheckinRecord {
  time: string
  lat: string
  lng: string
  distance: string
}

const checkin = ref<CheckinRecord | null>(null)

function handleCheckin() {
  const lat = (29.5912 + (Math.random() - 0.5) * 0.002).toFixed(5)
  const lng = (106.2205 + (Math.random() - 0.5) * 0.002).toFixed(5)
  const distance = (1 + Math.random() * 8).toFixed(1)
  checkin.value = { time: nowDateTime(), lat, lng, distance: `${distance} m` }
  appendRecord('GPS 打卡', `定位 ${lat}, ${lng}，距地块中心 ${distance} 米`)
  toast.success(`打卡成功，距地块中心 ${distance} 米`)
}

interface PhotoItem {
  id: number
  name: string
}

const photos = ref<PhotoItem[]>([])
let photoSeq = 0

function onPhotoChange(event: Event) {
  const input = event.target as HTMLInputElement
  const files = input.files
  if (!files || files.length === 0) return
  let added = 0
  for (let i = 0; i < files.length; i += 1) {
    const file = files[i]
    if (!file) continue
    photoSeq += 1
    photos.value.push({ id: photoSeq, name: file.name })
    added += 1
  }
  if (added > 0) {
    appendRecord('上传现场照片', `新增 ${added} 张现场照片`)
    toast.success(`已添加 ${added} 张现场照片`)
  }
  input.value = ''
}

const usageForm = ref({
  hours: '',
  materialId: materials[0]?.id ?? '',
  amount: '',
})

interface UsageItem {
  id: number
  time: string
  hours: number
  material: string
  amount: string
}

const usages = ref<UsageItem[]>([])
let usageSeq = 0

function addUsage() {
  const raw = usageForm.value.hours.trim()
  const hours = Number(raw)
  if (raw === '' || !Number.isFinite(hours) || hours <= 0) {
    toast.warn('请填写有效的工时（小时）')
    return
  }
  const material = materials.find((item) => item.id === usageForm.value.materialId)
  usageSeq += 1
  const materialText = material ? `${material.name}（${material.unit}）` : '未使用农资'
  usages.value.unshift({
    id: usageSeq,
    time: nowDateTime(),
    hours,
    material: materialText,
    amount: usageForm.value.amount.trim() || '0',
  })
  appendRecord('填写工时/农资', `${hours} 小时 · ${materialText} ${usageForm.value.amount.trim() || '0'}`)
  usageForm.value.hours = ''
  usageForm.value.amount = ''
  toast.success('工时与农资用量已保存')
}

function submitAcceptance() {
  const current = order.value
  if (!current) return
  if (photos.value.length === 0) {
    toast.warn('请先上传现场照片')
    return
  }
  if (usages.value.length === 0) {
    toast.warn('请先填写工时与农资用量')
    return
  }
  current.status = '待验收'
  current.progress = 100
  appendRecord('提交验收', '作业结果已提交，等待管理员验收')
  toast.success('已提交验收，等待管理员确认')
}

interface StepItem {
  title: string
  desc: string
}

const steps: StepItem[] = [
  { title: '接单确认', desc: '确认作业要求并领取任务' },
  { title: 'GPS 打卡', desc: '到达地块完成定位打卡' },
  { title: '上传照片', desc: '上传现场作业过程照片' },
  { title: '提交结果', desc: '填写工时与农资用量后提交' },
  { title: '验收完成', desc: '园区管理员验收归档' },
]

const stepStates = computed(() => [
  Boolean(order.value && order.value.status !== '待接单'),
  checkin.value !== null,
  photos.value.length > 0,
  order.value?.status === '待验收' || order.value?.status === '已完成',
  order.value?.status === '已完成',
])

function stepState(index: number): 'done' | 'active' | '' {
  if (stepStates.value[index] === true) return 'done'
  const pendingIndex = stepStates.value.findIndex((item) => !item)
  return index === pendingIndex ? 'active' : ''
}
</script>

<template>
  <div class="mobile-page">
    <header class="page-head">
      <div>
        <h2>任务详情</h2>
        <p>{{ today() }} · 农事作业执行</p>
      </div>
      <RouterLink to="/app/tasks" class="mobile-btn mobile-btn--ghost back-btn">返回列表</RouterLink>
    </header>

    <template v-if="order">
      <section class="mobile-card detail-head">
        <div class="detail-badges">
          <StatusTag :text="order.status" :tone="statusTone(order.status)" dot />
          <StatusTag :text="`优先级 ${order.priority}`" :tone="priorityTone(order.priority)" />
        </div>
        <h3 class="detail-title">{{ order.title }}</h3>
        <div class="detail-meta">
          <span>{{ plotName(order.plot) }}（{{ order.plot }}）</span>
          <span>作物 {{ order.crop }}</span>
        </div>
        <div class="detail-meta">
          <span>{{ order.type }}</span>
          <span>截止 {{ order.deadline }}</span>
        </div>
        <div class="progress-row detail-progress">
          <span>作业进度</span>
          <div class="progress">
            <div class="progress__bar" :style="{ width: `${order.progress}%` }" />
          </div>
          <b class="font-num">{{ order.progress }}%</b>
        </div>
      </section>

      <section class="mobile-section">
        <div class="mobile-section__head">
          <h3>作业要求</h3>
          <span class="tag tag--brand">验收依据</span>
        </div>
        <div class="mobile-card">
          <p class="requirement">{{ order.requirement }}</p>
          <p class="requirement-note">完成后需上传现场照片并登记工时与农资用量，方可提交验收。</p>
        </div>
      </section>

      <section class="mobile-section">
        <div class="mobile-section__head">
          <h3>执行进度</h3>
          <span class="step-time font-num">{{ checkin?.time ?? '待打卡' }}</span>
        </div>
        <div class="mobile-card">
          <div class="timeline">
            <div
              v-for="(step, index) in steps"
              :key="step.title"
              class="timeline__item"
              :class="{
                'timeline__item--done': stepState(index) === 'done',
                'timeline__item--active': stepState(index) === 'active',
              }"
            >
              <div class="timeline__title">
                {{ step.title }}
                <StatusTag v-if="stepState(index) === 'done'" text="已完成" tone="ok" />
                <StatusTag v-else-if="stepState(index) === 'active'" text="待执行" tone="warn" />
              </div>
              <div class="timeline__desc">{{ index + 1 }}. {{ step.desc }}</div>
            </div>
          </div>
        </div>
      </section>

      <section v-if="checkin" class="mobile-section">
        <div class="mobile-section__head">
          <h3>打卡定位</h3>
          <StatusTag text="定位有效" tone="ok" dot />
        </div>
        <div class="mobile-card checkin-card">
          <div class="checkin-row"><span>打卡时间</span><b class="font-num">{{ checkin.time }}</b></div>
          <div class="checkin-row"><span>GPS 坐标</span><b class="font-num">{{ checkin.lat }}, {{ checkin.lng }}</b></div>
          <div class="checkin-row"><span>距地块中心</span><b class="font-num">{{ checkin.distance }}</b></div>
        </div>
      </section>

      <section class="mobile-section">
        <div class="mobile-section__head">
          <h3>现场照片</h3>
          <span class="tag tag--outline">{{ photos.length }} 张</span>
        </div>
        <div class="mobile-card">
          <label class="mobile-upload upload-box">
            <input class="upload-input" type="file" accept="image/*" multiple @change="onPhotoChange" />
            <span>{{ photos.length > 0 ? '点击继续添加现场照片' : '点击选择现场照片，支持多选' }}</span>
          </label>
          <div v-if="photos.length > 0" class="photo-list">
            <div v-for="photo in photos" :key="photo.id" class="mobile-list-item photo-row">
              <span class="mobile-icon">图</span>
              <span class="photo-name">{{ photo.name }}</span>
              <StatusTag text="已上传" tone="ok" />
            </div>
          </div>
          <p v-else class="upload-hint">照片用于作业过程留档，提交验收时一并归档。</p>
        </div>
      </section>

      <section class="mobile-section">
        <div class="mobile-section__head">
          <h3>工时与农资用量</h3>
          <span class="tag tag--outline">已记录 {{ usages.length }} 条</span>
        </div>
        <div class="mobile-card">
          <label class="mobile-field">
            <span>工时（小时）</span>
            <input v-model="usageForm.hours" type="number" min="0" step="0.5" placeholder="如 3.5" />
          </label>
          <label class="mobile-field">
            <span>农资</span>
            <select v-model="usageForm.materialId">
              <option v-for="item in materials" :key="item.id" :value="item.id">{{ item.name }}</option>
            </select>
          </label>
          <label class="mobile-field">
            <span>用量</span>
            <input v-model="usageForm.amount" type="text" placeholder="如 2 kg / 3 瓶" />
          </label>
          <button class="mobile-btn mobile-btn--ghost mobile-btn--full" type="button" @click="addUsage">
            保存工时与农资用量
          </button>
          <div v-if="usages.length > 0" class="usage-list">
            <div v-for="item in usages" :key="item.id" class="usage-row">
              <div>
                <div class="usage-material">{{ item.material }}</div>
                <div class="usage-time font-num">{{ item.time }}</div>
              </div>
              <div class="usage-value font-num">{{ item.hours }} h · {{ item.amount }}</div>
            </div>
          </div>
        </div>
      </section>

      <section class="mobile-section">
        <div class="mobile-section__head">
          <h3>任务操作</h3>
          <span>{{ order.status }}</span>
        </div>
        <div class="mobile-card action-card">
          <button
            v-if="order.status === '待接单'"
            class="mobile-btn mobile-btn--full"
            type="button"
            @click="acceptOrder"
          >
            接单
          </button>

          <template v-if="order.status === '进行中'">
            <button class="mobile-btn mobile-btn--ghost mobile-btn--full" type="button" @click="handleCheckin">
              GPS 打卡
            </button>
            <p class="action-hint">
              {{ checkin ? `最近打卡：${checkin.time} · ${checkin.distance}` : '到达地块后点击打卡，系统将记录定位与时间' }}
            </p>
            <button class="mobile-btn mobile-btn--full" type="button" @click="submitAcceptance">
              提交验收
            </button>
            <p class="action-hint">提交前需至少上传 1 张现场照片并登记 1 条工时/农资用量</p>
          </template>

          <div v-if="order.status === '待验收'" class="status-note">
            作业结果已提交，等待园区管理员验收确认。
          </div>

          <template v-if="order.status === '已完成'">
            <div class="result-card">
              <div class="result-top">
                <span>验收结果</span>
                <StatusTag text="验收通过" tone="ok" dot />
              </div>
              <div class="result-row"><span>验收结论</span><b class="result-ok">合格</b></div>
              <div class="result-row"><span>验收人</span><b>李明 · 园区管理员</b></div>
              <div class="result-row"><span>验收时间</span><b class="font-num">{{ order.deadline }}</b></div>
              <div class="result-row"><span>验收意见</span><b>作业质量符合要求，准予归档</b></div>
            </div>
          </template>
        </div>
      </section>

      <section v-if="records.length > 0" class="mobile-section">
        <div class="mobile-section__head">
          <h3>作业记录</h3>
          <span>{{ records.length }} 条</span>
        </div>
        <div class="mobile-card">
          <div v-for="record in records" :key="record.id" class="mobile-list-item record-row">
            <span class="mobile-icon">记</span>
            <div class="record-main">
              <div class="record-title">{{ record.title }}</div>
              <div class="record-desc">{{ record.desc }}</div>
            </div>
            <span class="record-time font-num">{{ record.time.slice(11) }}</span>
          </div>
        </div>
      </section>
    </template>

    <div v-else class="mobile-card empty-card">
      <span class="empty-mark">空</span>
      <p>未找到该任务，可能已被撤回或编号有误</p>
      <RouterLink to="/app/tasks" class="mobile-btn mobile-btn--ghost">返回任务列表</RouterLink>
    </div>
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
  margin: 6px 0 14px;
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

.back-btn {
  height: 44px;
  padding: 0 13px;
  font-size: 12px;
}

.detail-badges {
  display: flex;
  align-items: center;
  gap: 7px;
}

.detail-title {
  margin-top: 9px;
  font-size: 16px;
  font-weight: 700;
  line-height: 1.45;
  color: var(--ink);
}

.detail-meta {
  display: flex;
  flex-wrap: wrap;
  gap: 12px;
  margin-top: 5px;
  font-size: 11.5px;
  color: var(--muted);
}

.detail-progress {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-top: 12px;
  font-size: 11px;
  color: var(--muted);
}

.detail-progress .progress {
  flex: 1;
}

.detail-progress b {
  width: 36px;
  text-align: right;
  color: var(--ink-2);
}

.requirement {
  font-size: 12.5px;
  line-height: 1.75;
  color: var(--ink-2);
}

.requirement-note {
  margin-top: 9px;
  padding-top: 9px;
  border-top: 1px dashed var(--line);
  font-size: 11px;
  line-height: 1.6;
  color: var(--warn);
}

.step-time {
  font-size: 10.5px;
  color: var(--muted);
}

.checkin-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 7px 0;
  font-size: 11.5px;
  color: var(--muted);
}

.checkin-row + .checkin-row {
  border-top: 1px dashed var(--line);
}

.checkin-row b {
  font-weight: 600;
  color: var(--ink-2);
}

.upload-box {
  position: relative;
}

.upload-input {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  opacity: 0;
  cursor: pointer;
}

.photo-list {
  margin-top: 5px;
}

.photo-row .photo-name {
  flex: 1;
  overflow: hidden;
  font-size: 12px;
  color: var(--ink-2);
  text-overflow: ellipsis;
  white-space: nowrap;
}

.upload-hint {
  margin-top: 8px;
  font-size: 10.5px;
  color: var(--faint);
}

.usage-list {
  margin-top: 10px;
  border-top: 1px dashed var(--line);
}

.usage-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  padding: 9px 0;
  border-bottom: 1px dashed var(--line);
}

.usage-row:last-child {
  border-bottom: 0;
}

.usage-material {
  font-size: 12px;
  color: var(--ink-2);
}

.usage-time {
  margin-top: 1px;
  font-size: 10px;
  color: var(--faint);
}

.usage-value {
  font-size: 12px;
  color: var(--brand-dark);
}

.action-card {
  display: flex;
  flex-direction: column;
  gap: 9px;
}

.action-hint {
  font-size: 10.5px;
  line-height: 1.6;
  color: var(--muted);
}

.status-note {
  padding: 12px;
  border-radius: 10px;
  background: var(--info-soft);
  color: var(--info);
  font-size: 12px;
  line-height: 1.6;
}

.result-card {
  padding: 12px;
  border: 1px solid var(--line);
  border-radius: 11px;
  background: var(--brand-softer);
}

.result-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  font-size: 12px;
  color: var(--muted);
}

.result-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding-top: 8px;
  font-size: 11.5px;
  color: var(--muted);
}

.result-row b {
  font-weight: 600;
  color: var(--ink-2);
}

.result-ok {
  color: var(--ok) !important;
}

.record-row {
  align-items: flex-start;
}

.record-main {
  flex: 1;
  min-width: 0;
}

.record-title {
  font-size: 12px;
  font-weight: 600;
  color: var(--ink);
}

.record-desc {
  margin-top: 1px;
  font-size: 10.5px;
  line-height: 1.5;
  color: var(--muted);
}

.record-time {
  flex: 0 0 auto;
  font-size: 10px;
  color: var(--faint);
}

.empty-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 10px;
  padding: 34px 16px;
}

.empty-card p {
  font-size: 12px;
  color: var(--muted);
}

.empty-mark {
  display: grid;
  place-items: center;
  width: 46px;
  height: 46px;
  border-radius: 50%;
  background: var(--surface-2);
  color: var(--faint);
  font-size: 14px;
}
</style>
