<script setup lang="ts">
import { computed, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import DonutChart from '@/components/ui/DonutChart.vue'
import { useToast } from '@/composables/useToast'
import { files } from '@/data/mock'
import type { FileRecord } from '@/data/types'
import { buildCsv, downloadText, formatNumber, nowDateTime } from '@/utils/format'

const toast = useToast()

const rows = ref<FileRecord[]>(files.map((item) => ({ ...item })))
const typeFilter = ref('')
const keyword = ref('')
const fileInput = ref<HTMLInputElement | null>(null)

const filtered = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  return rows.value.filter((item) => {
    if (typeFilter.value && item.type !== typeFilter.value) return false
    if (!kw) return true
    return [item.name, item.uploader].some((field) => field.toLowerCase().includes(kw))
  })
})

const typeSegments = computed(() => [
  { label: '图片', value: rows.value.filter((item) => item.type === '图片').length, color: '#157a8c' },
  { label: '文档', value: rows.value.filter((item) => item.type === '文档').length, color: '#b4692f' },
  { label: '视频', value: rows.value.filter((item) => item.type === '视频').length, color: '#2f6fae' },
])

const storage = { used: 486.2, total: 1024 }
const storagePercent = computed(() => Math.round((storage.used / storage.total) * 100))

function formatSize(bytes: number): string {
  if (bytes >= 1024 * 1024 * 1024) return `${(bytes / 1024 / 1024 / 1024).toFixed(1)} GB`
  if (bytes >= 1024 * 1024) return `${(bytes / 1024 / 1024).toFixed(1)} MB`
  if (bytes >= 1024) return `${Math.round(bytes / 1024)} KB`
  return `${bytes} B`
}

function detectType(file: File): FileRecord['type'] {
  if (file.type.startsWith('image/')) return '图片'
  if (file.type.startsWith('video/')) return '视频'
  return '文档'
}

function triggerUpload() {
  fileInput.value?.click()
}

function onFilePick(event: Event) {
  const target = event.target as HTMLInputElement
  const picked = target.files?.[0]
  if (!picked) return
  rows.value.unshift({
    id: `F-${String(rows.value.length + 1).padStart(2, '0')}`,
    name: picked.name,
    type: detectType(picked),
    size: formatSize(picked.size),
    uploader: '张运维',
    uploadedAt: nowDateTime(),
    url: `/files/upload/${picked.name}`,
  })
  target.value = ''
  toast.success(`文件「${picked.name}」已上传至对象存储`)
}

const previewTarget = ref<FileRecord | null>(null)
const previewOpen = computed({
  get: () => previewTarget.value !== null,
  set: (value: boolean) => {
    if (!value) previewTarget.value = null
  },
})

function previewHint(record: FileRecord | null): string {
  if (!record) return ''
  if (record.type === '图片') return '图片预览占位：生产环境将展示缩略图，可点击下载查看原图。'
  if (record.type === '视频') return '视频需转码为 H.264 后方可在线播放，当前请下载后使用播放器查看。'
  return '文档在线预览暂不可用，请下载后使用本地阅读器打开。'
}

function downloadFile(record: FileRecord) {
  toast.success(`文件「${record.name}」已开始下载`)
}

function downloadPreview() {
  const record = previewTarget.value
  if (record) downloadFile(record)
}

const deleteTarget = ref<FileRecord | null>(null)
const deleteOpen = computed({
  get: () => deleteTarget.value !== null,
  set: (value: boolean) => {
    if (!value) deleteTarget.value = null
  },
})

function confirmDelete() {
  const target = deleteTarget.value
  if (!target) return
  rows.value = rows.value.filter((item) => item.id !== target.id)
  deleteTarget.value = null
  toast.success(`文件「${target.name}」已删除并移入回收站`)
}

function exportFiles() {
  const list = filtered.value.map((item) => [item.name, item.type, item.size, item.uploader, item.uploadedAt])
  downloadText('文件存储清单_20261106.csv', buildCsv(['文件名', '类型', '大小', '上传人', '上传时间'], list))
  toast.success(`已导出 ${list.length} 条文件记录`)
}
</script>

