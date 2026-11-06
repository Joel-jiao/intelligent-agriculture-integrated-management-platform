<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { roles } from '@/data/mock'
import type { Role } from '@/data/types'

const toast = useToast()

interface PermissionItem {
  key: string
  label: string
}

interface PermissionModule {
  title: string
  items: PermissionItem[]
}

const modules: PermissionModule[] = [
  {
    title: '看板与总览',
    items: [
      { key: 'dashboard', label: '综合数据看板' },
      { key: 'workbench', label: '运维工作台' },
      { key: 'sup-overview', label: '监管数据总览' },
    ],
  },
  {
    title: '物联网感知',
    items: [
      { key: 'iot', label: '环境与设备监测' },
      { key: 'device-access', label: '设备接入管理' },
      { key: 'app-env', label: '移动端环境查看' },
      { key: 'app-device', label: '移动端设备控制' },
    ],
  },
  {
    title: '远程控制',
    items: [
      { key: 'control', label: '设备远程控制' },
      { key: 'linkage', label: '自动联动策略' },
    ],
  },
  {
    title: '生产农事',
    items: [
      { key: 'farm', label: '农事与地块管理' },
      { key: 'app-tasks', label: '移动端任务执行' },
    ],
  },
  {
    title: '质量溯源',
    items: [
      { key: 'trace', label: '溯源批次与赋码' },
      { key: 'app-trace', label: '移动端扫码录入' },
      { key: 'h5-trace', label: '公开溯源查询' },
      { key: 'sup-trace', label: '辖区溯源台账' },
    ],
  },
  {
    title: 'GIS 地图',
    items: [{ key: 'gis', label: 'GIS 综合地图' }],
  },
  {
    title: '告警中心',
    items: [
      { key: 'alarm', label: '告警信息处理' },
      { key: 'sup-warning', label: '监管预警管理' },
    ],
  },
  {
    title: '报表中心',
    items: [
      { key: 'report', label: '综合报表导出' },
      { key: 'sup-report', label: '监管报表导出' },
    ],
  },
  {
    title: '系统运维',
    items: [
      { key: 'users', label: '用户管理' },
      { key: 'roles', label: '角色权限配置' },
      { key: 'dict', label: '数据字典' },
      { key: 'logs', label: '日志审计' },
      { key: 'backup', label: '备份恢复' },
      { key: 'openapi', label: '第三方接口' },
      { key: 'files', label: '文件存储' },
    ],
  },
]

const allKeys = modules.flatMap((module) => module.items.map((item) => item.key))
const roleList = ref<Role[]>(roles.map((item) => ({ ...item, permissions: [...item.permissions] })))
const activeId = ref(roleList.value[0]?.id ?? '')

const currentRole = computed(() => roleList.value.find((item) => item.id === activeId.value) ?? roleList.value[0])

function isChecked(key: string): boolean {
  return (currentRole.value?.permissions ?? []).includes(key)
}

function togglePermission(key: string, checked: boolean) {
  const role = currentRole.value
  if (!role) return
  if (checked) {
    if (!role.permissions.includes(key)) role.permissions.push(key)
  } else {
    role.permissions = role.permissions.filter((item) => item !== key)
  }
}

function onToggle(key: string, event: Event) {
  const target = event.target as HTMLInputElement
  togglePermission(key, target.checked)
}

function selectAll() {
  const role = currentRole.value
  if (!role) return
  role.permissions = [...allKeys]
  toast.info('已勾选全部权限，请记得保存')
}

function clearAll() {
  const role = currentRole.value
  if (!role) return
  role.permissions = []
  toast.warn('已清空当前角色权限，请记得保存')
}

function savePermissions() {
  const role = currentRole.value
  if (!role) return
  toast.success(`角色「${role.name}」的 ${role.permissions.length} 项权限已保存`)
}

function saveDescription() {
  const role = currentRole.value
  if (!role) return
  toast.success(`角色「${role.name}」的权限说明已更新`)
}

const addOpen = ref(false)
const addForm = reactive({ name: '', code: '', description: '' })

function openAdd() {
  addForm.name = ''
  addForm.code = ''
  addForm.description = ''
  addOpen.value = true
}

