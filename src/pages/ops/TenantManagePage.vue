<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import Pager from '@/components/ui/Pager.vue'
import { useToast } from '@/composables/useToast'
import { tenants as seedTenants } from '@/api/store'
import type { Tenant } from '@/data/types'

const toast = useToast()

const rows = ref<Tenant[]>(seedTenants.map((item) => ({ ...item })))
const keyword = ref('')
const statusFilter = ref('')
const page = ref(1)
const pageSize = 5

const filtered = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  return rows.value.filter((item) => {
    if (statusFilter.value && item.status !== statusFilter.value) return false
    if (!kw) return true
    return [item.name, item.code, item.contact, item.phone].some((field) => field.toLowerCase().includes(kw))
  })
})

const paged = computed(() => {
  const start = (page.value - 1) * pageSize
  return filtered.value.slice(start, start + pageSize)
})

watch([keyword, statusFilter], () => {
  page.value = 1
})

const totalCount = computed(() => rows.value.length)
const enabledCount = computed(() => rows.value.filter((item) => item.status === '启用').length)
const userTotal = computed(() => rows.value.reduce((sum, item) => sum + item.userCount, 0))
const deviceTotal = computed(() => rows.value.reduce((sum, item) => sum + item.deviceCount, 0))

interface TenantForm {
  name: string
  code: string
  contact: string
  phone: string
  resourceQuota: string
  status: '启用' | '停用'
}

const editOpen = ref(false)
const editingId = ref<string | null>(null)
const form = reactive<TenantForm>({
  name: '',
  code: '',
  contact: '',
  phone: '',
  resourceQuota: '地块 6 · 用户 20 · 设备 80 · 存储 200GB',
  status: '启用',
})

function resetForm() {
  form.name = ''
  form.code = ''
  form.contact = ''
  form.phone = ''
  form.resourceQuota = '地块 6 · 用户 20 · 设备 80 · 存储 200GB'
  form.status = '启用'
}

function openCreate() {
  editingId.value = null
  resetForm()
  editOpen.value = true
}

function openEdit(tenant: Tenant) {
  editingId.value = tenant.id
  form.name = tenant.name
  form.code = tenant.code
  form.contact = tenant.contact
  form.phone = tenant.phone
  form.resourceQuota = tenant.resourceQuota
  form.status = tenant.status
  editOpen.value = true
}

function saveTenant() {
  const name = form.name.trim()
  const code = form.code.trim()
  if (!name || !code) {
    toast.error('租户名称与编码不能为空')
    return
  }
  const duplicated = rows.value.some((item) => item.code === code && item.id !== editingId.value)
  if (duplicated) {
    toast.error(`租户编码 ${code} 已存在，请更换`)
    return
  }
  const payload = {
    name,
    code,
    contact: form.contact.trim() || '—',
    phone: form.phone.trim() || '—',
    resourceQuota: form.resourceQuota,
    status: form.status,
  }
  if (editingId.value) {
    const target = rows.value.find((item) => item.id === editingId.value)
    if (target) Object.assign(target, payload)
    toast.success(`租户「${name}」已更新`)
  } else {
    const nextId = `T-${String(rows.value.length + 1).padStart(2, '0')}`
    rows.value.unshift({ id: nextId, ...payload, userCount: 0, deviceCount: 0, createdAt: '2026-11-06' })
    toast.success(`租户「${name}」已创建，资源隔离配置已生效`)
  }
  editOpen.value = false
}

function toggleStatus(tenant: Tenant) {
  tenant.status = tenant.status === '启用' ? '停用' : '启用'
  toast.success(`租户「${tenant.name}」已${tenant.status}`)
}

const deleteTarget = ref<Tenant | null>(null)
const deleteOpen = computed({
  get: () => deleteTarget.value !== null,
  set: (value: boolean) => {
    if (!value) deleteTarget.value = null
  },
})

function openDelete(tenant: Tenant) {
  if (tenant.code === 'YUNLING') {
    toast.error('主园区租户不允许删除')
    return
  }
  deleteTarget.value = tenant
}

function confirmDelete() {
  const target = deleteTarget.value
  if (!target) return
  rows.value = rows.value.filter((item) => item.id !== target.id)
  toast.success(`租户「${target.name}」已删除`)
  deleteTarget.value = null
}
</script>

