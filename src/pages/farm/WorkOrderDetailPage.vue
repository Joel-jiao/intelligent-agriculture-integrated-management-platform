<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRoute } from 'vue-router'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import { useToast } from '@/composables/useToast'
import { findPlot, materials, plotName, workOrders as seedWorkOrders } from '@/data/mock'
import type { WorkOrder } from '@/data/types'
import { formatNumber, nowDateTime } from '@/utils/format'

const toast = useToast()
const route = useRoute()

const orderList = ref<WorkOrder[]>(seedWorkOrders.map((item) => ({ ...item })))
const routeId = computed(() => String(route.params.id ?? ''))
const order = computed<WorkOrder | undefined>(
  () => orderList.value.find((item) => item.id === routeId.value) ?? orderList.value[0],
)

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

const doneCount = computed(() => {
  const status = order.value?.status
  if (status === '待接单') return 1
  if (status === '进行中') return 3
  if (status === '待验收') return 5
  if (status === '已完成') return 6
  return 0
})

const steps = [
  { title: '工单派发', desc: '管理员创建工单并指派负责人' },
  { title: '农户接单', desc: '负责人确认任务与作业要求' },
  { title: '现场打卡', desc: '到达地块后完成 GPS 定位打卡' },
  { title: '上传照片', desc: '上传作业过程与结果现场照片' },
  { title: '提交验收', desc: '填写工时与农资用量后提交' },
  { title: '验收完成', desc: '管理员验收通过并归档' },
]

const timeline = computed(() =>
  steps.map((step, index) => ({
    ...step,
    state: index < doneCount.value ? 'done' : index === doneCount.value ? 'active' : '',
  })),
)

interface CheckinItem {
  id: number
  time: string
  lat: string
  lng: string
  distance: string
}

const checkins = ref<CheckinItem[]>([
  { id: 1, time: '2026-11-06 08:34', lat: '29.5912', lng: '106.2205', distance: '4.2 m' },
])

interface PhotoItem {
  id: number
  name: string
}

const photos = ref<PhotoItem[]>([])
let photoSeq = 0

interface UsageItem {
  id: number
  time: string
  hours: number
  material: string
  amount: string
}

const usages = ref<UsageItem[]>([])
let usageSeq = 0

const usageForm = ref({
  hours: '',
  materialId: materials[0]?.id ?? '',
  amount: '',
})

function acceptOrder() {
  if (!order.value) return
  order.value.status = '进行中'
  order.value.progress = Math.max(order.value.progress, 15)
  toast.success(`已接单，请在 ${order.value.deadline} 前完成作业`)
}

function startWork() {
  if (!order.value) return
  order.value.progress = Math.max(order.value.progress, 35)
  toast.info('已开始作业，系统记录了作业开始时间')
}

function submitAcceptance() {
  if (!order.value) return
  order.value.status = '待验收'
  order.value.progress = 100
  toast.success('已提交验收，等待管理员确认')
}

function approve() {
  if (!order.value) return
  order.value.status = '已完成'
  order.value.progress = 100
  toast.success('验收通过，工单已归档')
}

function addCheckin() {
  const lat = (29.5 + Math.random() * 0.1).toFixed(4)
  const lng = (106.2 + Math.random() * 0.1).toFixed(4)
  const distance = (1 + Math.random() * 9).toFixed(1)
  const id = (checkins.value[checkins.value.length - 1]?.id ?? 0) + 1
  checkins.value.unshift({ id, time: nowDateTime(), lat, lng, distance: `${distance} m` })
  toast.success(`现场打卡成功，距地块中心 ${distance} 米`)
}

function onPhotoChange(event: Event) {
  const input = event.target as HTMLInputElement
  const files = input.files
  if (!files || files.length === 0) return
  for (let i = 0; i < files.length; i += 1) {
    const file = files[i]
    if (!file) continue
    photoSeq += 1
    photos.value.push({ id: photoSeq, name: file.name })
  }
  toast.success(`已添加 ${files.length} 张现场照片`)
  input.value = ''
}