function createRole() {
  const name = addForm.name.trim()
  const code = addForm.code.trim().toUpperCase()
  if (!name || !code) {
    toast.error('角色名称与角色编码不能为空')
    return
  }
  if (roleList.value.some((item) => item.code === code)) {
    toast.error(`角色编码 ${code} 已存在`)
    return
  }
  const id = `R-${String(roleList.value.length + 1).padStart(2, '0')}`
  const role: Role = {
    id,
    name,
    code,
    members: 0,
    description: addForm.description.trim() || '未填写角色说明',
    permissions: [],
  }
  roleList.value.push(role)
  activeId.value = id
  addOpen.value = false
  toast.success(`角色「${name}」已创建，请为其分配权限`)
}

const deleteTarget = ref<Role | null>(null)
const deleteOpen = computed({
  get: () => deleteTarget.value !== null,
  set: (value: boolean) => {
    if (!value) deleteTarget.value = null
  },
})

function openDelete(role: Role) {
  if (role.members > 0) {
    toast.error(`角色「${role.name}」下仍有 ${role.members} 名成员，请先调整成员角色`)
    return
  }
  deleteTarget.value = role
}

function openDeleteCurrent() {
  const role = currentRole.value
  if (role) openDelete(role)
}

function confirmDelete() {
  const target = deleteTarget.value
  if (!target) return
  roleList.value = roleList.value.filter((item) => item.id !== target.id)
  activeId.value = roleList.value[0]?.id ?? ''
  deleteTarget.value = null
  toast.success(`角色「${target.name}」已删除`)
}
</script>

