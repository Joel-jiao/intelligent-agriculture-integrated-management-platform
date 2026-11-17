<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { dictTypes as seedDictTypes } from '@/api/store'
import type { DictItem, DictType } from '@/data/types'

const toast = useToast()

const dictTypes = ref<DictType[]>(cloneDictTypes())

/** 本地编辑副本：字典数据来自后端 /api/v1/system/dicts */
function cloneDictTypes(): DictType[] {
  return JSON.parse(JSON.stringify(seedDictTypes)) as DictType[]
}

const activeId = ref(dictTypes.value[0]?.id ?? '')
const keyword = ref('')

const currentType = computed(() => dictTypes.value.find((item) => item.id === activeId.value) ?? dictTypes.value[0])
const filteredItems = computed(() => {
  const kw = keyword.value.trim().toLowerCase()
  const list = currentType.value?.items ?? []
  if (!kw) return list
  return list.filter((item) => item.code.toLowerCase().includes(kw) || item.name.includes(kw) || item.note.includes(kw))
})

watch(activeId, () => {
  keyword.value = ''
})

function selectType(id: string) {
  activeId.value = id
}

const itemOpen = ref(false)
const editingId = ref<string | null>(null)
const itemForm = reactive<{ code: string; name: string; sort: number; status: '启用' | '停用'; note: string }>({
  code: '',
  name: '',
  sort: 1,
  status: '启用',
  note: '',
})

function openItem(item?: DictItem) {
  editingId.value = item?.id ?? null
  itemForm.code = item?.code ?? ''
  itemForm.name = item?.name ?? ''
  itemForm.sort = item?.sort ?? (currentType.value?.items.length ?? 0) + 1
  itemForm.status = item?.status ?? '启用'
  itemForm.note = item?.note ?? ''
  itemOpen.value = true
}

function saveItem() {
  const type = currentType.value
  if (!type) return
  if (!itemForm.code.trim() || !itemForm.name.trim()) {
    toast.error('字典编码与名称不能为空')
    return
  }
  const payload = {
    code: itemForm.code.trim().toUpperCase(),
    name: itemForm.name.trim(),
    sort: itemForm.sort,
    status: itemForm.status,
    note: itemForm.note.trim() || '—',
  }
  if (editingId.value) {
    const target = type.items.find((item) => item.id === editingId.value)
    if (target) Object.assign(target, payload)
    toast.success(`字典项「${payload.name}」已更新`)
  } else {
    type.items.push({ id: `${type.code}-${type.items.length + 1}`, ...payload })
    toast.success(`字典项「${payload.name}」已新增`)
  }
  itemOpen.value = false
}

function toggleItem(item: DictItem) {
  item.status = item.status === '启用' ? '停用' : '启用'
  toast.success(`字典项「${item.name}」已${item.status}`)
}

const deleteTarget = ref<DictItem | null>(null)
const deleteOpen = computed({
  get: () => deleteTarget.value !== null,
  set: (value: boolean) => {
    if (!value) deleteTarget.value = null
  },
})

function confirmDelete() {
  const type = currentType.value
  const target = deleteTarget.value
  if (!type || !target) return
  type.items = type.items.filter((item) => item.id !== target.id)
  deleteTarget.value = null
  toast.success(`字典项「${target.name}」已删除`)
}

const typeOpen = ref(false)
const typeForm = reactive({ name: '', code: '', desc: '' })

function openType() {
  typeForm.name = ''
  typeForm.code = ''
  typeForm.desc = ''
  typeOpen.value = true
}

function createType() {
  const name = typeForm.name.trim()
  const code = typeForm.code.trim()
  if (!name || !code) {
    toast.error('字典类型名称与标识不能为空')
    return
  }
  if (dictTypes.value.some((item) => item.code === code)) {
    toast.error(`字典标识 ${code} 已存在`)
    return
  }
  const id = `DT-${String(dictTypes.value.length + 1).padStart(2, '0')}`
  dictTypes.value.push({ id, code, name, desc: typeForm.desc.trim() || '未填写说明', items: [] })
  activeId.value = id
  typeOpen.value = false
  toast.success(`字典类型「${name}」已创建，请添加字典项`)
}
</script>