<template>
  <div>
    <PageHeader eyebrow="TENANT MANAGEMENT" title="租户信息管理" description="维护园区租户账号，配置资源配额与数据隔离，为多园区扩展预留能力">
      <template #actions>
        <button class="btn btn--primary" type="button" @click="openCreate">新增租户</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="租户总数" :value="totalCount" unit="个" note="本期单园区 · 预留扩展" trend="多园区规划" />
      <StatCard label="启用租户" :value="enabledCount" unit="个" note="可正常登录使用" trend="启用率稳定" />
      <StatCard label="租户用户合计" :value="userTotal" unit="个" note="各租户账号汇总" trend="按配额隔离" />
      <StatCard label="接入设备合计" :value="deviceTotal" unit="台" note="各租户设备汇总" trend="在线率 90%" accent />
    </div>

    <section class="card">
      <div class="card__body" style="padding-bottom: 0">
        <div class="toolbar">
          <div class="field">
            <span class="field__label">状态</span>
            <select v-model="statusFilter" class="select" style="width: 120px">
              <option value="">全部状态</option>
              <option value="启用">启用</option>
              <option value="停用">停用</option>
            </select>
          </div>
          <div class="field" style="flex: 1; min-width: 200px">
            <span class="field__label">关键词</span>
            <input v-model="keyword" class="input" placeholder="搜索租户名称 / 编码 / 联系人 / 手机" />
          </div>
          <button class="btn btn--sm" type="button" style="margin-top: 18px" @click="keyword = ''; statusFilter = ''">重置筛选</button>
          <div class="toolbar__spacer" />
          <span class="tag tag--brand" style="margin-top: 18px">共 {{ filtered.length }} 个租户</span>
        </div>

        <div class="table-wrap">
          <table class="data-table">
            <thead>
              <tr>
                <th>租户名称</th>
                <th>编码</th>
                <th>联系人</th>
                <th>资源配额</th>
                <th>用户 / 设备</th>
                <th>状态</th>
                <th>创建时间</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="tenant in paged" :key="tenant.id">
                <td class="cell-strong">{{ tenant.name }}</td>
                <td class="num">{{ tenant.code }}</td>
                <td>{{ tenant.contact }} <span class="cell-muted">· {{ tenant.phone }}</span></td>
                <td class="cell-muted">{{ tenant.resourceQuota }}</td>
                <td class="num">{{ tenant.userCount }} / {{ tenant.deviceCount }}</td>
                <td><StatusTag :text="tenant.status" :tone="tenant.status === '启用' ? 'ok' : 'mute'" dot /></td>
                <td class="num">{{ tenant.createdAt }}</td>
                <td>
                  <div class="table-actions">
                    <button class="link-action" type="button" @click="openEdit(tenant)">编辑</button>
                    <button class="link-action" type="button" @click="toggleStatus(tenant)">{{ tenant.status === '启用' ? '停用' : '启用' }}</button>
                    <button class="link-action link-action--danger" type="button" @click="openDelete(tenant)">删除</button>
                  </div>
                </td>
              </tr>
              <tr v-if="paged.length === 0">
                <td colspan="8">
                  <div class="empty"><span class="empty__mark">空</span>没有符合条件的租户，请调整筛选条件</div>
                </td>
              </tr>
            </tbody>
          </table>
          <Pager :total="filtered.length" :page="page" :page-size="pageSize" @update:page="page = $event" />
        </div>
      </div>
    </section>

    <AppModal v-model="editOpen" :title="editingId ? '编辑租户' : '新增租户'" size="lg">
      <div class="form-grid">
        <label class="field">
          <span class="field__label">租户名称</span>
          <input v-model="form.name" class="input" placeholder="如：璧山生态果蔬基地" />
        </label>
        <label class="field">
          <span class="field__label">租户编码</span>
          <input v-model="form.code" class="input" placeholder="如：BISHAN（大写字母）" />
        </label>
        <label class="field">
          <span class="field__label">联系人</span>
          <input v-model="form.contact" class="input" placeholder="园区负责人姓名" />
        </label>
        <label class="field">
          <span class="field__label">联系电话</span>
          <input v-model="form.phone" class="input" placeholder="用于接收系统通知" />
        </label>
        <label class="field span-2">
          <span class="field__label">资源配额</span>
          <input v-model="form.resourceQuota" class="input" placeholder="地块 / 用户 / 设备 / 存储配额" />
        </label>
        <label class="field span-2">
          <span class="field__label">租户状态</span>
          <select v-model="form.status" class="select">
            <option value="启用">启用</option>
            <option value="停用">停用</option>
          </select>
        </label>
      </div>
      <div class="notice notice--brand" style="margin-top: 14px">
        <span>租户间数据按编码隔离，创建后将为该租户初始化独立的数据空间与默认角色。</span>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="editOpen = false">取消</button>
        <button class="btn btn--primary" type="button" @click="saveTenant">保存</button>
      </template>
    </AppModal>

    <AppModal v-model="deleteOpen" title="删除租户">
      <div class="notice notice--danger">
        <span>删除后该租户及其用户将无法登录，历史数据仍会保留。此操作不可撤销。</span>
      </div>
      <div class="kv" style="margin-top: 14px">
        <div class="kv__item"><span>租户名称</span><b>{{ deleteTarget?.name }}</b></div>
        <div class="kv__item"><span>编码</span><b>{{ deleteTarget?.code }}</b></div>
        <div class="kv__item"><span>用户数</span><b>{{ deleteTarget?.userCount }}</b></div>
        <div class="kv__item"><span>设备数</span><b>{{ deleteTarget?.deviceCount }}</b></div>
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
