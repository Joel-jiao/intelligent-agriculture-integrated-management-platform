<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { openApis, sysInfo } from '@/data/mock'
import type { OpenApi } from '@/data/types'
import { buildCsv, downloadText, formatNumber, nowDateTime } from '@/utils/format'

const toast = useToast()

const rows = ref<OpenApi[]>(openApis.map((item) => ({ ...item })))
const keyword = ref('')

const filtered = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  if (!kw) return rows.value
  return rows.value.filter((item) => [item.name, item.path, item.target, item.method].some((field) => field.toLowerCase().includes(kw)))
})

const enabledCount = computed(() => rows.value.filter((item) => item.enabled).length)
const totalCalls = computed(() => rows.value.reduce((sum, item) => sum + item.calls, 0))

function genKey(seed: string): string {
  const hex = (length: number) => Math.random().toString(16).slice(2, 2 + length).padEnd(length, '0')
  return `ak_${seed}_${hex(4)}****${hex(4)}`
}

function copyText(text: string, label: string) {
  const clipboard = navigator.clipboard
  if (clipboard) {
    void clipboard.writeText(text).catch(() => undefined)
  }
  toast.success(`${label}已复制到剪贴板`)
}

function toggleApi(api: OpenApi) {
  toast.success(`接口「${api.name}」已${api.enabled ? '启用' : '停用'}`)
}

const editOpen = ref(false)
const editForm = reactive({ name: '', path: '', target: '', key: '' })
const editId = ref<string | null>(null)

function openEdit(api: OpenApi) {
  editId.value = api.id
  editForm.name = api.name
  editForm.path = api.path
  editForm.target = api.target
  editForm.key = api.key
  editOpen.value = true
}

function saveEdit() {
  if (!editForm.name.trim() || !editForm.path.trim() || !editForm.target.trim()) {
    toast.error('接口名称、路径与对接目标不能为空')
    return
  }
  const target = rows.value.find((item) => item.id === editId.value)
  if (!target) return
  target.name = editForm.name.trim()
  target.path = editForm.path.trim()
  target.target = editForm.target.trim()
  target.key = editForm.key
  target.updatedAt = nowDateTime()
  editOpen.value = false
  toast.success(`接口「${target.name}」配置已更新`)
}

const keyTarget = ref<OpenApi | null>(null)
const keyOpen = computed({
  get: () => keyTarget.value !== null,
  set: (value: boolean) => {
    if (!value) keyTarget.value = null
  },
})

function openKey(api: OpenApi) {
  keyTarget.value = api
}

function regenerateKey() {
  const target = keyTarget.value
  if (!target) return
  target.key = genKey(target.id.toLowerCase().replace(/-/g, ''))
  target.updatedAt = nowDateTime()
  keyTarget.value = null
  toast.success(`接口「${target.name}」的密钥已重新生成，请同步更新对接方`)
}

const testOpen = ref(false)
const testTarget = ref<OpenApi | null>(null)
const testResult = ref('')
const testing = ref(false)

function openTest(api: OpenApi) {
  testTarget.value = api
  testResult.value = ''
  testing.value = false
  testOpen.value = true
}

function sendTest() {
  const api = testTarget.value
  if (!api || testing.value) return
  testing.value = true
  testResult.value = ''
  window.setTimeout(() => {
    testResult.value = JSON.stringify(
      {
        code: 200,
        message: 'success',
        requestId: `req-${api.id.toLowerCase()}-20261106`,
        timestamp: nowDateTime(),
        data: {
          interface: api.name,
          method: api.method,
          target: api.target,
          latency: 38,
          records: 12,
        },
      },
      null,
      2,
    )
    testing.value = false
    toast.success(`测试调用成功，响应耗时 38 ms`)
  }, 700)
}

const addOpen = ref(false)
const addForm = reactive<{ name: string; path: string; method: 'GET' | 'POST' | 'PUT'; target: string }>({
  name: '',
  path: '/api/v1/open/',
  method: 'GET',
  target: '',
})

function openAdd() {
  addForm.name = ''
  addForm.path = '/api/v1/open/'
  addForm.method = 'GET'
  addForm.target = ''
  addOpen.value = true
}

function createApi() {
  if (!addForm.name.trim() || !addForm.path.trim() || !addForm.target.trim()) {
    toast.error('接口名称、路径与对接目标不能为空')
    return
  }
  const id = `API-${String(rows.value.length + 1).padStart(2, '0')}`
  rows.value.push({
    id,
    name: addForm.name.trim(),
    path: addForm.path.trim(),
    method: addForm.method,
    target: addForm.target.trim(),
    enabled: true,
    calls: 0,
    updatedAt: nowDateTime(),
    key: genKey(id.toLowerCase().replace(/-/g, '')),
  })
  addOpen.value = false
  toast.success(`接口「${addForm.name}」已创建，默认处于启用状态`)
}