<template>
  <div>
    <PageHeader eyebrow="DATA DICTIONARY" title="系统数据字典" description="统一维护枚举值与业务编码，修改后将影响筛选条件、报表与移动端展示">
      <template #actions>
        <button class="btn" type="button" @click="keyword = ''">重置搜索</button>
        <button class="btn btn--primary" type="button" @click="openType">新增字典类型</button>
      </template>
    </PageHeader>

    <div class="grid grid--sidebar">
      <section class="card">
        <div class="card__head">
          <div class="card__title">字典类型 <span class="card__sub">{{ dictTypes.length }} 类</span></div>
        </div>
        <div class="card__body type-list">
          <button
            v-for="type in dictTypes"
            :key="type.id"
            class="type-item"
            :class="{ 'type-item--active': type.id === activeId }"
            type="button"
            @click="selectType(type.id)"
          >
            <div class="type-item__top">
              <b>{{ type.name }}</b>
              <span class="tag" :class="type.id === activeId ? 'tag--brand' : ''">{{ type.items.length }} 项</span>
            </div>
            <code>{{ type.code }}</code>
            <small>{{ type.desc }}</small>
          </button>
        </div>
      </section>

      <section class="card">
        <div class="card__head">
          <div class="card__title">
            {{ currentType?.name }}
            <span class="card__sub">{{ currentType?.code }} · {{ currentType?.items.length ?? 0 }} 个字典项</span>
          </div>
          <button class="btn btn--sm btn--primary" type="button" @click="openItem()">新增字典项</button>
        </div>
        <div class="card__body">
          <div class="notice notice--brand" style="margin-bottom: 14px">
            <span>{{ currentType?.desc }}</span>
          </div>

          <div class="toolbar">
            <div class="field" style="flex: 1; min-width: 200px">
              <span class="field__label">搜索字典项</span>
              <input v-model="keyword" class="input" placeholder="按编码 / 名称 / 备注搜索" />
            </div>
            <div class="toolbar__spacer" />
            <span class="tag tag--brand" style="margin-top: 18px">启用以 {{ currentType?.items.filter((item) => item.status === '启用').length ?? 0 }} 项</span>
          </div>

          <div class="table-wrap">
            <table class="data-table">
              <thead>
                <tr>
                  <th>编码</th>
                  <th>名称</th>
                  <th>排序</th>
                  <th>状态</th>
                  <th>备注</th>
                  <th>操作</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in filteredItems" :key="item.id">
                  <td class="cell-strong num">{{ item.code }}</td>
                  <td>{{ item.name }}</td>
                  <td class="num">{{ item.sort }}</td>
                  <td><StatusTag :text="item.status" :tone="item.status === '启用' ? 'ok' : 'mute'" dot /></td>
                  <td class="cell-muted">{{ item.note }}</td>
                  <td>
                    <div class="table-actions">
                      <button class="link-action" type="button" @click="openItem(item)">编辑</button>
                      <button class="link-action" type="button" @click="toggleItem(item)">{{ item.status === '启用' ? '停用' : '启用' }}</button>
                      <button class="link-action link-action--danger" type="button" @click="deleteTarget = item">删除</button>
                    </div>
                  </td>
                </tr>
                <tr v-if="filteredItems.length === 0">
                  <td colspan="6">
                    <div class="empty"><span class="empty__mark">空</span>{{ currentType?.items.length ? '没有匹配的字典项' : '该字典类型暂无字典项' }}</div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>
    </div>

    <AppModal v-model="itemOpen" :title="editingId ? '编辑字典项' : '新增字典项'">
      <div class="form-grid">
        <label class="field">
          <span class="field__label">字典编码</span>
          <input v-model="itemForm.code" class="input" placeholder="英文大写，如 VEG" />
        </label>
        <label class="field">
          <span class="field__label">显示名称</span>
          <input v-model="itemForm.name" class="input" placeholder="如：蔬菜类" />
        </label>
        <label class="field">
          <span class="field__label">排序值</span>
          <input v-model.number="itemForm.sort" class="input" type="number" min="1" max="999" />
        </label>
        <label class="field">
          <span class="field__label">状态</span>
          <select v-model="itemForm.status" class="select">
            <option value="启用">启用</option>
            <option value="停用">停用</option>
          </select>
        </label>
        <label class="field span-2">
          <span class="field__label">备注</span>
          <textarea v-model="itemForm.note" class="textarea" placeholder="说明该枚举的适用范围" />
        </label>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="itemOpen = false">取消</button>
        <button class="btn btn--primary" type="button" @click="saveItem">保存</button>
      </template>
    </AppModal>

    <AppModal v-model="typeOpen" title="新增字典类型">
      <div class="form-grid">
        <label class="field">
          <span class="field__label">类型名称</span>
          <input v-model="typeForm.name" class="input" placeholder="如：灌溉方式" />
        </label>
        <label class="field">
          <span class="field__label">类型标识</span>
          <input v-model="typeForm.code" class="input" placeholder="如 irrigation_type" />
        </label>
        <label class="field span-2">
          <span class="field__label">类型说明</span>
          <textarea v-model="typeForm.desc" class="textarea" placeholder="说明用途与影响范围" />
        </label>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="typeOpen = false">取消</button>
        <button class="btn btn--primary" type="button" @click="createType">创建类型</button>
      </template>
    </AppModal>

    <AppModal v-model="deleteOpen" title="删除字典项">
      <div class="notice notice--danger">
        <span>删除字典项「{{ deleteTarget?.name }}」可能影响正在使用该枚举的历史数据展示，请确认无业务引用。</span>
      </div>
      <div class="kv" style="margin-top: 14px">
        <div class="kv__item"><span>字典编码</span><b>{{ deleteTarget?.code }}</b></div>
        <div class="kv__item"><span>所属类型</span><b>{{ currentType?.name }}</b></div>
        <div class="kv__item"><span>状态</span><b>{{ deleteTarget?.status }}</b></div>
        <div class="kv__item"><span>备注</span><b>{{ deleteTarget?.note }}</b></div>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="deleteTarget = null">取消</button>
        <button class="btn btn--danger" type="button" @click="confirmDelete">确认删除</button>
      </template>
    </AppModal>
  </div>
</template>

<style scoped>
.type-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.type-item {
  display: flex;
  flex-direction: column;
  gap: 3px;
  padding: 11px 12px;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: var(--surface-2);
  text-align: left;
  transition: 0.18s;
}

.type-item:hover {
  border-color: var(--brand);
}

.type-item--active {
  border-color: var(--brand);
  background: var(--brand-softer);
  box-shadow: inset 3px 0 0 var(--brand);
}

.type-item__top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
}

.type-item__top b {
  font-size: 13px;
  color: var(--ink);
}

.type-item code {
  font-size: 10.5px;
  color: var(--faint);
  font-family: var(--font-num);
}

.type-item small {
  font-size: 11px;
  color: var(--muted);
  line-height: 1.5;
}

.link-action--danger {
  color: var(--danger);
}
</style>
