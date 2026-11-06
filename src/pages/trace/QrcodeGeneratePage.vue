<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import PageHeader from '@/components/ui/PageHeader.vue'
import QrCode from '@/components/ui/QrCode.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import { useToast } from '@/composables/useToast'
import { batches } from '@/data/mock'
import { buildCsv, downloadText, formatNumber, today } from '@/utils/format'

const toast = useToast()
const route = useRoute()

interface GeneratedCode {
  seq: number
  code: string
  batchNo: string
  status: '待打印'
}

const pendingBatches = computed(() => batches.filter((item) => item.status === '待赋码'))
const codedBatches = computed(() => batches.filter((item) => item.status === '已赋码'))

const initialBatchNo = typeof route.query.batch === 'string' ? route.query.batch : ''
const requestedBatch = pendingBatches.value.find((item) => item.batchNo === initialBatchNo)
const selectedNo = ref(requestedBatch?.batchNo ?? (pendingBatches.value[0]?.batchNo ?? ''))
const selectedBatch = computed(() => pendingBatches.value.find((item) => item.batchNo === selectedNo.value))

const quantity = ref(12)
const remark = ref('')
const generating = ref(false)
const progress = ref(0)
const results = ref<GeneratedCode[]>([])

const maxQuantity = computed(() => {
  const batch = selectedBatch.value
  if (!batch) return 0
  return Math.max(0, Math.min(50, batch.weight - batch.qrCount))
})

const previewCode = computed(() => {
  const first = results.value[0]
  if (first) return first.code
  const batch = selectedBatch.value
  if (!batch) return ''
  return `${batch.batchNo}-${String(batch.qrCount + 1).padStart(4, '0')}`
})

let timer: ReturnType<typeof window.setInterval> | null = null

function stopTimer() {
  if (timer !== null) {
    window.clearInterval(timer)
    timer = null
  }
}

onBeforeUnmount(stopTimer)

watch(selectedNo, () => {
  stopTimer()
  generating.value = false
  progress.value = 0
  results.value = []
  if (quantity.value > maxQuantity.value) quantity.value = Math.max(1, maxQuantity.value)
})

watch(maxQuantity, (value) => {
  if (quantity.value > value) quantity.value = Math.max(1, value)
})

function generate() {
  const batch = selectedBatch.value
  if (!batch) {
    toast.error('请选择可赋码批次')
    return
  }
  const total = Number(quantity.value)
  if (!Number.isFinite(total) || total <= 0) {
    toast.error('生成数量需大于 0')
    return
  }
  if (total > maxQuantity.value) {
    toast.error(`单次最多生成 ${maxQuantity.value} 枚溯源码`)
    return
  }
  stopTimer()
  generating.value = true
  progress.value = 0
  results.value = []
  timer = window.setInterval(() => {
    progress.value = Math.min(100, progress.value + 10)
    if (progress.value >= 100) {
      stopTimer()
      generating.value = false
      results.value = Array.from({ length: total }, (_, index) => ({
        seq: index + 1,
        code: `${batch.batchNo}-${String(batch.qrCount + index + 1).padStart(4, '0')}`,
        batchNo: batch.batchNo,
        status: '待打印',
      }))
      toast.success(`批次 ${batch.batchNo} 已生成 ${total} 枚溯源码`)
    }
  }, 110)
}

function downloadAll() {
  if (results.value.length === 0) {
    toast.warn('请先生成溯源码后再下载')
    return
  }
  const batchNo = selectedBatch.value?.batchNo ?? 'unknown'
  const data = results.value.map((item) => [item.seq, item.code, item.batchNo, item.status])
  downloadText(
    `溯源码_${batchNo}_${today()}.csv`,
    buildCsv(['序号', '溯源码', '批次号', '状态'], data),
  )
  toast.success(`已导出 ${data.length} 枚溯源码清单`)
}

function downloadQr() {
  if (!previewCode.value) {
    toast.warn('请先选择批次')
    return
  }
  toast.success(`二维码 ${previewCode.value}.png 已加入下载队列`)
}

function exportCodes() {
  downloadAll()
}
</script>

