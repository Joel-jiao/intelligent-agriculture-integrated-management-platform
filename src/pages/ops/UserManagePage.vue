<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import Pager from '@/components/ui/Pager.vue'
import { useToast } from '@/composables/useToast'
import { plots, roles, users } from '@/data/mock'
import type { SysUser } from '@/data/types'
import { buildCsv, downloadText } from '@/utils/format'

const toast = useToast()

const rows = ref<SysUser[]>(users.map((item) => ({ ...item })))
const roleOptions = roles.map((item) => item.name)
const scopeOptions = Array.from(
  new Set(['全部地块', '系统全部', '璧山区辖区', ...plots.map((item) => item.name), ...users.map((item) => item.plotScope)]),
)

const roleFilter = ref('')
const statusFilter = ref('')
const keyword = ref('')
const page = ref(1)
const pageSize = 6

const filtered = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  return rows.value.filter((item) => {
    if (roleFilter.value && item.role !== roleFilter.value) return false
    if (statusFilter.value && item.status !== statusFilter.value) return false
    if (!kw) return true
    return [item.account, item.name, item.phone, item.plotScope].some((field) => field.toLowerCase().includes(kw))
  })
})

const paged = computed(() => {
  const start = (page.value - 1) * pageSize
  return filtered.value.slice(start, start + pageSize)
})

watch([roleFilter, statusFilter, keyword], () => {
  page.value = 1
})

const totalCount = computed(() => rows.value.length)
const enabledCount = computed(() => rows.value.filter((item) => item.status === '启用').length)
const disabledCount = computed(() => rows.value.filter((item) => item.status === '停用').length)
const farmerCount = computed(() => rows.value.filter((item) => item.role === '农户').length)

interface UserForm {
  account: string
  name: string
  role: string
  phone: string
  plotScope: string
  status: '启用' | '停用'
}

const editOpen = ref(false)
const editingId = ref<string | null>(null)
const form = reactive<UserForm>({
  account: '',
  name: '',
  role: '农户',
  phone: '',
  plotScope: '全部地块',
  status: '启用',
})

function resetForm() {
  form.account = ''
  form.name = ''
  form.role = '农户'
  form.phone = ''
  form.plotScope = '全部地块'
  form.status = '启用'
}

function openCreate() {
  editingId.value = null
  resetForm()
  editOpen.value = true
}

function openEdit(user: SysUser) {
  editingId.value = user.id
  form.account = user.account
  form.name = user.name
  form.role = user.role
  form.phone = user.phone
  form.plotScope = user.plotScope
  form.status = user.status
  editOpen.value = true
}

function saveUser() {
  const account = form.account.trim()
  const name = form.name.trim()
  if (!account || !name) {
    toast.error('账号与姓名不能为空')
    return
  }
  const duplicated = rows.value.some((item) => item.account === account && item.id !== editingId.value)
  if (duplicated) {
    toast.error(`账号 ${account} 已存在，请更换`)
    return
  }
  const payload = {
    account,
    name,
    role: form.role,
    phone: form.phone.trim() || '—',
    plotScope: form.plotScope,
    status: form.status,
  }
  if (editingId.value) {
    const target = rows.value.find((item) => item.id === editingId.value)
    if (target) Object.assign(target, payload)
    toast.success(`用户 ${name} 的资料已更新`)
  } else {
    const nextId = `U-${String(rows.value.length + 1).padStart(3, '0')}`
    rows.value.unshift({ id: nextId, ...payload, lastLogin: '—', createdAt: '2026-11-06' })
    toast.success(`用户 ${name} 已创建，初始密码已发送至绑定手机`)
  }
  editOpen.value = false
}

function toggleStatus(user: SysUser) {
  user.status = user.status === '启用' ? '停用' : '启用'
  toast.success(`用户 ${user.name} 已${user.status}`)
}

const resetTarget = ref<SysUser | null>(null)
const resetOpen = computed({
  get: () => resetTarget.value !== null,
  set: (value: boolean) => {
    if (!value) resetTarget.value = null
  },
})

function openReset(user: SysUser) {
  resetTarget.value = user
}

function confirmReset() {
  const target = resetTarget.value
  if (!target) return
  toast.success(`已重置 ${target.name} 的密码，临时密码已发送至 ${target.phone}`)
  resetTarget.value = null
}