function removePhoto(id: number) {
  photos.value = photos.value.filter((item) => item.id !== id)
}

function addUsage() {
  const hours = Number(usageForm.value.hours)
  if (Number.isNaN(hours) || hours <= 0) {
    toast.warn('请填写有效的工时（小时）')
    return
  }
  const material = materials.find((item) => item.id === usageForm.value.materialId)
  usageSeq += 1
  usages.value.unshift({
    id: usageSeq,
    time: nowDateTime(),
    hours,
    material: material ? `${material.name}（${material.unit}）` : '未使用农资',
    amount: usageForm.value.amount.trim() || '0',
  })
  usageForm.value.hours = ''
  usageForm.value.amount = ''
  toast.success('工时与农资用量记录已添加')
}

const totalHours = computed(() => usages.value.reduce((sum, item) => sum + item.hours, 0))
</script>

<template>
  <div>
    <PageHeader
      eyebrow="WORK ORDER DETAIL"
      :title="order?.title ?? '工单详情'"
      :description="order ? `${order.id} · ${plotName(order.plot)} · 截止 ${order.deadline}` : '未找到匹配的工单记录'"
    >
      <template #actions>
        <RouterLink class="btn" to="/farm/work-orders">返回列表</RouterLink>
        <StatusTag v-if="order" :text="order.status" :tone="statusTone(order.status)" dot />
      </template>
    </PageHeader>

    <template v-if="order">
      <div class="grid grid--main">
        <div class="stack">
          <section class="card">
            <div class="card__head">
              <div class="card__title">工单基本信息</div>
              <StatusTag :text="`优先级 ${order.priority}`" :tone="priorityTone(order.priority)" />
            </div>
            <div class="card__body">
              <div class="progress-row" style="margin-bottom: 16px">
                <span style="color: var(--muted)">作业进度</span>
                <div class="progress">
                  <div class="progress__bar" :class="{ 'progress__bar--warn': order.progress < 40 }" :style="{ width: `${order.progress}%` }" />
                </div>
                <b>{{ order.progress }}%</b>
              </div>
              <div class="kv kv--3">
                <div class="kv__item"><span>工单编号</span><b>{{ order.id }}</b></div>
                <div class="kv__item"><span>作业类型</span><b>{{ order.type }}</b></div>
                <div class="kv__item"><span>工单状态</span><b>{{ order.status }}</b></div>
                <div class="kv__item"><span>作业地块</span><b>{{ plotName(order.plot) }}（{{ order.plot }}）</b></div>
                <div class="kv__item"><span>种植作物</span><b>{{ order.crop }}</b></div>
                <div class="kv__item"><span>负责人</span><b>{{ order.assignee }}</b></div>
                <div class="kv__item"><span>联系电话</span><b>{{ order.phone }}</b></div>
                <div class="kv__item"><span>创建时间</span><b>{{ order.createdAt }}</b></div>
                <div class="kv__item"><span>截止时间</span><b>{{ order.deadline }}</b></div>
              </div>
            </div>
          </section>

          <section class="card">
            <div class="card__head">
              <div class="card__title">作业要求</div>
              <StatusTag text="验收依据" tone="brand" />
            </div>
            <div class="card__body">
              <div class="notice notice--brand">{{ order.requirement }}</div>
              <div class="notice notice--warn" style="margin-top: 10px">
                作业完成后需上传现场照片，并登记本次工时与农资用量，方可在移动端提交验收。
              </div>
            </div>
          </section>

          <section class="card">
            <div class="card__head">
              <div class="card__title">执行流程 <span class="card__sub">按当前状态高亮</span></div>
              <span class="tag tag--outline">{{ doneCount }}/{{ steps.length }} 已完成</span>
            </div>
            <div class="card__body">
              <div class="timeline">
                <div
                  v-for="(step, index) in timeline"
                  :key="step.title"
                  class="timeline__item"
                  :class="{ 'timeline__item--done': step.state === 'done', 'timeline__item--active': step.state === 'active' }"
                >
                  <div class="timeline__title">
                    {{ step.title }}
                    <StatusTag v-if="step.state === 'active'" text="进行中" tone="warn" />
                    <StatusTag v-else-if="step.state === 'done'" text="完成" tone="ok" />
                    <span v-else class="tag">待执行</span>
                  </div>
                  <div class="timeline__desc">{{ index + 1 }}. {{ step.desc }}</div>
                </div>
              </div>
            </div>
          </section>

          <section class="card">
            <div class="card__head">
              <div class="card__title">工时与农资用量 <span class="card__sub">累计工时 {{ formatNumber(totalHours, 1) }} 小时</span></div>
              <span class="tag tag--outline">{{ usages.length }} 条记录</span>
            </div>
            <div class="card__body">
              <div class="usage-form">
                <label class="field">
                  <span class="field__label">工时（小时）</span>
                  <input v-model="usageForm.hours" class="input" type="number" min="0" step="0.5" placeholder="如 3.5" />
                </label>
                <label class="field">
                  <span class="field__label">农资</span>
                  <select v-model="usageForm.materialId" class="select">
                    <option v-for="item in materials" :key="item.id" :value="item.id">{{ item.name }}</option>
                  </select>
                </label>
                <label class="field">
                  <span class="field__label">用量</span>
                  <input v-model="usageForm.amount" class="input" type="text" placeholder="如 2 kg / 3 瓶" />
                </label>
                <button class="btn btn--primary" type="button" @click="addUsage">添加记录</button>
              </div>

              <div class="table-wrap" style="margin-top: 12px">
                <table class="data-table">
                  <thead>
                    <tr>
                      <th>记录时间</th>
                      <th>工时</th>
                      <th>农资</th>
                      <th>用量</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-if="usages.length === 0">
                      <td colspan="4">
                        <div class="empty" style="padding: 20px">暂无工时与农资记录，请在上方添加</div>
                      </td>
                    </tr>
                    <tr v-for="item in usages" :key="item.id">
                      <td class="num">{{ item.time }}</td>
                      <td class="num">{{ formatNumber(item.hours, 1) }} h</td>
                      <td>{{ item.material }}</td>
                      <td class="num">{{ item.amount }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </section>
        </div>

        <div class="stack">
          <section class="card card--tint">
            <div class="card__head">
              <div class="card__title">负责人信息</div>
              <span class="tag tag--brand">执行人</span>
            </div>
            <div class="card__body">
              <div class="row" style="margin-bottom: 14px">
                <span class="avatar avatar--lg">{{ order.assignee.slice(0, 1) }}</span>
                <div>
                  <div style="font-size: 16px; font-weight: 650">{{ order.assignee }}</div>
                  <div style="font-size: 11.5px; color: var(--muted)">农户 · 负责 {{ plotName(order.plot) }}</div>
                  <div style="font-size: 11.5px; color: var(--faint)">{{ order.phone }}</div>
                </div>
              </div>
              <div class="kv">
                <div class="kv__item"><span>责任地块</span><b>{{ order.plot }}</b></div>
                <div class="kv__item"><span>作物品种</span><b>{{ findPlot(order.plot)?.variety ?? '—' }}</b></div>
                <div class="kv__item"><span>累计工时</span><b>{{ formatNumber(totalHours, 1) }} 小时</b></div>
                <div class="kv__item"><span>现场打卡</span><b>{{ checkins.length }} 次</b></div>
              </div>

              <div class="order-actions">
                <button v-if="order.status === '待接单'" class="btn btn--primary btn--full" type="button" @click="acceptOrder">接单</button>
                <button v-if="order.status === '进行中'" class="btn btn--full" type="button" @click="startWork">开始作业</button>
                <button v-if="order.status === '进行中'" class="btn btn--primary btn--full" type="button" @click="submitAcceptance">提交验收</button>
                <button v-if="order.status === '待验收'" class="btn btn--primary btn--full" type="button" @click="approve">验收通过</button>
                <div v-if="order.status === '已完成'" class="notice notice--brand">该工单已验收归档，流程已全部完成。</div>
              </div>
            </div>
          </section>

          <section class="card">
            <div class="card__head">
              <div class="card__title">现场打卡记录</div>
              <button class="btn btn--sm" type="button" @click="addCheckin">现场打卡</button>
            </div>
            <div class="card__body">
              <div class="checkin-list">
                <div v-for="item in checkins" :key="item.id" class="checkin-item">
                  <span class="checkin-item__dot" />
                  <div style="flex: 1; min-width: 0">
                    <div class="checkin-item__time">{{ item.time }}</div>
                    <div class="checkin-item__gps">GPS {{ item.lat }}, {{ item.lng }} · 距地块 {{ item.distance }}</div>
                  </div>
                  <StatusTag text="有效" tone="ok" />
                </div>
              </div>
            </div>
          </section>

          <section class="card">
            <div class="card__head">
              <div class="card__title">现场照片 <span class="card__sub">{{ photos.length }} 张</span></div>
              <label class="btn btn--sm" style="position: relative; overflow: hidden">
                选择照片
                <input type="file" accept="image/*" multiple style="position: absolute; inset: 0; opacity: 0; cursor: pointer" @change="onPhotoChange" />
              </label>
            </div>
            <div class="card__body">
              <div v-if="photos.length === 0" class="empty" style="padding: 24px">
                <span class="empty__mark">图</span>
                尚未上传现场照片
              </div>
              <div v-else class="photo-grid">
                <div v-for="photo in photos" :key="photo.id" class="photo-thumb">
                  <span class="photo-thumb__mark">IMG</span>
                  <span class="photo-thumb__name" :title="photo.name">{{ photo.name }}</span>
                  <button class="photo-thumb__del" type="button" @click="removePhoto(photo.id)">×</button>
                </div>
              </div>
              <div class="notice" style="margin-top: 10px">照片仅演示文件名记录，提交验收时将与工单一并归档。</div>
            </div>
          </section>
        </div>
      </div>
    </template>

    <section v-else class="card">
      <div class="card__body">
        <div class="empty">
          <span class="empty__mark">空</span>
          未找到该工单，请返回列表重新选择
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.usage-form {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr)) auto;
  gap: 10px;
  align-items: end;
}

