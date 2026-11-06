<script setup lang="ts">
import { computed, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import VideoStage from '@/components/ui/VideoStage.vue'
import { useToast } from '@/composables/useToast'
import { cameras, plotName } from '@/data/mock'
import type { Camera } from '@/data/types'
import { buildCsv, downloadText } from '@/utils/format'

const toast = useToast()

const cameraList = ref<Camera[]>(cameras.map((item) => ({ ...item })))
const selectedId = ref(cameraList.value[0]?.id ?? '')
const viewMode = ref<'single' | 'grid'>('single')
const playing = ref(true)
const period = ref<'today' | '3d' | '7d'>('today')

const hues = [145, 165, 182, 120, 205, 132]

const selectedCamera = computed(() => cameraList.value.find((item) => item.id === selectedId.value) ?? cameraList.value[0])

const onlineCount = computed(() => cameraList.value.filter((item) => item.status === '在线').length)
const offlineCount = computed(() => cameraList.value.filter((item) => item.status === '离线').length)
const onlineRate = computed(() =>
  cameraList.value.length === 0 ? 0 : Math.round((onlineCount.value / cameraList.value.length) * 100),
)

function hueOf(id: string): number {
  const index = cameraList.value.findIndex((item) => item.id === id)
  return hues[index] ?? 145
}

function selectCamera(camera: Camera) {
  selectedId.value = camera.id
  if (camera.status === '离线') {
    toast.warn(`${camera.name} 当前离线，画面可能无法加载`)
  } else {
    toast.info(`已切换至 ${camera.name}`)
  }
}

function togglePlay() {
  playing.value = !playing.value
  toast.success(playing.value ? '已恢复实时画面播放' : '已暂停当前画面')
}

function snapshot() {
  toast.success(`已抓拍 ${selectedCamera.value?.name ?? '当前画面'}，图片已保存至文件库`)
}

function fullscreen() {
  toast.info('已请求全屏展示，按 Esc 可退出')
}

function refreshCameras() {
  toast.success(`摄像头状态已刷新，平台在线 ${onlineCount.value} 路 / 离线 ${offlineCount.value} 路`)
}

interface ReplayRecord {
  id: string
  cameraId: string
  cameraName: string
  start: string
  duration: string
  size: string
  daysAgo: number
}

const replayRecords: ReplayRecord[] = [
  { id: 'R-01', cameraId: 'CAM-01', cameraName: '1号大棚 · 东侧', start: '2026-11-06 09:00', duration: '32 分钟', size: '186 MB', daysAgo: 0 },
  { id: 'R-02', cameraId: 'CAM-02', cameraName: '1号大棚 · 西侧', start: '2026-11-06 08:30', duration: '28 分钟', size: '164 MB', daysAgo: 0 },
  { id: 'R-03', cameraId: 'CAM-03', cameraName: '2号草莓棚 · 入口', start: '2026-11-06 07:00', duration: '45 分钟', size: '212 MB', daysAgo: 0 },
  { id: 'R-04', cameraId: 'CAM-04', cameraName: '3号黄瓜棚 · 中部', start: '2026-11-05 16:20', duration: '36 分钟', size: '198 MB', daysAgo: 1 },
  { id: 'R-05', cameraId: 'CAM-06', cameraName: '稻田 · 灌渠', start: '2026-11-04 10:15', duration: '52 分钟', size: '264 MB', daysAgo: 2 },
  { id: 'R-06', cameraId: 'CAM-01', cameraName: '1号大棚 · 东侧', start: '2026-11-02 14:00', duration: '40 分钟', size: '208 MB', daysAgo: 4 },
  { id: 'R-07', cameraId: 'CAM-05', cameraName: '露天果园 · 全景', start: '2026-10-31 09:30', duration: '25 分钟', size: '142 MB', daysAgo: 6 },
]

const thresholdDays = computed(() => {
  if (period.value === 'today') return 0
  if (period.value === '3d') return 2
  return 7
})

const filteredRecords = computed(() => replayRecords.filter((item) => item.daysAgo <= thresholdDays.value))

function replay(record: ReplayRecord) {
  toast.info(`正在回放「${record.cameraName}」${record.start} 录像片段`)
}

function exportList() {
  const rows = cameraList.value.map((camera) => [
    camera.id,
    camera.name,
    plotName(camera.plot),
    camera.status,
    camera.resolution,
    camera.stream,
  ])
  downloadText(
    '视频监控摄像头清单_20261106.csv',
    buildCsv(['摄像头编号', '名称', '所属地块', '状态', '分辨率', '码流地址'], rows),
  )
  toast.success(`已导出 ${rows.length} 路摄像头清单`)
}
</script>

<template>
  <div>
    <PageHeader
      eyebrow="IOT · VIDEO"
      title="视频监控"
      :description="`园区 6 路摄像头实时画面与历史录像回放 · 在线率 ${onlineRate}%`"
    >
      <template #actions>
        <button class="btn" type="button" @click="refreshCameras">刷新状态</button>
        <button class="btn" type="button" @click="exportList">导出摄像头清单</button>
        <button class="btn btn--primary" type="button" @click="fullscreen">全屏展示</button>
      </template>
    </PageHeader>

    <div class="grid grid--sidebar">
      <section class="card">
        <div class="card__head">
          <div class="card__title">摄像头列表</div>
          <span class="tag tag--ok">{{ onlineCount }} / {{ cameraList.length }} 在线</span>
        </div>
        <div class="card__body camera-list">
          <button
            v-for="camera in cameraList"
            :key="camera.id"
            class="camera-item"
            :class="{ 'is-active': camera.id === selectedId }"
            type="button"
            @click="selectCamera(camera)"
          >
            <span class="camera-item__thumb" :style="{ background: `hsl(${hueOf(camera.id)}, 32%, 18%)` }">
              <i class="dot" :class="camera.status === '在线' ? 'dot--ok' : 'dot--danger'" />
            </span>
            <span class="camera-item__text">
              <b>{{ camera.name }}</b>
              <small>{{ camera.id }} · {{ plotName(camera.plot) }}</small>
            </span>
            <StatusTag :text="camera.status" :tone="camera.status === '在线' ? 'ok' : 'danger'" />
          </button>
        </div>
        <div class="card__body" style="border-top: 1px solid var(--line)">
          <div class="kv kv--3">
            <div class="kv__item"><span>在线</span><b>{{ onlineCount }} 路</b></div>
            <div class="kv__item"><span>离线</span><b>{{ offlineCount }} 路</b></div>
            <div class="kv__item"><span>在线率</span><b>{{ onlineRate }}%</b></div>
          </div>
        </div>
      </section>

      <div class="stack">
        <section class="card">
          <div class="card__head">
            <div class="card__title">
              实时画面
              <span class="card__sub">{{ selectedCamera?.id }} · {{ selectedCamera?.resolution }}</span>
            </div>
            <div class="segmented">
              <button type="button" :class="{ 'is-active': viewMode === 'single' }" @click="viewMode = 'single'">单画面</button>
              <button type="button" :class="{ 'is-active': viewMode === 'grid' }" @click="viewMode = 'grid'">网格</button>
            </div>
          </div>
          <div class="card__body">
            <template v-if="viewMode === 'single'">
              <VideoStage
                :title="selectedCamera?.name ?? '未选择摄像头'"
                :plot="selectedCamera ? plotName(selectedCamera.plot) : '—'"
                :live="selectedCamera?.status === '在线'"
                :hue="selectedCamera ? hueOf(selectedCamera.id) : 145"
              />
              <div class="row wrap" style="margin-top: 12px">
                <button class="btn btn--sm" type="button" @click="togglePlay">{{ playing ? '暂停' : '播放' }}</button>
                <button class="btn btn--sm" type="button" @click="snapshot">抓拍</button>
                <button class="btn btn--sm" type="button" @click="fullscreen">全屏</button>
                <div class="toolbar__spacer" />
                <span class="tag tag--info">码流 {{ selectedCamera?.stream ?? '—' }}</span>
                <span class="tag" :class="selectedCamera?.status === '在线' ? 'tag--ok' : 'tag--danger'">
                  {{ selectedCamera?.status === '在线' ? '实时在线' : '设备离线' }}
                </span>
              </div>
            </template>
            <div v-else class="video-grid">
              <button
                v-for="camera in cameraList"
                :key="camera.id"
                class="video-cell"
                type="button"
                @click="selectCamera(camera)"
              >
                <VideoStage
                  :title="camera.name"
                  :plot="plotName(camera.plot)"
                  :live="camera.status === '在线'"
                  :hue="hueOf(camera.id)"
                />
              </button>
            </div>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">录像回放</div>
            <div class="segmented">
              <button type="button" :class="{ 'is-active': period === 'today' }" @click="period = 'today'">今日</button>
              <button type="button" :class="{ 'is-active': period === '3d' }" @click="period = '3d'">近 3 日</button>
              <button type="button" :class="{ 'is-active': period === '7d' }" @click="period = '7d'">近 7 日</button>
            </div>
          </div>
          <div class="table-wrap" style="border: 0; border-radius: 0">
            <table class="data-table">
              <thead>
                <tr>
                  <th>录像编号</th>
                  <th>摄像头</th>
                  <th>开始时间</th>
                  <th>时长</th>
                  <th>文件大小</th>
                  <th>状态</th>
                  <th>操作</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="record in filteredRecords" :key="record.id">
                  <td class="num cell-strong">{{ record.id }}</td>
                  <td>{{ record.cameraName }}</td>
                  <td class="num">{{ record.start }}</td>
                  <td>{{ record.duration }}</td>
                  <td class="num cell-muted">{{ record.size }}</td>
                  <td><StatusTag text="已归档" tone="info" /></td>
                  <td><button class="btn btn--sm" type="button" @click="replay(record)">回放</button></td>
                </tr>
                <tr v-if="filteredRecords.length === 0">
                  <td colspan="7"><div class="empty">该时间段暂无录像文件</div></td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>
      </div>
    </div>
  </div>
</template>

<style scoped>
.camera-list {
  display: flex;
  flex-direction: column;
  gap: 6px;
  padding-top: 10px;
}

.camera-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 9px;
  border: 1px solid transparent;
  border-radius: 9px;
  background: var(--surface-2);
  text-align: left;
  transition: 0.16s;
}

.camera-item:hover {
  border-color: var(--line-strong);
  background: var(--surface);
}

.camera-item.is-active {
  border-color: var(--brand);
  background: var(--brand-softer);
  box-shadow: inset 3px 0 0 var(--brand);
}

.camera-item__thumb {
  display: grid;
  place-items: center;
  flex: 0 0 auto;
  width: 38px;
  height: 30px;
  border-radius: 6px;
}

.camera-item__text {
  display: flex;
  flex: 1;
  flex-direction: column;
  min-width: 0;
}

.camera-item__text b {
  overflow: hidden;
  font-size: 12px;
  font-weight: 600;
  color: var(--ink);
  text-overflow: ellipsis;
  white-space: nowrap;
}

.camera-item__text small {
  font-size: 10px;
  color: var(--faint);
}

.video-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 10px;
}

.video-cell {
  padding: 0;
  border: 1px solid var(--line);
  border-radius: 12px;
  background: none;
  overflow: hidden;
}

.video-cell:hover {
  border-color: var(--brand);
}

@media (max-width: 720px) {
  .video-grid {
    grid-template-columns: 1fr;
  }
}
</style>
