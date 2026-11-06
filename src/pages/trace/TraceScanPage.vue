<script setup lang="ts">
import { ref } from 'vue'
import QrCode from '@/components/ui/QrCode.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import { useToast } from '@/composables/useToast'
import { findPlot, plots } from '@/data/mock'
import { nowDateTime, today } from '@/utils/format'

type Grade = '特级' | '一级' | '二级'
type Result = '合格' | '不合格'

const toast = useToast()

const scannedCode = ref('')

function scanCode() {
  const suffix = String(Math.floor(Math.random() * 9000) + 1000)
  scannedCode.value = `B20261106-${suffix}`
  toast.success(`扫码成功，已生成溯源码 ${scannedCode.value}`)
}

const form = ref({
  plotId: plots[0]?.id ?? '',
  crop: plots[0]?.crop ?? '',
  weight: '',
  grade: '一级' as Grade,
  result: '合格' as Result,
  remark: '',
})

function onPlotChange() {
  const plot = findPlot(form.value.plotId)
  form.value.crop = plot?.crop ?? ''
}

const photoName = ref('')

function onPhotoChange(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return
  photoName.value = file.name
  toast.success('现场照片已添加')
  input.value = ''
}

interface TraceRecord {
  id: number
  code: string
  plot: string
  crop: string
  weight: string
  grade: Grade
  result: Result
  time: string
}

const records = ref<TraceRecord[]>([])
let recordSeq = 0

function submitRecord() {
  if (!scannedCode.value) {
    toast.warn('请先模拟扫码生成溯源码')
    return
  }
  const raw = form.value.weight.trim()
  const weight = Number(raw)
  if (raw === '' || !Number.isFinite(weight) || weight <= 0) {
    toast.warn('请填写有效的采收重量')
    return
  }
  const plot = findPlot(form.value.plotId)
  if (!plot) {
    toast.warn('请选择有效的地块')
    return
  }
  recordSeq += 1
  records.value.unshift({
    id: recordSeq,
    code: scannedCode.value,
    plot: plot.name,
    crop: form.value.crop || plot.crop,
    weight: `${weight} kg`,
    grade: form.value.grade,
    result: form.value.result,
    time: nowDateTime(),
  })
  toast.success(`录入成功，溯源码 ${scannedCode.value} 已同步溯源档案`)
  form.value.weight = ''
  form.value.remark = ''
  photoName.value = ''
}
</script>

