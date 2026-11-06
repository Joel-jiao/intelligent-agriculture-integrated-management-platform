<script setup lang="ts">
import { computed, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatCard from '@/components/ui/StatCard.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import AppModal from '@/components/ui/AppModal.vue'
import { useToast } from '@/composables/useToast'
import { materials as seedMaterials } from '@/data/mock'
import type { Material } from '@/data/types'
import { buildCsv, downloadText, formatNumber, nowDateTime, pad } from '@/utils/format'

const toast = useToast()

const materialList = ref<Material[]>(seedMaterials.map((item) => ({ ...item })))

const keyword = ref('')
const categoryFilter = ref('全部')
const lowOnly = ref(false)

const categories: Array<Material['category']> = ['种子', '化肥', '农药', '农膜', '工具']
const monthIn = ref(9)
const monthOut = ref(14)

const filteredMaterials = computed(() =>
  materialList.value.filter((item) => {
    if (categoryFilter.value !== '全部' && item.category !== categoryFilter.value) return false
    if (lowOnly.value && item.stock >= item.safeStock) return false
    if (!keyword.value.trim()) return true
    const key = keyword.value.trim()
    return item.name.includes(key) || item.supplier.includes(key) || item.batchNo.includes(key)
  }),
)

const lowStockCount = computed(() => materialList.value.filter((item) => item.stock < item.safeStock).length)
const categoryCount = computed(() => Array.from(new Set(materialList.value.map((item) => item.category))).length)

function isLow(item: Material): boolean {
  return item.stock < item.safeStock
}

function resetFilters() {
  keyword.value = ''
  categoryFilter.value = '全部'
  lowOnly.value = false
}

const stockOpen = ref(false)
const stockTarget = ref<Material | null>(null)
const stockForm = ref({
  type: '入库',
  amount: '',
  note: '',
})

function openStock(item: Material, type: '入库' | '出库') {
  stockTarget.value = item
  stockForm.value = { type, amount: '', note: '' }
  stockOpen.value = true
}

function confirmStock() {
  const target = stockTarget.value
  if (!target) return
  const amount = Number(stockForm.value.amount)
  if (Number.isNaN(amount) || amount <= 0) {
    toast.warn('请输入大于 0 的数量')
    return
  }
  if (stockForm.value.type === '出库' && amount > target.stock) {
    toast.warn(`出库数量超过当前库存（${target.stock} ${target.unit}）`)
    return
  }
  const before = target.stock
  const after = stockForm.value.type === '入库' ? before + amount : before - amount
  const index = materialList.value.findIndex((item) => item.id === target.id)
  const current = materialList.value[index]
  if (current) {
    current.stock = after
    current.updatedAt = nowDateTime()
  }
  if (stockForm.value.type === '入库') monthIn.value += 1
  else monthOut.value += 1
  stockOpen.value = false
  toast.success(`${target.name} ${stockForm.value.type} ${formatNumber(amount)} ${target.unit}，库存 ${before} → ${after}`)
}

const createOpen = ref(false)
const createForm = ref({
  name: '',
  category: '种子',
  unit: '袋',
  stock: '',
  safeStock: '',
  supplier: '',
  batchNo: '',
})

function openCreate() {
  createForm.value = {
    name: '',
    category: '种子',
    unit: '袋',
    stock: '',
    safeStock: '',
    supplier: '',
    batchNo: '',
  }
  createOpen.value = true
}

function nextMaterialId(): string {
  const max = materialList.value.reduce((acc, item) => {
    const value = Number(item.id.replace('MAT-', ''))
    return Number.isNaN(value) ? acc : Math.max(acc, value)
  }, 0)
  return `MAT-${pad(max + 1)}`
}

function submitCreate() {
  const stock = Number(createForm.value.stock)
  const safeStock = Number(createForm.value.safeStock)
  if (!createForm.value.name.trim()) {
    toast.warn('请填写农资名称')
    return
  }
  if (Number.isNaN(stock) || stock < 0) {
    toast.warn('初始库存需为不小于 0 的数字')
    return
  }
  if (Number.isNaN(safeStock) || safeStock < 0) {
    toast.warn('安全库存需为不小于 0 的数字')
    return
  }
  if (!createForm.value.supplier.trim()) {
    toast.warn('请填写供应商名称')
    return
  }
  const created: Material = {
    id: nextMaterialId(),
    name: createForm.value.name.trim(),
    category: createForm.value.category as Material['category'],
    unit: createForm.value.unit.trim() || '件',
    stock,
    safeStock,
    supplier: createForm.value.supplier.trim(),
    batchNo: createForm.value.batchNo.trim() || `NEW${todayBatch()}`,
    updatedAt: nowDateTime(),
  }
  materialList.value.push(created)
  createOpen.value = false
  toast.success(`农资「${created.name}」已入库建档，编号 ${created.id}`)
}

function todayBatch(): string {
  return nowDateTime().slice(0, 10).replace(/-/g, '')
}

function exportMaterials() {
  const rows = filteredMaterials.value.map((item) => [
    item.id,
    item.name,
    item.category,
    item.unit,
    item.stock,
    item.safeStock,
    item.supplier,
    item.batchNo,
    item.updatedAt,
    isLow(item) ? '库存不足' : '库存充足',
  ])
  downloadText(
    '农资库存_20261106.csv',
    buildCsv(['编号', '名称', '类别', '单位', '库存', '安全库存', '供应商', '批次号', '更新时间', '状态'], rows),
  )
  toast.success(`已导出 ${rows.length} 条农资库存记录`)
}
</script>

<template>
  <div>
    <PageHeader eyebrow="FARM MATERIAL" title="农资库存管理" description="种子、化肥、农药与工具库存台账 · 低于安全库存自动预警">
      <template #actions>
        <button class="btn" type="button" @click="exportMaterials">导出库存</button>
        <button class="btn btn--primary" type="button" @click="openCreate">新增农资</button>
      </template>
    </PageHeader>

    <div class="stat-grid">
      <StatCard label="农资品类" :value="materialList.length" unit="种" icon="资" :note="`覆盖 ${categoryCount} 个类别 · 共 ${materialList.length} 条档案`" trend="档案完整率 100%" />
      <StatCard label="库存不足" :value="lowStockCount" unit="种" icon="警" note="低于安全库存需补货" trend="需及时补货" :trend-up="false" accent />
      <StatCard label="本月入库" :value="monthIn" unit="笔" icon="入" note="含本次操作实时累加" trend="较上月 +18%" />
      <StatCard label="本月出库" :value="monthOut" unit="笔" icon="出" note="按工单领用登记" trend="较上月 +6%" />
    </div>

    <section class="card">
      <div class="card__head">
        <div class="card__title">库存台账 <span class="card__sub">共 {{ filteredMaterials.length }} 条记录</span></div>
        <span v-if="lowStockCount" class="tag tag--danger">库存不足 {{ lowStockCount }} 种</span>
      </div>
      <div class="card__body">
        <div class="toolbar">
          <label class="field" style="flex: 1; min-width: 200px">
            <span class="field__label">关键词</span>
            <input v-model="keyword" class="input" type="text" placeholder="农资名称 / 供应商 / 批次号" />
          </label>
          <label class="field" style="width: 140px">
            <span class="field__label">类别</span>
            <select v-model="categoryFilter" class="select">
              <option value="全部">全部类别</option>
              <option v-for="item in categories" :key="item" :value="item">{{ item }}</option>
            </select>
          </label>
          <label class="switch" style="align-self: flex-end; padding-bottom: 9px">
            <input v-model="lowOnly" type="checkbox" />
            <span class="switch__track" />
            仅看库存不足
          </label>
          <div class="toolbar__spacer" />
          <button class="link-action" type="button" @click="resetFilters">重置筛选</button>
        </div>

        <div class="table-wrap">
          <table class="data-table">
            <thead>
              <tr>
                <th>名称</th>
                <th>类别</th>
                <th>单位</th>
                <th>库存</th>
                <th>安全库存</th>
                <th>供应商</th>
                <th>批次号</th>
                <th>更新时间</th>
                <th>状态</th>
                <th>操作</th>
              </tr>
            </thead>
            <tbody>
              <tr v-if="filteredMaterials.length === 0">
                <td colspan="10">
                  <div class="empty">
                    <span class="empty__mark">空</span>
                    当前筛选条件下没有农资记录
                  </div>
                </td>
              </tr>
              <tr v-for="item in filteredMaterials" :key="item.id">
                <td>
                  <div class="cell-strong">{{ item.name }}</div>
                  <div class="cell-sub">{{ item.id }}</div>
                </td>
                <td><span class="tag tag--brand">{{ item.category }}</span></td>
                <td>{{ item.unit }}</td>
                <td class="num" :class="{ 'stock-low': isLow(item) }">{{ formatNumber(item.stock) }}</td>
                <td class="num cell-muted">{{ formatNumber(item.safeStock) }}</td>
                <td>{{ item.supplier }}</td>
                <td class="num">{{ item.batchNo }}</td>
                <td class="num cell-muted">{{ item.updatedAt }}</td>
                <td>
                  <StatusTag :text="isLow(item) ? '库存不足' : '库存充足'" :tone="isLow(item) ? 'danger' : 'ok'" dot />
                </td>
                <td>
                  <div class="table-actions">
                    <button class="btn btn--sm" type="button" @click="openStock(item, '入库')">入库</button>
                    <button class="btn btn--sm" type="button" @click="openStock(item, '出库')">出库</button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
    </section>

    <AppModal v-model="stockOpen" :title="`${stockForm.type}登记`">
      <div v-if="stockTarget" class="notice" style="margin-bottom: 14px">
        {{ stockTarget.name }} · 当前库存 {{ formatNumber(stockTarget.stock) }} {{ stockTarget.unit }} · 安全库存 {{ formatNumber(stockTarget.safeStock) }} {{ stockTarget.unit }}
      </div>
      <div class="form-grid">
        <label class="field">
          <span class="field__label">操作类型</span>
          <select v-model="stockForm.type" class="select">
            <option value="入库">入库</option>
            <option value="出库">出库</option>
          </select>
        </label>
        <label class="field">
          <span class="field__label">数量{{ stockTarget ? `（${stockTarget.unit}）` : '' }}</span>
          <input v-model="stockForm.amount" class="input" type="number" min="0" step="1" placeholder="请输入数量" />
        </label>
        <label class="field span-2">
          <span class="field__label">备注</span>
          <textarea v-model="stockForm.note" class="textarea" placeholder="如：供应商送货 / 工单领用"></textarea>
        </label>
      </div>
      <template #footer>
        <button class="btn" type="button" @click="stockOpen = false">取消</button>
        <button class="btn btn--primary" type="button" @click="confirmStock">确认{{ stockForm.type }}</button>
      </template>
    </AppModal>

    <AppModal v-model="createOpen" title="新增农资" size="lg">
      <div class="form-grid">
        <label class="field">
          <span class="field__label">农资名称</span>
          <input v-model="createForm.name" class="input" type="text" placeholder="如：水溶肥 20-20-20" />
        </label>
        <label class="field">
          <span class="field__label">类别</span>
          <select v-model="createForm.category" class="select">
            <option v-for="item in categories" :key="item" :value="item">{{ item }}</option>
          </select>
        </label>
        <label class="field">
          <span class="field__label">计量单位</span>
          <input v-model="createForm.unit" class="input" type="text" placeholder="如：袋 / kg / 瓶" />
        </label>
        <label class="field">
          <span class="field__label">初始库存</span>
          <input v-model="createForm.stock" class="input" type="number" min="0" placeholder="0" />
        </label>
        <label class="field">
          <span class="field__label">安全库存</span>
          <input v-model="createForm.safeStock" class="input" type="number" min="0" placeholder="0" />
        </label>
        <label class="field">
          <span class="field__label">供应商</span>
          <input v-model="createForm.supplier" class="input" type="text" placeholder="如：中化化肥西南分公司" />
        </label>
        <label class="field">
          <span class="field__label">批次号</span>
          <input v-model="createForm.batchNo" class="input" type="text" placeholder="留空自动生成" />
        </label>
      </div>
      <div class="notice" style="margin-top: 14px">库存低于安全库存时，列表将自动标记为「库存不足」并提示补货。</div>
      <template #footer>
        <button class="btn" type="button" @click="createOpen = false">取消</button>
        <button class="btn btn--primary" type="button" @click="submitCreate">保存建档</button>
      </template>
    </AppModal>
  </div>
</template>

<style scoped>
.cell-sub {
  margin-top: 1px;
  font-size: 10.5px;
  color: var(--faint);
  font-family: var(--font-num);
}

.stock-low {
  color: var(--danger);
  font-weight: 700;
}
</style>