const deleteTarget = ref<SysUser | null>(null)
const deleteOpen = computed({
  get: () => deleteTarget.value !== null,
  set: (value: boolean) => {
    if (!value) deleteTarget.value = null
  },
})

function openDelete(user: SysUser) {
  if (user.account === 'admin' || user.account === 'ops') {
    toast.error('内置管理账号不允许删除')
    return
  }
  deleteTarget.value = user
}

function confirmDelete() {
  const target = deleteTarget.value
  if (!target) return
  rows.value = rows.value.filter((item) => item.id !== target.id)
  if (page.value > 1 && paged.value.length === 0) page.value -= 1
  toast.success(`用户 ${target.name} 已删除`)
  deleteTarget.value = null
}

function exportUsers() {
  const rowsToExport = filtered.value.map((item) => [item.account, item.name, item.role, item.phone, item.plotScope, item.status, item.lastLogin])
  downloadText('系统用户清单_20261106.csv', buildCsv(['账号', '姓名', '角色', '手机', '地块范围', '状态', '最后登录'], rowsToExport))
  toast.success(`已导出 ${rowsToExport.length} 条用户记录`)
}
</script>

<template>
  <div>
    <PageHeader eyebrow="USER MANAGEMENT" title="系统用户管理" description="统一维护管理员、运维、农户与监管账号，控制登录状态与数据可见范围">
      <template #actions>
        <button class="btn" type="button" @click="exportUsers">导出用户</button>
        <button class="btn btn--primary" type="button" @click="openCreate">新增用户</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="用户总数" :value="totalCount" unit="个" icon="用" note="覆盖 4 类角色" trend="本月新增 2" trend-up />
      <StatCard label="启用账号" :value="enabledCount" unit="个" icon="启" note="可正常登录系统" trend="启用率 86%" />
      <StatCard label="停用账号" :value="disabledCount" unit="个" icon="停" note="离职或待复核账号" trend="较上月持平" />
      <StatCard label="农户账号" :value="farmerCount" unit="个" icon="农" note="绑定地块作业范围" trend="移动端在用" accent />
    </div>

    <section class="card">
      <div class="card__body" style="padding-bottom: 0">
        <div class="toolbar">
          <div class="field">
            <span class="field__label">角色</span>
            <select v-model="roleFilter" class="select" style="width: 132px">
              <option value="">全部角色</option>
              <option v-for="role in roleOptions" :key="role" :value="role">{{ role }}</option>
            </select>
          </div>
          <div class="field">
            <span class="field__label">状态</span>
            <select v-model="statusFilter" class="select" style="width: 108px">
              <option value="">全部状态</option>
              <option value="启用">启用</option>
              <option value="停用">停用</option>
            </select>
          </div>
          <div class="field" style="flex: 1; min-width: 180px">
            <span class="field__label">关键词</span>
            <input v-model="keyword" class="input" placeholder="搜索账号 / 姓名 / 手机 / 地块范围" />
          </div>
          <button class="btn btn--sm" type="button" style="margin-top: 18px" @click="roleFilter = ''; statusFilter = ''; keyword = ''">重置筛选</button>
          <div class="toolbar__spacer" />
          <span class="tag tag--brand" style="margin-top: 18px">共 {{ filtered.length }} 条</span>
        </div>

        <div class="table-wrap">
          <table class="data-table">
            <thead>
              <tr>
                <th>账号</th>
                <th>姓名</th>
                <th>角色</th>
                <th>手机</th>
                <th>地块范围</th>
                <th>状态</th>
                <th>最后登录</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="user in paged" :key="user.id">
                <td class="cell-strong">{{ user.account }}</td>
                <td>{{ user.name }}</td>
                <td>
                  <span class="tag" :class="user.role === '运维' ? 'tag--brand' : user.role === '农户' ? 'tag--info' : ''">{{ user.role }}</span>
                </td>
                <td class="num">{{ user.phone }}</td>
                <td class="cell-muted">{{ user.plotScope }}</td>
                <td><StatusTag :text="user.status" :tone="user.status === '启用' ? 'ok' : 'mute'" dot /></td>
                <td class="num">{{ user.lastLogin }}</td>
                <td>
                  <div class="table-actions">
                    <button class="link-action" type="button" @click="openEdit(user)">编辑</button>
                    <button class="link-action" type="button" @click="toggleStatus(user)">{{ user.status === '启用' ? '停用' : '启用' }}</button>
                    <button class="link-action" type="button" @click="openReset(user)">重置密码</button>
                    <button class="link-action link-action--danger" type="button" @click="openDelete(user)">删除</button>
                  </div>
                </td>
              </tr>
              <tr v-if="paged.length === 0">
                <td colspan="8">
                  <div class="empty"><span class="empty__mark">空</span>没有符合条件的用户，请调整筛选条件</div>
                </td>
              </tr>
            </tbody>
          </table>
          <Pager :total="filtered.length" :page="page" :page-size="pageSize" @update:page="page = $event" />
        </div>
      </div>
    </section>

    <AppModal v-model="editOpen" :title="editingId ? '编辑用户' : '新增用户'">
      <div class="form-grid">
        <label class="field">
          <span class="field__label">登录账号</span>
          <input v-model="form.account" class="input" placeholder="字母或数字，4-20 位" />
        </label>
        <label class="field">
          <span class="field__label">真实姓名</span>
          <input v-model="form.name" class="input" placeholder="请输入姓名" />
        </label>
        <label class="field">
          <span class="field__label">角色</span>
          <select v-model="form.role" class="select">
            <option v-for="role in roleOptions" :key="role" :value="role">{{ role }}</option>
          </select>
        </label>
        <label class="field">
          <span class="field__label">手机号</span>
          <input v-model="form.phone" class="input" placeholder="用于接收验证码与告警" />
        </label>
        <label class="field">
          <span class="field__label">地块范围</span>
          <select v-model="form.plotScope" class="select">
            <option v-for="scope in scopeOptions" :key="scope" :value="scope">{{ scope }}</option>
          </select>
        </label>
        <label class="field">
          <span class="field__label">账号状态</span>
          <select v-model="form.status" class="select">
            <option value="启用">启用</option>
            <option value="停用">停用</option>
          </select>
        </label>
      </div>
      <div class="notice notice--brand" style="margin-top: 14px">
        <span>新建账号将随机生成初始密码，有效期为 24 小时，首次登录需强制修改。</span>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="editOpen = false">取消</button>
        <button class="btn btn--primary" type="button" @click="saveUser">保存</button>
      </template>
    </AppModal>

    <AppModal v-model="resetOpen" title="重置登录密码">
      <div class="notice notice--warn">
        <span>即将重置账号 <b>{{ resetTarget?.name }}</b>（{{ resetTarget?.account }}）的登录密码，原密码立即失效。</span>
      </div>
      <div class="kv" style="margin-top: 14px">
        <div class="kv__item"><span>绑定手机</span><b>{{ resetTarget?.phone }}</b></div>
        <div class="kv__item"><span>重置方式</span><b>短信临时密码</b></div>
        <div class="kv__item"><span>有效期</span><b>24 小时</b></div>
        <div class="kv__item"><span>最近登录</span><b>{{ resetTarget?.lastLogin }}</b></div>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="resetTarget = null">取消</button>
        <button class="btn btn--primary" type="button" @click="confirmReset">确认重置</button>
      </template>
    </AppModal>

    <AppModal v-model="deleteOpen" title="删除用户">
      <div class="notice notice--danger">
        <span>删除后该账号将无法登录，且历史操作日志仍会保留。此操作不可撤销。</span>
      </div>
      <div class="kv" style="margin-top: 14px">
        <div class="kv__item"><span>账号</span><b>{{ deleteTarget?.account }}</b></div>
        <div class="kv__item"><span>姓名</span><b>{{ deleteTarget?.name }}</b></div>
        <div class="kv__item"><span>角色</span><b>{{ deleteTarget?.role }}</b></div>
        <div class="kv__item"><span>最后登录</span><b>{{ deleteTarget?.lastLogin }}</b></div>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="deleteTarget = null">取消</button>
        <button class="btn btn--danger" type="button" @click="confirmDelete">确认删除</button>
      </template>
    </AppModal>
  </div>
</template>

<style scoped>
.link-action--danger {
  color: var(--danger);
}
</style>