const deleteTarget = ref<OpenApi | null>(null)
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
  toast.success(`接口「${target.name}」已删除，对接方将无法继续调用`)
}

function exportApis() {
  const list = filtered.value.map((item) => [item.name, item.path, item.method, item.target, item.enabled ? '启用' : '停用', item.calls, item.updatedAt, item.key])
  downloadText('第三方接口清单_20261106.csv', buildCsv(['名称', '路径', '方法', '对接目标', '状态', '调用次数', '更新时间', '密钥'], list))
  toast.success(`已导出 ${list.length} 条接口配置`)
}
</script>

<template>
  <div>
    <PageHeader eyebrow="OPEN API" title="第三方接口管理" description="维护对外接口的启用状态、对接目标与访问密钥，所有调用均需签名校验">
      <template #actions>
        <button class="btn" type="button" @click="exportApis">导出配置</button>
        <button class="btn btn--primary" type="button" @click="openAdd">新增接口</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="接口总数" :value="rows.length" unit="个" icon="接" note="覆盖气象、监管、短信等" trend="本周新增 1" trend-up />
      <StatCard label="已启用" :value="enabledCount" unit="个" icon="启" note="停用接口不对外响应" trend="启用率 80%" />
      <StatCard label="今日调用" :value="formatNumber(sysInfo.apiCalls)" unit="次" icon="调" note="峰值 QPS 128" trend="+6.4% 环比" trend-up />
      <StatCard label="调用成功率" :value="99.2" unit="%" icon="成" note="失败主因：签名过期" trend="较昨日 +0.3%" trend-up accent />
    </div>

    <section class="card">
      <div class="card__body" style="padding-bottom: 0">
        <div class="toolbar">
          <div class="field" style="flex: 1; min-width: 220px">
            <span class="field__label">关键词</span>
            <input v-model="keyword" class="input" placeholder="搜索接口名称 / 路径 / 对接目标" />
          </div>
          <button class="btn btn--sm" type="button" style="margin-top: 18px" @click="keyword = ''">重置</button>
          <div class="toolbar__spacer" />
          <span class="tag tag--brand" style="margin-top: 18px">累计调用 {{ formatNumber(totalCalls) }} 次</span>
        </div>

        <div class="table-wrap">
          <table class="data-table">
            <thead>
              <tr>
                <th>接口名称</th>
                <th>请求路径</th>
                <th>方法</th>
                <th>对接目标</th>
                <th>状态</th>
                <th>调用次数</th>
                <th>更新时间</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="api in filtered" :key="api.id">
                <td class="cell-strong">{{ api.name }}</td>
                <td class="num">{{ api.path }}</td>
                <td>
                  <span class="tag" :class="api.method === 'POST' ? 'tag--brand' : api.method === 'PUT' ? 'tag--warn' : 'tag--info'">{{ api.method }}</span>
                </td>
                <td class="cell-muted">{{ api.target }}</td>
                <td>
                  <label class="switch">
                    <input v-model="api.enabled" type="checkbox" @change="toggleApi(api)" />
                    <span class="switch__track" />
                    <span class="switch__text">{{ api.enabled ? '启用' : '停用' }}</span>
                  </label>
                </td>
                <td class="num">{{ formatNumber(api.calls) }}</td>
                <td class="num">{{ api.updatedAt }}</td>
                <td>
                  <div class="table-actions">
                    <button class="link-action" type="button" @click="openEdit(api)">编辑</button>
                    <button class="link-action" type="button" @click="openKey(api)">密钥</button>
                    <button class="link-action" type="button" @click="openTest(api)">测试</button>
                    <button class="link-action link-action--danger" type="button" @click="deleteTarget = api">删除</button>
                  </div>
                </td>
              </tr>
              <tr v-if="filtered.length === 0">
                <td colspan="8">
                  <div class="empty"><span class="empty__mark">空</span>没有匹配的接口配置</div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>

    <AppModal v-model="editOpen" title="编辑接口配置" size="lg">
      <div class="form-grid">
        <label class="field">
          <span class="field__label">接口名称</span>
          <input v-model="editForm.name" class="input" />
        </label>
        <label class="field">
          <span class="field__label">请求路径</span>
          <input v-model="editForm.path" class="input" />
        </label>
        <label class="field">
          <span class="field__label">对接目标</span>
          <input v-model="editForm.target" class="input" />
        </label>
        <label class="field">
          <span class="field__label">访问密钥</span>
          <input v-model="editForm.key" class="input num" />
        </label>
      </div>
      <div class="notice notice--brand" style="margin-top: 14px">
        <span>密钥变更后旧密钥将在 5 分钟内失效，请提前通知对接方完成替换。</span>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="editOpen = false">取消</button>
        <button class="btn btn--primary" type="button" @click="saveEdit">保存配置</button>
      </template>
    </AppModal>

    <AppModal v-model="keyOpen" title="重新生成访问密钥">
      <div class="notice notice--warn">
        <span>重新生成后原密钥立即失效，正在进行的签名请求将被拒绝，请确认可承担短暂中断。</span>
      </div>
      <div class="kv" style="margin-top: 14px">
        <div class="kv__item"><span>接口名称</span><b>{{ keyTarget?.name }}</b></div>
        <div class="kv__item"><span>对接目标</span><b>{{ keyTarget?.target }}</b></div>
        <div class="kv__item"><span>最后更新</span><b>{{ keyTarget?.updatedAt }}</b></div>
      </div>
      <div class="field" style="margin-top: 14px">
        <span class="field__label">当前密钥</span>
        <div class="row">
          <input class="input num" :value="keyTarget?.key" readonly />
          <button class="btn btn--sm" type="button" @click="copyText(keyTarget?.key ?? '', '访问密钥')">复制密钥</button>
        </div>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="keyTarget = null">取消</button>
        <button class="btn btn--primary" type="button" @click="regenerateKey">重新生成</button>
      </template>
    </AppModal>

    <AppModal v-model="testOpen" title="测试接口调用" size="lg">
      <div v-if="testTarget" class="kv">
        <div class="kv__item"><span>接口名称</span><b>{{ testTarget.name }}</b></div>
        <div class="kv__item"><span>请求方法</span><b>{{ testTarget.method }}</b></div>
        <div class="kv__item"><span>请求路径</span><b class="num">{{ testTarget.path }}</b></div>
        <div class="kv__item"><span>对接目标</span><b>{{ testTarget.target }}</b></div>
      </div>
      <div class="field" style="margin-top: 14px">
        <span class="field__label">当前密钥</span>
        <div class="row">
          <input class="input num" :value="testTarget?.key" readonly />
          <button class="btn btn--sm" type="button" @click="copyText(testTarget?.key ?? '', '访问密钥')">复制</button>
        </div>
      </div>
      <div class="field" style="margin-top: 14px">
        <span class="field__label">响应结果</span>
        <pre class="test-result">{{ testing ? '正在发送测试请求…' : testResult || '尚未发起测试，点击下方按钮发送一次模拟请求。' }}</pre>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="testOpen = false">关闭</button>
        <button class="btn btn--primary" type="button" :disabled="testing" @click="sendTest">{{ testing ? '请求中…' : '发送测试请求' }}</button>
      </template>
    </AppModal>

    <AppModal v-model="addOpen" title="新增接口">
      <div class="form-grid">
        <label class="field">
          <span class="field__label">接口名称</span>
          <input v-model="addForm.name" class="input" placeholder="如：土壤墒情同步" />
        </label>
        <label class="field">
          <span class="field__label">请求方法</span>
          <select v-model="addForm.method" class="select">
            <option value="GET">GET</option>
            <option value="POST">POST</option>
            <option value="PUT">PUT</option>
          </select>
        </label>
        <label class="field span-2">
          <span class="field__label">请求路径</span>
          <input v-model="addForm.path" class="input" placeholder="以 /api/v1/open/ 开头" />
        </label>
        <label class="field span-2">
          <span class="field__label">对接目标</span>
          <input v-model="addForm.target" class="input" placeholder="如：璧山区农业监管平台" />
        </label>
      </div>
      <div class="notice notice--brand" style="margin-top: 14px">
        <span>创建后系统自动生成访问密钥，默认启用并按 IP 白名单限制调用来源。</span>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="addOpen = false">取消</button>
        <button class="btn btn--primary" type="button" @click="createApi">创建接口</button>
      </template>
    </AppModal>

    <AppModal v-model="deleteOpen" title="删除接口">
      <div class="notice notice--danger">
        <span>删除后该接口将立即不可访问，且调用记录不再纳入统计，请确认对接方已停止调用。</span>
      </div>
      <div class="kv" style="margin-top: 14px">
        <div class="kv__item"><span>接口名称</span><b>{{ deleteTarget?.name }}</b></div>
        <div class="kv__item"><span>请求路径</span><b class="num">{{ deleteTarget?.path }}</b></div>
        <div class="kv__item"><span>累计调用</span><b>{{ formatNumber(deleteTarget?.calls ?? 0) }} 次</b></div>
        <div class="kv__item"><span>状态</span><b>{{ deleteTarget?.enabled ? '启用' : '停用' }}</b></div>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="deleteTarget = null">取消</button>
        <button class="btn btn--danger" type="button" @click="confirmDelete">确认删除</button>
      </template>
    </AppModal>
  </div>
</template>

<style scoped>
.switch__text {
  white-space: nowrap;
}

.test-result {
  min-height: 150px;
  margin: 0;
  padding: 12px 14px;
  border: 1px solid var(--line);
  border-radius: 9px;
  background: var(--surface-2);
  font-family: var(--font-num);
  font-size: 11.5px;
  line-height: 1.7;
  color: var(--ink-2);
  white-space: pre-wrap;
  word-break: break-all;
}

.link-action--danger {
  color: var(--danger);
}
</style>