<template>
  <div>
    <PageHeader eyebrow="RBAC" title="RBAC 角色权限配置" description="按角色分配功能权限，遵循最小权限原则，变更将实时写入审计日志">
      <template #actions>
        <button class="btn" type="button" @click="selectAll">全选权限</button>
        <button class="btn btn--primary" type="button" @click="openAdd">新增角色</button>
      </template>
    </PageHeader>

    <div class="grid grid--sidebar">
      <section class="card role-card">
        <div class="card__head">
          <div class="card__title">角色列表 <span class="card__sub">{{ roleList.length }} 个</span></div>
        </div>
        <div class="card__body role-list">
          <button
            v-for="role in roleList"
            :key="role.id"
            class="role-item"
            :class="{ 'role-item--active': role.id === activeId }"
            type="button"
            @click="activeId = role.id"
          >
            <div class="role-item__top">
              <b>{{ role.name }}</b>
              <span class="tag" :class="role.id === activeId ? 'tag--brand' : ''">{{ role.code }}</span>
            </div>
            <div class="role-item__meta">
              <span>{{ role.members }} 名成员</span>
              <span>{{ role.permissions.length }} 项权限</span>
            </div>
          </button>
          <div class="notice notice--brand" style="margin-top: 12px">
            <span>权限变更保存后对已登录用户即时生效，建议在业务低峰期调整。</span>
          </div>
        </div>
      </section>

      <section v-if="currentRole" class="card">
        <div class="card__head">
          <div class="card__title">
            {{ currentRole.name }}
            <span class="card__sub">{{ currentRole.code }} · {{ currentRole.members }} 名成员</span>
          </div>
          <div class="row">
            <button class="btn btn--sm" type="button" @click="clearAll">清空</button>
            <button class="btn btn--sm btn--primary" type="button" @click="savePermissions">保存权限</button>
          </div>
        </div>
        <div class="card__body">
          <div class="toolbar" style="margin-bottom: 16px">
            <span class="tag tag--brand">已选 {{ currentRole.permissions.length }} / {{ allKeys.length }} 项</span>
            <span class="cell-muted" style="font-size: 11.5px">勾选模块下的功能项即可授予对应权限</span>
            <div class="toolbar__spacer" />
            <button class="link-action" type="button" @click="selectAll">全选</button>
            <button class="link-action" type="button" @click="clearAll">清空</button>
            <button class="link-action" style="color: var(--danger)" type="button" @click="openDeleteCurrent">删除角色</button>
          </div>

          <div class="perm-grid">
            <div v-for="module in modules" :key="module.title" class="perm-module">
              <div class="perm-module__head">
                <b>{{ module.title }}</b>
                <span>{{ module.items.filter((item) => isChecked(item.key)).length }}/{{ module.items.length }}</span>
              </div>
              <label v-for="item in module.items" :key="item.key" class="perm-item">
                <input type="checkbox" :checked="isChecked(item.key)" @change="onToggle(item.key, $event)" />
                <span>{{ item.label }}</span>
                <small>{{ item.key }}</small>
              </label>
            </div>
          </div>

          <div class="field" style="margin-top: 18px">
            <span class="field__label">角色说明</span>
            <textarea v-model="currentRole.description" class="textarea" placeholder="描述该角色的职责与适用场景" />
          </div>
          <div class="form-foot">
            <button class="btn" type="button" @click="saveDescription">保存说明</button>
            <button class="btn btn--primary" type="button" @click="savePermissions">保存全部变更</button>
          </div>
        </div>
      </section>
    </div>

    <AppModal v-model="addOpen" title="新增角色">
      <div class="form-grid">
        <label class="field">
          <span class="field__label">角色名称</span>
          <input v-model="addForm.name" class="input" placeholder="如：设备维护员" />
        </label>
        <label class="field">
          <span class="field__label">角色编码</span>
          <input v-model="addForm.code" class="input" placeholder="大写英文，如 MAINTAINER" />
        </label>
        <label class="field span-2">
          <span class="field__label">角色说明</span>
          <textarea v-model="addForm.description" class="textarea" placeholder="描述职责范围（可选）" />
        </label>
      </div>
      <div class="notice notice--brand" style="margin-top: 14px">
        <span>新角色默认不含任何权限，创建后请在权限矩阵中勾选并保存。</span>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="addOpen = false">取消</button>
        <button class="btn btn--primary" type="button" @click="createRole">创建角色</button>
      </template>
    </AppModal>

    <AppModal v-model="deleteOpen" title="删除角色">
      <div class="notice notice--danger">
        <span>角色「{{ deleteTarget?.name }}」删除后不可恢复，权限配置将一并移除。</span>
      </div>
      <div class="kv" style="margin-top: 14px">
        <div class="kv__item"><span>角色编码</span><b>{{ deleteTarget?.code }}</b></div>
        <div class="kv__item"><span>成员数</span><b>{{ deleteTarget?.members }} 人</b></div>
        <div class="kv__item"><span>权限项</span><b>{{ deleteTarget?.permissions.length }} 项</b></div>
        <div class="kv__item"><span>角色说明</span><b>{{ deleteTarget?.description }}</b></div>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="deleteTarget = null">取消</button>
        <button class="btn btn--danger" type="button" @click="confirmDelete">确认删除</button>
      </template>
    </AppModal>
  </div>
</template>

<style scoped>
.role-card {
  align-self: start;
}

.role-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.role-item {
  padding: 11px 12px;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: var(--surface-2);
  text-align: left;
  transition: 0.18s;
}

.role-item:hover {
  border-color: var(--brand);
}

.role-item--active {
  border-color: var(--brand);
  background: var(--brand-softer);
  box-shadow: inset 3px 0 0 var(--brand);
}

.role-item__top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.role-item__top b {
  font-size: 13px;
  color: var(--ink);
}

.role-item__meta {
  display: flex;
  gap: 10px;
  margin-top: 4px;
  font-size: 11px;
  color: var(--muted);
}

.perm-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 12px;
}

.perm-module {
  padding: 12px 13px;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: var(--surface-2);
}

.perm-module__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 8px;
  font-size: 12.5px;
  color: var(--ink);
}

.perm-module__head span {
  font-size: 11px;
  color: var(--faint);
  font-family: var(--font-num);
}

.perm-item {
  display: flex;
  align-items: center;
  gap: 7px;
  padding: 3px 0;
  font-size: 12px;
  color: var(--ink-2);
  cursor: pointer;
}

.perm-item input {
  accent-color: var(--brand);
}

.perm-item small {
  margin-left: auto;
  font-size: 10px;
  color: var(--faint);
  font-family: var(--font-num);
}

@media (max-width: 900px) {
  .perm-grid {
    grid-template-columns: 1fr;
  }
}
</style>