<template>
  <div class="mobile-page">
    <header class="page-head">
      <div>
        <h2>扫码溯源录入</h2>
        <p>{{ today() }} · 采收与检测信息登记</p>
      </div>
      <span class="tag tag--brand">移动录入</span>
    </header>

    <section class="mobile-card scan-card">
      <div class="scan-head">
        <span class="mobile-icon">码</span>
        <div>
          <div class="scan-title">扫描产品追溯码</div>
          <div class="scan-desc">扫描包装上的批次码，自动生成新的溯源码并关联地块档案</div>
        </div>
      </div>
      <button class="mobile-btn mobile-btn--full scan-btn" type="button" @click="scanCode">
        {{ scannedCode ? '重新模拟扫码' : '模拟扫码' }}
      </button>
      <div v-if="scannedCode" class="code-box">
        <span>本次溯源码</span>
        <b class="font-num">{{ scannedCode }}</b>
        <small>已关联 {{ form.crop || '当前地块作物' }} · {{ findPlot(form.plotId)?.name ?? '园区地块' }}</small>
      </div>
      <p v-else class="scan-hint">演示环境点击按钮即生成 B20261106-xxxx 格式的溯源码</p>
    </section>

    <section v-if="scannedCode" class="mobile-section">
      <div class="mobile-section__head">
        <h3>溯源二维码预览</h3>
        <span>扫码查看全流程</span>
      </div>
      <div class="mobile-card qr-card">
        <QrCode :text="scannedCode" :size="152" />
        <b class="qr-code-text font-num">{{ scannedCode }}</b>
        <p>消费者扫码可查看种植、检测、采收与赋码信息</p>
      </div>
    </section>

    <section class="mobile-section">
      <div class="mobile-section__head">
        <h3>录入信息</h3>
        <span class="tag tag--outline">必填项</span>
      </div>
      <div class="mobile-card">
        <label class="mobile-field">
          <span>地块</span>
          <select v-model="form.plotId" @change="onPlotChange">
            <option v-for="plot in plots" :key="plot.id" :value="plot.id">{{ plot.name }}（{{ plot.crop }}）</option>
          </select>
        </label>
        <label class="mobile-field">
          <span>作物</span>
          <input v-model="form.crop" type="text" placeholder="如 番茄" />
        </label>
        <label class="mobile-field">
          <span>采收重量（kg）</span>
          <input v-model="form.weight" type="number" min="0" step="0.1" placeholder="请输入本次采收重量" />
        </label>
        <label class="mobile-field">
          <span>等级</span>
          <select v-model="form.grade">
            <option value="特级">特级</option>
            <option value="一级">一级</option>
            <option value="二级">二级</option>
          </select>
        </label>
        <label class="mobile-field">
          <span>检测结论</span>
          <select v-model="form.result">
            <option value="合格">合格</option>
            <option value="不合格">不合格</option>
          </select>
        </label>
        <label class="mobile-field">
          <span>备注</span>
          <textarea v-model="form.remark" placeholder="可填写采收批次、检测机构等补充信息" />
        </label>

        <label class="mobile-upload upload-box">
          <input class="upload-input" type="file" accept="image/*" @change="onPhotoChange" />
          <span>{{ photoName ? `已选择：${photoName}` : '拍照上传现场照片' }}</span>
        </label>

        <p class="sync-note">录入后自动同步溯源档案，并生成对应批次的扫码查询记录。</p>

        <button class="mobile-btn mobile-btn--full submit-btn" type="button" @click="submitRecord">
          提交溯源录入
        </button>
      </div>
    </section>

    <section class="mobile-section">
      <div class="mobile-section__head">
        <h3>今日录入记录</h3>
        <span>{{ records.length }} 条</span>
      </div>
      <div v-if="records.length > 0" class="record-list">
        <div v-for="record in records" :key="record.id" class="mobile-card record-card">
          <div class="record-top">
            <b class="font-num">{{ record.code }}</b>
            <StatusTag :text="record.result" :tone="record.result === '合格' ? 'ok' : 'danger'" dot />
          </div>
          <div class="record-meta">{{ record.plot }} · {{ record.crop }} · {{ record.weight }} · {{ record.grade }}</div>
          <div class="record-time font-num">{{ record.time }}</div>
        </div>
      </div>
      <div v-else class="mobile-card empty-card">
        <span class="empty-mark">空</span>
        <p>今日尚未录入溯源信息</p>
      </div>
    </section>

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

.scan-card {
  background: linear-gradient(160deg, var(--brand-softer), #fff 65%);
}

.scan-head {
  display: flex;
  align-items: flex-start;
  gap: 10px;
}

.scan-title {
  font-size: 14px;
  font-weight: 650;
  color: var(--ink);
}

.scan-desc {
  margin-top: 3px;
  font-size: 11px;
  line-height: 1.6;
  color: var(--muted);
}

.scan-btn {
  margin-top: 13px;
}

.code-box {
  margin-top: 11px;
  padding: 11px 12px;
  border: 1px dashed var(--line-strong);
  border-radius: 10px;
  background: #fff;
}

.code-box span {
  display: block;
  font-size: 10.5px;
  color: var(--muted);
}

.code-box b {
  display: block;
  margin-top: 2px;
  font-size: 17px;
  letter-spacing: 0.5px;
  color: var(--brand-dark);
}

.code-box small {
  display: block;
  margin-top: 3px;
  font-size: 10px;
  color: var(--faint);
}

.scan-hint {
  margin-top: 9px;
  font-size: 10.5px;
  color: var(--faint);
}

.qr-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 7px;
  text-align: center;
}

.qr-code-text {
  font-size: 14px;
  letter-spacing: 0.5px;
  color: var(--ink);
}

.qr-card p {
  font-size: 10.5px;
  line-height: 1.6;
  color: var(--muted);
}

.upload-box {
  position: relative;
  margin-top: 2px;
}

.upload-input {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  opacity: 0;
  cursor: pointer;
}

.sync-note {
  margin-top: 10px;
  padding: 9px 10px;
  border-radius: 9px;
  background: var(--brand-soft);
  color: var(--brand-dark);
  font-size: 10.5px;
  line-height: 1.6;
}

.submit-btn {
  margin-top: 12px;
}

.record-list {
  display: block;
}

.record-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
}

.record-top b {
  font-size: 13px;
  color: var(--ink);
}

.record-meta {
  margin-top: 4px;
  font-size: 11px;
  color: var(--muted);
}

.record-time {
  margin-top: 3px;
  font-size: 10px;
  color: var(--faint);
}

.empty-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 7px;
  padding: 26px 16px;
}

.empty-card p {
  font-size: 11.5px;
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

.page-spacer {
  height: 24px;
}
</style>
