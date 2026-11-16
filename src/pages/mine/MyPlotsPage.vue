<script setup lang="ts">
import { computed, ref } from 'vue'
import { useRouter } from 'vue-router'
import GisMap from '@/components/ui/GisMap.vue'
import { devices, farmerPlots } from '@/data/mock'
import type { AuditStatus, FarmerPlot, Plot } from '@/data/types'

const router = useRouter()

const selectedId = ref(farmerPlots[0]?.id ?? '')
const selected = computed<FarmerPlot | undefined>(() => farmerPlots.find((item) => item.id === selectedId.value))

const previewPlot = computed<Plot | undefined>(() => {
  const plot = selected.value
  if (!plot) return undefined
  return {
    id: plot.id,
    code: plot.id,
    name: plot.name,
    crop: plot.crop,
    variety: plot.variety,
    area: plot.area,
    greenhouse: plot.greenhouse,
    stage: '—',
    soil: '—',
    manager: '本人',
    plantedAt: plot.plantedAt,
    expectedHarvest: plot.expectedHarvest,
    status: plot.auditStatus === '已通过' ? '正常' : '预警',
    color: '#4fae74',
    polygon: plot.polygon,
  }
})

const plotDevices = computed(() => devices.filter((device) => device.plotId === selectedId.value))

function auditTone(status: AuditStatus): 'ok' | 'warn' | 'danger' {
  if (status === '已通过') return 'ok'
  if (status === '待审核') return 'warn'
  return 'danger'
}

function submitPlot() {
  router.push('/app/plots/submit')
}

function resubmitPlot(id: string) {
  router.push(`/app/plots/submit/${id}`)
}
</script>

<template>
  <div class="mobile-page">
    <header class="page-head">
      <div>
        <h2>我的地块</h2>
        <p>归属本人地块档案与审核进度</p>
      </div>
      <span class="tag tag--brand">{{ farmerPlots.length }} 个地块</span>
    </header>

    <div class="mobile-tabs plots-tabs">
      <button
        v-for="plot in farmerPlots"
        :key="plot.id"
        class="mobile-tab"
        :class="{ 'is-active': plot.id === selectedId }"
        type="button"
        @click="selectedId = plot.id"
      >
        {{ plot.name }}
      </button>
      <button class="mobile-tab" type="button" @click="submitPlot">+ 录入</button>
    </div>

    <section v-if="selected" class="mobile-section">
      <div class="mobile-card plot-map-card">
        <div class="plot-map-head">
          <span>{{ selected.name }}</span>
          <span class="tag" :class="`tag--${auditTone(selected.auditStatus)}`">{{ selected.auditStatus }}</span>
        </div>
        <GisMap v-if="previewPlot" :plots="[previewPlot]" :devices="[]" :show-devices="false" :height="180" />
      </div>

      <div v-if="selected.rejectReason" class="notice notice--danger" style="margin-top: 10px">
        <span>驳回意见：{{ selected.rejectReason }}</span>
      </div>

      <div class="mobile-card" style="margin-top: 10px">
        <div class="mobile-section__head">
          <h3>档案信息</h3>
        </div>
        <div class="detail-row"><span>种植作物</span><b>{{ selected.crop }} · {{ selected.variety }}</b></div>
        <div class="detail-row"><span>地块面积</span><b class="font-num">{{ selected.area }} 亩</b></div>
        <div class="detail-row"><span>温室类型</span><b>{{ selected.greenhouse }}</b></div>
        <div class="detail-row"><span>种植时间</span><b class="font-num">{{ selected.plantedAt }}</b></div>
        <div class="detail-row"><span>预计采收</span><b class="font-num">{{ selected.expectedHarvest }}</b></div>
      </div>

      <div class="mobile-card" style="margin-top: 10px">
        <div class="mobile-section__head">
          <h3>设备与环境摘要</h3>
        </div>
        <div class="env-summary">
          <div class="env-summary__stat">
            <span>空气温度</span>
            <b class="font-num">{{ selected.envTemp }}℃</b>
          </div>
          <div class="env-summary__stat">
            <span>空气湿度</span>
            <b class="font-num">{{ selected.envHumidity }}%</b>
          </div>
          <div class="env-summary__stat">
            <span>绑定设备</span>
            <b class="font-num">{{ plotDevices.length }} 台</b>
          </div>
        </div>
        <div v-if="plotDevices.length" class="device-chips">
          <span v-for="device in plotDevices.slice(0, 6)" :key="device.id" class="device-chip">
            <i class="dot" :class="device.status === '在线' ? 'dot--ok' : 'dot--danger'" />{{ device.name }}
          </span>
        </div>
        <div v-else class="empty" style="padding: 12px 0"><span class="empty__mark">设</span>该地块尚未绑定设备</div>
      </div>

      <div class="mobile-section__actions">
        <button v-if="selected.auditStatus === '已驳回'" class="mobile-btn mobile-btn--primary mobile-btn--full" type="button" @click="resubmitPlot(selected.id)">
          按驳回意见修改并重新提交
        </button>
        <button v-else class="mobile-btn mobile-btn--ghost mobile-btn--full" type="button" @click="submitPlot">
          录入新地块档案
        </button>
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
  margin: 6px 0 12px;
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

.plots-tabs {
  margin-bottom: 12px;
  overflow-x: auto;
}

.plot-map-card {
  padding: 12px;
}

.plot-map-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 10px;
  font-size: 13px;
  font-weight: 650;
  color: var(--ink);
}

.detail-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 8px 0;
  border-bottom: 1px dashed var(--line);
  font-size: 12px;
  color: var(--muted);
}

.detail-row:last-child {
  border-bottom: 0;
}

.detail-row b {
  font-weight: 600;
  color: var(--ink-2);
}

.env-summary {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 8px;
}

.env-summary__stat {
  display: flex;
  flex-direction: column;
  gap: 2px;
  padding: 8px;
  border-radius: 8px;
  background: var(--brand-soft);
}

.env-summary__stat span {
  font-size: 10px;
  color: var(--muted);
}

.env-summary__stat b {
  font-size: 14px;
  color: var(--brand-dark);
}

.device-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-top: 10px;
}

.device-chip {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 3px 8px;
  border: 1px solid var(--line);
  border-radius: 6px;
  font-size: 10px;
  color: var(--muted);
}

.mobile-section__actions {
  margin-top: 14px;
}
</style>
