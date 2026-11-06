<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'

const toast = useToast()

interface DictItem {
  id: string
  code: string
  name: string
  sort: number
  status: '启用' | '停用'
  note: string
}

interface DictType {
  id: string
  code: string
  name: string
  desc: string
  items: DictItem[]
}

const dictTypes = ref<DictType[]>([
  {
    id: 'DT-01',
    code: 'crop_type',
    name: '作物分类',
    desc: '用于农事档案与报表的作物大类划分',
    items: [
      { id: 'CT-01', code: 'VEG', name: '蔬菜类', sort: 1, status: '启用', note: '茄果、瓜类、叶菜等' },
      { id: 'CT-02', code: 'FRUIT', name: '水果类', sort: 2, status: '启用', note: '草莓、柑橘等' },
      { id: 'CT-03', code: 'GRAIN', name: '粮油类', sort: 3, status: '启用', note: '水稻、玉米、油菜' },
      { id: 'CT-04', code: 'LEAF', name: '叶菜类', sort: 4, status: '启用', note: '生菜、菠菜、小白菜' },
      { id: 'CT-05', code: 'OTHER', name: '其他作物', sort: 5, status: '停用', note: '暂未启用' },
    ],
  },
  {
    id: 'DT-02',
    code: 'device_type',
    name: '设备类型',
    desc: '设备接入与远程控制的功能分类',
    items: [
      { id: 'DT2-01', code: 'PUMP', name: '水泵', sort: 1, status: '启用', note: '灌溉与排水' },
      { id: 'DT2-02', code: 'FAN', name: '风机', sort: 2, status: '启用', note: '环流与加温' },
      { id: 'DT2-03', code: 'CURTAIN', name: '卷帘', sort: 3, status: '启用', note: '内外遮阳' },
      { id: 'DT2-04', code: 'LIGHT', name: '补光灯', sort: 4, status: '启用', note: '育苗补光' },
      { id: 'DT2-05', code: 'VALVE', name: '电磁阀', sort: 5, status: '启用', note: '滴灌分区控制' },
      { id: 'DT2-06', code: 'SENSOR', name: '传感器', sort: 6, status: '启用', note: '环境与水质采集' },
      { id: 'DT2-07', code: 'GATEWAY', name: '网关', sort: 7, status: '启用', note: '边缘接入节点' },
    ],
  },
  {
    id: 'DT-03',
    code: 'alarm_level',
    name: '告警级别',
    desc: '告警分级决定通知渠道与响应时限',
    items: [
      { id: 'DT3-01', code: 'URGENT', name: '紧急', sort: 1, status: '启用', note: '短信 + 电话，10 分钟内响应' },
      { id: 'DT3-02', code: 'IMPORTANT', name: '重要', sort: 2, status: '启用', note: '站内 + 短信，30 分钟内响应' },
      { id: 'DT3-03', code: 'NORMAL', name: '一般', sort: 3, status: '启用', note: '站内通知，2 小时内响应' },
      { id: 'DT3-04', code: 'INFO', name: '提示', sort: 4, status: '停用', note: '仅记录，不推送' },
    ],
  },
  {
    id: 'DT-04',
    code: 'product_grade',
    name: '产品等级',
    desc: '采收分级与溯源码赋码依据',
    items: [
      { id: 'DT4-01', code: 'SPECIAL', name: '特级', sort: 1, status: '启用', note: '外观与规格均优' },
      { id: 'DT4-02', code: 'FIRST', name: '一级', sort: 2, status: '启用', note: '符合主销标准' },
      { id: 'DT4-03', code: 'SECOND', name: '二级', sort: 3, status: '启用', note: '加工或团购渠道' },
      { id: 'DT4-04', code: 'REJECT', name: '等外', sort: 4, status: '启用', note: '不进入溯源销售' },
    ],
  },
  {
    id: 'DT-05',
    code: 'measure_unit',
    name: '计量单位',
    desc: '农资、采收与报表统一单位',
    items: [
      { id: 'DT5-01', code: 'KG', name: '千克', sort: 1, status: '启用', note: 'kg' },
      { id: 'DT5-02', code: 'TON', name: '吨', sort: 2, status: '启用', note: 't' },
      { id: 'DT5-03', code: 'L', name: '升', sort: 3, status: '启用', note: 'L' },
      { id: 'DT5-04', code: 'M2', name: '平方米', sort: 4, status: '启用', note: 'm²' },
      { id: 'DT5-05', code: 'M3', name: '立方米', sort: 5, status: '启用', note: 'm³' },
    ],
  },
  {
    id: 'DT-06',
    code: 'work_status',
    name: '工单状态',
    desc: '农事工单流转状态定义',
    items: [
      { id: 'DT6-01', code: 'PENDING', name: '待接单', sort: 1, status: '启用', note: '农户尚未接单' },
      { id: 'DT6-02', code: 'DOING', name: '进行中', sort: 2, status: '启用', note: '作业执行中' },
      { id: 'DT6-03', code: 'CHECKING', name: '待验收', sort: 3, status: '启用', note: '等待管理员验收' },
      { id: 'DT6-04', code: 'DONE', name: '已完成', sort: 4, status: '启用', note: '验收通过归档' },
    ],
  },
])

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