.order-actions {
  display: grid;
  gap: 8px;
  margin-top: 16px;
}

.checkin-list {
  display: grid;
  gap: 9px;
}

.checkin-item {
  display: flex;
  align-items: center;
  gap: 9px;
  padding: 9px 11px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: var(--surface-2);
}

.checkin-item__dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--brand);
  box-shadow: 0 0 0 3px var(--brand-soft);
}

.checkin-item__time {
  font-size: 12px;
  color: var(--ink-2);
  font-family: var(--font-num);
}

.checkin-item__gps {
  margin-top: 1px;
  font-size: 10.5px;
  color: var(--faint);
  font-family: var(--font-num);
}

.photo-grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 9px;
}

.photo-thumb {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 8px;
  border: 1px solid var(--line);
  border-radius: 8px;
  background: var(--surface-2);
}

.photo-thumb__mark {
  display: grid;
  place-items: center;
  height: 42px;
  border-radius: 6px;
  background: var(--brand-soft);
  color: var(--brand);
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 1px;
}

.photo-thumb__name {
  overflow: hidden;
  font-size: 10.5px;
  color: var(--muted);
  text-overflow: ellipsis;
  white-space: nowrap;
}

.photo-thumb__del {
  position: absolute;
  top: 3px;
  right: 3px;
  width: 18px;
  height: 18px;
  border: 0;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.9);
  color: var(--danger);
  font-size: 11px;
  line-height: 1;
}

@media (max-width: 720px) {
  .usage-form {
    grid-template-columns: 1fr;
  }
}
</style>
