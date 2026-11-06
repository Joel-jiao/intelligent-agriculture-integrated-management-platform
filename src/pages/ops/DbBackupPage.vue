<script setup lang="ts">
import { computed, onUnmounted, reactive, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { backups, sysInfo } from '@/data/mock'
import type { BackupRecord } from '@/data/types'
import { buildCsv, downloadText, formatNumber, nowDateTime, nowTime } from '@/utils/format'

const toast = useToast()

const records = ref<BackupRecord[]>(backups.map((item) => ({ ...item })))
const backingUp = ref(false)
const progress = ref(0)
let timer: number | undefined

const lastBackup = computed(() => records.value[0]?.createdAt ?? '—')
const lastSize = computed(() => records.value[0]?.size ?? '—')
const totalSize = computed(() => records.value.length * 426)

const storage = reactive({ used: 486, total: 1024 })
const storagePercent = computed(() => Math.round((storage.used / storage.total) * 100))

function startBackup() {
  if (backingUp.value) return
  backingUp.value = true
  progress.value = 0
  timer = window.setInterval(() => {
    progress.value = Math.min(100, progress.value + 10)
    if (progress.value >= 100) {
      if (timer !== undefined) window.clearInterval(timer)
      timer = undefined
      backingUp.value = false
      const stamp = nowTime().replace(/:/g, '')
      records.value.unshift({
        id: `BK-${String(records.value.length + 1).padStart(2, '0')}`,
        name: `agri_manual_20261106_${stamp}.sql.gz`,
        size: '429 MB',
        type: '手动',
        createdAt: nowDateTime(),
        status: '成功',
      })
      toast.success('手动备份已完成，备份文件已写入对象存储')
    }
  }, 200)
}

onUnmounted(() => {
  if (timer !== undefined) window.clearInterval(timer)
})

const restoreTarget = ref<BackupRecord | null>(null)
const restoreConfirm = ref('')
const restoreOpen = computed({
  get: () => restoreTarget.value !== null,
  set: (value: boolean) => {
    if (!value) {
      restoreTarget.value = null
      restoreConfirm.value = ''
    }
  },
})

function openRestore(record: BackupRecord) {
  restoreTarget.value = record
  restoreConfirm.value = ''
}

function confirmRestore() {
  const target = restoreTarget.value
  if (!target) return
  if (restoreConfirm.value.trim() !== 'RESTORE') {
    toast.error('请输入 RESTORE 确认口令后再执行恢复')
    return
  }
  restoreTarget.value = null
  restoreConfirm.value = ''
  toast.success(`已提交恢复任务（${target.name}），系统将于维护窗口执行`)
}

const deleteTarget = ref<BackupRecord | null>(null)
const deleteOpen = computed({
  get: () => deleteTarget.value !== null,
  set: (value: boolean) => {
    if (!value) deleteTarget.value = null
  },
})

function confirmDelete() {
  const target = deleteTarget.value
  if (!target) return
  records.value = records.value.filter((item) => item.id !== target.id)
  deleteTarget.value = null
  toast.success(`备份文件 ${target.name} 已删除`)
}

function downloadRecord(record: BackupRecord) {
  downloadText(record.name.replace('.sql.gz', '.txt'), `模拟备份文件：${record.name}\n生成时间：${record.createdAt}\n大小：${record.size}\n说明：演示环境导出为占位文本。`)
  toast.success(`备份文件 ${record.name} 已开始下载`)
}

const autoForm = reactive({ frequency: '每日', keep: 30, enabled: true })

function saveAuto() {
  if (autoForm.keep < 3 || autoForm.keep > 180) {
    toast.error('保留份数需在 3 到 180 之间')
    return
  }
  toast.success(`自动备份设置已保存：${autoForm.frequency}执行，保留 ${autoForm.keep} 份`)
}

function exportBackups() {
  const list = records.value.map((item) => [item.name, item.size, item.type, item.createdAt, item.status])
  downloadText('数据库备份记录_20261106.csv', buildCsv(['文件名', '大小', '类型', '时间', '状态'], list))
  toast.success(`已导出 ${list.length} 条备份记录`)
}
</script>

<template>
  <div>
    <PageHeader eyebrow="BACKUP & RESTORE" title="数据库备份恢复" description="管理业务数据库全量备份、恢复演练与保留策略，保障数据可回溯">
      <template #actions>
        <button class="btn" type="button" @click="exportBackups">导出记录</button>
        <button class="btn btn--primary" type="button" :disabled="backingUp" @click="startBackup">
          {{ backingUp ? `备份中 ${progress}%` : '立即备份' }}
        </button>
      </template>
    </PageHeader>

    <div class="grid grid--main">
      <div class="stack">
        <section class="card card--tint">
          <div class="card__head">
            <div class="card__title">数据库状态 <span class="card__sub">{{ sysInfo.db }}</span></div>
            <StatusTag text="运行中" tone="ok" dot />
          </div>
          <div class="card__body">
            <div class="kv kv--3">
              <div class="kv__item"><span>数据库版本</span><b>{{ sysInfo.db }}</b></div>
              <div class="kv__item"><span>数据大小</span><b>428 MB</b></div>
              <div class="kv__item"><span>上次备份</span><b>{{ lastBackup }}</b></div>
              <div class="kv__item"><span>最新备份文件</span><b>{{ lastSize }}</b></div>
              <div class="kv__item"><span>保留策略</span><b>保留 30 天 · 每日全量</b></div>
              <div class="kv__item"><span>存储引擎</span><b>InnoDB · utf8mb4</b></div>
              <div class="kv__item"><span>binlog 保留</span><b>7 天</b></div>
              <div class="kv__item"><span>备份总量</span><b>{{ records.length }} 份</b></div>
              <div class="kv__item"><span>累计备份体积</span><b>{{ formatNumber(totalSize) }} MB</b></div>
            </div>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">备份记录 <span class="card__sub">共 {{ records.length }} 份</span></div>
            <span class="tag tag--brand">对象存储 · 同城双活</span>
          </div>
          <div class="card__body" style="padding-bottom: 8px">
            <div v-if="backingUp" class="backup-progress">
              <div class="row row--between" style="margin-bottom: 7px">
                <span>正在执行全量备份 · 请勿关闭页面</span>
                <b>{{ progress }}%</b>
              </div>
              <div class="progress">
                <div class="progress__bar" :style="{ width: `${progress}%` }" />
              </div>
            </div>
            <div class="table-wrap">
              <table class="data-table">
                <thead>
                  <tr>
                    <th>文件名</th>
                    <th>大小</th>
                    <th>类型</th>
                    <th>时间</th>
                    <th>状态</th>
                    <th>操作</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="record in records" :key="record.id">
                    <td class="cell-strong">{{ record.name }}</td>
                    <td class="num">{{ record.size }}</td>
                    <td><span class="tag" :class="record.type === '手动' ? 'tag--warn' : 'tag--info'">{{ record.type }}</span></td>
                    <td class="num">{{ record.createdAt }}</td>
                    <td><StatusTag :text="record.status" :tone="record.status === '成功' ? 'ok' : record.status === '进行中' ? 'warn' : 'danger'" dot /></td>
                    <td>
                      <div class="table-actions">
                        <button class="link-action" type="button" @click="openRestore(record)">恢复</button>
                        <button class="link-action" type="button" @click="downloadRecord(record)">下载</button>
                        <button class="link-action link-action--danger" type="button" @click="deleteTarget = record">删除</button>
                      </div>
                    </td>
                  </tr>
                  <tr v-if="records.length === 0">
                    <td colspan="6">
                      <div class="empty"><span class="empty__mark">空</span>暂无备份记录，建议立即执行一次全量备份</div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </section>
      </div>

      <div class="stack">
        <section class="card">
          <div class="card__head">
            <div class="card__title">备份存储空间</div>
            <span class="tag" :class="storagePercent > 80 ? 'tag--warn' : 'tag--ok'">{{ storagePercent }}% 已用</span>
          </div>
          <div class="card__body">
            <div class="row row--between" style="margin-bottom: 8px; font-size: 12px; color: var(--muted)">
              <span>已用 {{ storage.used }} GB</span>
              <span>总配额 {{ storage.total }} GB</span>
            </div>
            <div class="progress">
              <div class="progress__bar" :class="{ 'progress__bar--warn': storagePercent > 80 }" :style="{ width: `${storagePercent}%` }" />
            </div>
            <div class="kv" style="margin-top: 16px">
              <div class="kv__item"><span>备份文件占用</span><b>412 GB</b></div>
              <div class="kv__item"><span>附件与媒体文件</span><b>58 GB</b></div>
              <div class="kv__item"><span>临时文件</span><b>16 GB</b></div>
              <div class="kv__item"><span>可清理空间</span><b>38 GB</b></div>
            </div>
            <div class="notice notice--warn" style="margin-top: 14px">
              <span>存储使用率超过 80% 时将自动清理 90 天前的备份文件，请提前确认保留策略。</span>
            </div>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">自动备份设置</div>
            <span class="tag" :class="autoForm.enabled ? 'tag--ok' : ''">{{ autoForm.enabled ? '已启用' : '已停用' }}</span>
          </div>
          <div class="card__body">
            <div class="form-grid">
              <label class="field">
                <span class="field__label">备份频率</span>
                <select v-model="autoForm.frequency" class="select">
                  <option value="每 6 小时">每 6 小时</option>
                  <option value="每日">每日</option>
                  <option value="每周">每周</option>
                  <option value="每月">每月</option>
                </select>
              </label>
              <label class="field">
                <span class="field__label">保留份数</span>
                <input v-model.number="autoForm.keep" class="input" type="number" min="3" max="180" />
              </label>
            </div>
            <label class="switch" style="margin-top: 14px">
              <input v-model="autoForm.enabled" type="checkbox" />
              <span class="switch__track" />
              <span>启用定时自动备份</span>
            </label>
            <div class="notice notice--brand" style="margin-top: 14px">
              <span>下次执行：{{ autoForm.enabled ? '2026-11-07 02:00:00' : '未排期' }}，执行结果将通过运维告警通道通知。</span>
            </div>
            <div class="form-foot">
              <button class="btn btn--primary" type="button" @click="saveAuto">保存设置</button>
            </div>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">恢复须知</div>
          </div>
          <div class="card__body">
            <div class="timeline">
              <div class="timeline__item timeline__item--done">
                <div class="timeline__title">提交恢复申请</div>
                <div class="timeline__desc">选择目标备份文件，系统校验文件完整性</div>
              </div>
              <div class="timeline__item">
                <div class="timeline__title">系统维护窗口</div>
                <div class="timeline__desc">默认在 02:00-04:00 执行，期间业务只读</div>
              </div>
              <div class="timeline__item">
                <div class="timeline__title">回放 binlog</div>
                <div class="timeline__desc">按需回放到指定时间点，减少数据丢失</div>
              </div>
            </div>
          </div>
        </section>
      </div>
    </div>

    <AppModal v-model="restoreOpen" title="恢复数据库备份">
      <div class="notice notice--danger">
        <span>恢复操作将覆盖当前数据库全部数据，并导致业务短暂中断。请确认已完成当前数据备份，且已获得负责人审批。</span>
      </div>
      <div class="kv" style="margin-top: 14px">
        <div class="kv__item"><span>备份文件</span><b>{{ restoreTarget?.name }}</b></div>
        <div class="kv__item"><span>文件大小</span><b>{{ restoreTarget?.size }}</b></div>
        <div class="kv__item"><span>备份时间</span><b>{{ restoreTarget?.createdAt }}</b></div>
        <div class="kv__item"><span>备份类型</span><b>{{ restoreTarget?.type }}备份</b></div>
      </div>
      <div class="field" style="margin-top: 14px">
        <span class="field__label">恢复确认口令</span>
        <input v-model="restoreConfirm" class="input" placeholder="请输入 RESTORE 以确认执行" />
      </div>
      <template #footer>
        <button class="btn" type="button" @click="restoreTarget = null">取消</button>
        <button class="btn btn--danger" type="button" :disabled="restoreConfirm.trim() !== 'RESTORE'" @click="confirmRestore">确认恢复</button>
      </template>
    </AppModal>

    <AppModal v-model="deleteOpen" title="删除备份文件">
      <div class="notice notice--danger">
        <span>删除后该备份文件不可找回，请确认保留策略允许清理此时间点的数据。</span>
      </div>
      <div class="kv" style="margin-top: 14px">
        <div class="kv__item"><span>文件名</span><b>{{ deleteTarget?.name }}</b></div>
        <div class="kv__item"><span>大小</span><b>{{ deleteTarget?.size }}</b></div>
        <div class="kv__item"><span>备份类型</span><b>{{ deleteTarget?.type }}</b></div>
        <div class="kv__item"><span>备份时间</span><b>{{ deleteTarget?.createdAt }}</b></div>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="deleteTarget = null">取消</button>
        <button class="btn btn--danger" type="button" @click="confirmDelete">确认删除</button>
      </template>
    </AppModal>
  </div>
</template>

<style scoped>
.backup-progress {
  margin-bottom: 14px;
  padding: 11px 13px;
  border: 1px dashed var(--line-strong);
  border-radius: 9px;
  background: var(--brand-softer);
  font-size: 12px;
  color: var(--brand-dark);
}

.backup-progress b {
  font-family: var(--font-num);
}

.link-action--danger {
  color: var(--danger);
}
</style>