<template>
  <div>
    <PageHeader eyebrow="FILE STORAGE" title="文件存储管理" description="管理检测报告、现场照片与作业视频，监控存储配额与文件生命周期">
      <template #actions>
        <button class="btn" type="button" @click="exportFiles">导出清单</button>
        <button class="btn btn--primary" type="button" @click="triggerUpload">上传文件</button>
      </template>
    </PageHeader>

    <input ref="fileInput" type="file" style="display: none" @change="onFilePick" />

    <div class="stat-grid">
      <StatCard label="已用存储" :value="storage.used" unit="GB" icon="存" note="总配额 1024 GB" trend="使用率 47%" />
      <StatCard label="文件总数" :value="rows.length" unit="个" icon="文" note="图片 3 · 文档 4 · 视频 1" trend="本月 +12" trend-up />
      <StatCard label="本月上传" :value="formatNumber(126)" unit="个" icon="传" note="检测报告占比 46%" trend="较上月 +18" trend-up />
      <StatCard label="待清理文件" :value="12" unit="个" icon="清" note="90 天未访问" trend="可释放 3.2 GB" accent />
    </div>

    <div class="grid grid--main" style="margin-bottom: 16px">
      <section class="card">
        <div class="card__head">
          <div class="card__title">存储配额 <span class="card__sub">对象存储 · 同城双活</span></div>
          <span class="tag" :class="storagePercent > 80 ? 'tag--warn' : 'tag--brand'">{{ storagePercent }}% 已用</span>
        </div>
        <div class="card__body">
          <div class="row row--between" style="margin-bottom: 8px; font-size: 12px; color: var(--muted)">
            <span>已用 {{ storage.used }} GB</span>
            <span>总配额 {{ storage.total }} GB</span>
          </div>
          <div class="progress">
            <div class="progress__bar" :style="{ width: `${storagePercent}%` }" />
          </div>
          <div class="kv kv--3" style="margin-top: 16px">
            <div class="kv__item"><span>图片占用</span><b>18.6 GB</b></div>
            <div class="kv__item"><span>文档占用</span><b>12.4 GB</b></div>
            <div class="kv__item"><span>视频占用</span><b>45.2 GB</b></div>
            <div class="kv__item"><span>备份快照</span><b>386.0 GB</b></div>
            <div class="kv__item"><span>临时文件</span><b>24.0 GB</b></div>
            <div class="kv__item"><span>本月增量</span><b>6.8 GB</b></div>
          </div>
          <div class="notice notice--warn" style="margin-top: 14px">
            <span>存储使用率超过 85% 时将暂停视频上传，请及时清理 90 天前的作业视频。</span>
          </div>
        </div>
      </section>

      <section class="card">
        <div class="card__head">
          <div class="card__title">文件类型分布 <span class="card__sub">按文件数量</span></div>
        </div>
        <div class="card__body">
          <DonutChart :segments="typeSegments" :size="150" :center-value="`${rows.length}`" center-label="文件总数" />
          <div class="kv" style="margin-top: 16px">
            <div class="kv__item"><span>平均文件大小</span><b>7.9 MB</b></div>
            <div class="kv__item"><span>本月删除</span><b>9 个</b></div>
          </div>
        </div>
      </section>
    </div>

    <section class="card">
      <div class="card__head">
        <div class="card__title">文件列表 <span class="card__sub">{{ filtered.length }} 个文件</span></div>
        <span class="tag tag--brand">保留策略 180 天</span>
      </div>
      <div class="card__body">
        <div class="toolbar">
          <div class="field">
            <span class="field__label">文件类型</span>
            <select v-model="typeFilter" class="select" style="width: 116px">
              <option value="">全部类型</option>
              <option value="图片">图片</option>
              <option value="文档">文档</option>
              <option value="视频">视频</option>
            </select>
          </div>
          <div class="field" style="flex: 1; min-width: 200px">
            <span class="field__label">关键词</span>
            <input v-model="keyword" class="input" placeholder="搜索文件名 / 上传人" />
          </div>
          <button class="btn btn--sm" type="button" style="margin-top: 18px" @click="typeFilter = ''; keyword = ''">重置</button>
          <div class="toolbar__spacer" />
          <button class="btn btn--sm" type="button" style="margin-top: 18px" @click="triggerUpload">选择文件上传</button>
        </div>

        <div class="table-wrap">
          <table class="data-table">
            <thead>
              <tr>
                <th>文件名</th>
                <th>类型</th>
                <th>大小</th>
                <th>上传人</th>
                <th>上传时间</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="record in filtered" :key="record.id">
                <td class="cell-strong">{{ record.name }}</td>
                <td>
                  <StatusTag :text="record.type" :tone="record.type === '图片' ? 'brand' : record.type === '文档' ? 'info' : 'warn'" />
                </td>
                <td class="num">{{ record.size }}</td>
                <td>{{ record.uploader }}</td>
                <td class="num">{{ record.uploadedAt }}</td>
                <td>
                  <div class="table-actions">
                    <button class="link-action" type="button" @click="previewTarget = record">预览</button>
                    <button class="link-action" type="button" @click="downloadFile(record)">下载</button>
                    <button class="link-action link-action--danger" type="button" @click="deleteTarget = record">删除</button>
                  </div>
                </td>
              </tr>
              <tr v-if="filtered.length === 0">
                <td colspan="6">
                  <div class="empty"><span class="empty__mark">空</span>没有匹配的文件，可尝试上传新文件</div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>

    <AppModal v-model="previewOpen" title="文件预览" size="lg">
      <div v-if="previewTarget" class="preview-box">
        <span class="preview-box__mark">{{ previewTarget.type === '图片' ? '图' : previewTarget.type === '视频' ? '视' : '文' }}</span>
        <b>{{ previewTarget.name }}</b>
        <small>{{ previewTarget.size }} · {{ previewTarget.type }} · {{ previewTarget.uploader }}</small>
      </div>
      <div v-if="previewTarget" class="kv" style="margin-top: 14px">
        <div class="kv__item"><span>文件编号</span><b>{{ previewTarget.id }}</b></div>
        <div class="kv__item"><span>存储路径</span><b class="num">{{ previewTarget.url }}</b></div>
        <div class="kv__item"><span>上传时间</span><b>{{ previewTarget.uploadedAt }}</b></div>
        <div class="kv__item"><span>上传人</span><b>{{ previewTarget.uploader }}</b></div>
      </div>
      <div class="notice notice--brand" style="margin-top: 14px">
        <span>{{ previewHint(previewTarget) }}</span>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="previewTarget = null">关闭</button>
        <button class="btn btn--primary" type="button" @click="downloadPreview">下载文件</button>
      </template>
    </AppModal>

    <AppModal v-model="deleteOpen" title="删除文件">
      <div class="notice notice--danger">
        <span>删除后文件移入回收站，7 天内可恢复；超过保留期将物理删除且不可找回。</span>
      </div>
      <div class="kv" style="margin-top: 14px">
        <div class="kv__item"><span>文件名</span><b>{{ deleteTarget?.name }}</b></div>
        <div class="kv__item"><span>类型</span><b>{{ deleteTarget?.type }}</b></div>
        <div class="kv__item"><span>大小</span><b>{{ deleteTarget?.size }}</b></div>
        <div class="kv__item"><span>上传人</span><b>{{ deleteTarget?.uploader }}</b></div>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="deleteTarget = null">取消</button>
        <button class="btn btn--danger" type="button" @click="confirmDelete">确认删除</button>
      </template>
    </AppModal>
  </div>
</template>

<style scoped>
.preview-box {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 5px;
  min-height: 220px;
  padding: 24px;
  border: 1px dashed var(--line-strong);
  border-radius: 12px;
  background: var(--surface-2);
  text-align: center;
}

.preview-box__mark {
  display: grid;
  place-items: center;
  width: 58px;
  height: 58px;
  margin-bottom: 6px;
  border-radius: 16px;
  background: var(--brand-soft);
  color: var(--brand);
  font-size: 22px;
  font-weight: 700;
}

.preview-box b {
  font-size: 14px;
  color: var(--ink);
  word-break: break-all;
}

.preview-box small {
  font-size: 11.5px;
  color: var(--muted);
}

.link-action--danger {
  color: var(--danger);
}
</style>