<template>
  <div>
    <PageHeader
      eyebrow="QR GENERATION"
      title="溯源码生成"
      description="为待赋码批次批量生成一物一码，支持二维码预览与清单导出"
    >
      <template #actions>
        <button class="btn" type="button" @click="downloadQr">下载二维码</button>
        <button class="btn btn--primary" type="button" @click="exportCodes">下载全部</button>
      </template>
    </PageHeader>

    <div class="notice" style="margin-bottom: 16px">
      当前有 {{ pendingBatches.length }} 个待赋码批次，已完成赋码的 {{ codedBatches.length }} 个批次不可重复生成新码。
    </div>

    <div class="grid grid--main">
      <section class="card">
        <div class="card__head">
          <div class="card__title">赋码参数 <span class="card__sub">单次最多 50 枚，用于现场打印</span></div>
        </div>
        <div class="card__body">
          <div class="form-grid">
            <label class="field span-2">
              <span class="field__label">选择批次（仅显示待赋码批次）</span>
              <select v-model="selectedNo" class="select" :disabled="pendingBatches.length === 0 || generating">
                <option v-if="pendingBatches.length === 0" value="">暂无待赋码批次</option>
                <option v-for="batch in pendingBatches" :key="batch.id" :value="batch.batchNo">
                  {{ batch.batchNo }} · {{ batch.crop }} {{ batch.variety }} · {{ formatNumber(batch.weight) }} kg
                </option>
              </select>
            </label>

            <div v-if="selectedBatch" class="span-2">
              <div class="kv kv--3">
                <div class="kv__item"><span>批次号</span><b>{{ selectedBatch.batchNo }}</b></div>
                <div class="kv__item"><span>作物 / 品种</span><b>{{ selectedBatch.crop }} / {{ selectedBatch.variety }}</b></div>
                <div class="kv__item"><span>采收重量</span><b>{{ formatNumber(selectedBatch.weight) }} kg</b></div>
                <div class="kv__item"><span>已赋码</span><b>{{ formatNumber(selectedBatch.qrCount) }} 枚</b></div>
                <div class="kv__item"><span>剩余可赋码</span><b>{{ formatNumber(maxQuantity) }} 枚</b></div>
                <div class="kv__item"><span>当前状态</span><b>{{ selectedBatch.status }}</b></div>
              </div>
            </div>

            <label class="field">
              <span class="field__label">生成数量</span>
              <input
                v-model.number="quantity"
                class="input"
                type="number"
                min="1"
                :max="maxQuantity"
                :disabled="!selectedBatch || generating"
              />
            </label>
            <div class="field">
              <span class="field__label">赋码说明</span>
              <div class="notice notice--brand" style="height: 36px; align-items: center">
                编号规则：批次号 + 4 位流水号
              </div>
            </div>
            <label class="field span-2">
              <span class="field__label">备注</span>
              <textarea v-model="remark" class="textarea" placeholder="记录本次赋码用途、打印批次或操作人备注" :disabled="generating" />
            </label>
          </div>

          <div v-if="generating || progress > 0" class="progress-wrap">
            <div class="row row--between">
              <span class="field__label">{{ generating ? '正在生成溯源码…' : '生成完成' }}</span>
              <b class="num">{{ progress }}%</b>
            </div>
            <div class="progress">
              <div class="progress__bar" :style="{ width: `${progress}%` }" />
            </div>
          </div>

          <div class="form-foot">
            <button class="btn" type="button" :disabled="generating" @click="downloadAll">下载全部</button>
            <button class="btn btn--primary" type="button" :disabled="!selectedBatch || generating" @click="generate">
              {{ generating ? '生成中…' : '生成溯源码' }}
            </button>
          </div>
        </div>
      </section>

      <section class="card">
        <div class="card__head">
          <div class="card__title">溯源码预览 <span class="card__sub">首枚</span></div>
          <span class="tag tag--brand">{{ results.length ? '已生成' : '待生成' }}</span>
        </div>
        <div class="card__body preview">
          <QrCode v-if="previewCode" :text="previewCode" :size="210" />
          <div v-if="previewCode" class="preview__code">{{ previewCode }}</div>
          <div v-else class="empty">
            <div class="empty__mark">码</div>
            <span>请选择待赋码批次</span>
          </div>
          <div class="legend" style="justify-content: center; margin-top: 10px">
            <span>批次 {{ selectedBatch?.batchNo ?? '—' }}</span>
            <span>作物 {{ selectedBatch?.crop ?? '—' }}</span>
          </div>
          <div class="preview__hint">消费者扫码进入 H5 溯源页，查看产地、检测与农事记录</div>
        </div>
      </section>
    </div>

    <section class="card" style="margin-top: 16px">
      <div class="card__head">
        <div class="card__title">
          生成结果 <span class="card__sub">{{ results.length }} 枚</span>
        </div>
        <div class="row" style="gap: 8px">
          <button class="btn btn--sm" type="button" @click="downloadQr">下载二维码</button>
          <button class="btn btn--sm btn--primary" type="button" @click="downloadAll">下载全部</button>
        </div>
      </div>
      <div class="card__body">
        <div v-if="results.length > 0" class="qr-grid">
          <div v-for="item in results" :key="item.code" class="qr-item">
            <QrCode :text="item.code" :size="58" />
            <div class="qr-item__info">
              <b class="num">{{ item.code }}</b>
              <span>{{ item.batchNo }}</span>
              <div class="row" style="gap: 6px">
                <span class="tag">#{{ item.seq }}</span>
                <StatusTag text="待打印" tone="info" />
              </div>
            </div>
          </div>
        </div>
        <div v-else class="empty">
          <div class="empty__mark">码</div>
          <span>尚未生成溯源码，请先选择批次并设置生成数量</span>
        </div>
      </div>
    </section>
  </div>
</template>

<style scoped>
.preview {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding-top: 22px;
}

.preview__code {
  margin-top: 12px;
  font-family: var(--font-num);
  font-size: 12.5px;
  font-weight: 600;
  color: var(--ink);
}

.preview__hint {
  margin-top: 16px;
  padding-top: 12px;
  border-top: 1px dashed var(--line);
  font-size: 11.5px;
  line-height: 1.7;
  color: var(--muted);
  text-align: center;
}

.progress-wrap {
  margin-top: 16px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.qr-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(215px, 1fr));
  gap: 12px;
}

.qr-item {
  display: flex;
  align-items: center;
  gap: 11px;
  padding: 10px;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: var(--surface-2);
}

.qr-item__info {
  display: flex;
  flex-direction: column;
  gap: 3px;
  min-width: 0;
}

.qr-item__info b {
  font-size: 12px;
  color: var(--ink);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.qr-item__info span {
  font-size: 10.5px;
  color: var(--muted);
}
</style>
