<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import QrCode from '@/components/ui/QrCode.vue'
import { batches, findPlot, inspections, park, plotName, traceDetail, traceTimeline } from '@/data/mock'
import { formatNumber } from '@/utils/format'

interface TraceDisplay {
  batchNo: string
  crop: string
  variety: string
  origin: string
  grade: string
  weightText: string
  harvestedAt: string
  plantedAt: string
  farmer: string
  plotName: string
  plotCode: string
  scans: number
  qrCount: number
  status: string
  certified: boolean
}

const route = useRoute()

const code = computed(() => {
  const raw = route.params.code
  const value = Array.isArray(raw) ? raw[0] : raw
  return value ?? ''
})

const matchedBatch = computed(() => {
  const value = code.value.trim()
  if (!value) return undefined
  const stripped = value.replace(/^TRACE-/i, '')
  return batches.find((item) => item.batchNo === value || item.batchNo === stripped)
})

const isFallback = computed(() => !matchedBatch.value)

const display = computed<TraceDisplay>(() => {
  const batch = matchedBatch.value ?? batches.find((item) => item.batchNo === traceDetail.batchNo)
  if (batch) {
    const plot = findPlot(batch.plot)
    return {
      batchNo: batch.batchNo,
      crop: batch.crop,
      variety: batch.variety,
      origin: `${park.name} · ${plot?.name ?? plotName(batch.plot)}`,
      grade: batch.grade,
      weightText: `${formatNumber(batch.weight)} kg`,
      harvestedAt: batch.harvestedAt,
      plantedAt: batch.plantedAt,
      farmer: plot?.manager ?? traceDetail.farmer,
      plotName: plot?.name ?? plotName(batch.plot),
      plotCode: batch.plot,
      scans: batch.scans,
      qrCount: batch.qrCount,
      status: batch.status,
      certified: true,
    }
  }
  return {
    batchNo: traceDetail.batchNo,
    crop: traceDetail.crop,
    variety: traceDetail.variety,
    origin: traceDetail.origin,
    grade: traceDetail.grade,
    weightText: traceDetail.weight,
    harvestedAt: traceDetail.harvestedAt,
    plantedAt: '2026-07-26',
    farmer: traceDetail.farmer,
    plotName: plotName(traceDetail.plot),
    plotCode: traceDetail.plot,
    scans: traceDetail.scans,
    qrCount: 1260,
    status: '已赋码',
    certified: true,
  }
})

const report = computed(() => {
  const hit = inspections.find((item) => item.batchNo === display.value.batchNo)
  if (hit) {
    return {
      reportNo: hit.reportNo,
      agency: hit.agency,
      testedAt: hit.testedAt,
      pesticide: hit.pesticide,
      heavyMetal: hit.heavyMetal,
      conclusion: hit.result,
    }
  }
  return traceDetail.inspect
})
</script>

<template>
  <div class="h5-page">
    <div class="h5-shell">
      <div class="h5-hero">
        <span class="h5-hero__badge">{{ display.certified ? '绿色食品认证' : '常规种植' }} · 全程可追溯</span>
        <h1>{{ display.crop }}</h1>
        <p>{{ display.variety }} · {{ display.origin }}</p>
        <p class="trace-code">溯源码 / 批次号：{{ display.batchNo }}</p>
        <div class="h5-hero__stats">
          <div class="h5-hero__stat">
            <span>批次号</span>
            <b class="stat-batch">{{ display.batchNo }}</b>
          </div>
          <div class="h5-hero__stat">
            <span>产品等级</span>
            <b>{{ display.grade }}</b>
          </div>
          <div class="h5-hero__stat">
            <span>批次重量</span>
            <b>{{ display.weightText }}</b>
          </div>
          <div class="h5-hero__stat">
            <span>扫码次数</span>
            <b>{{ formatNumber(display.scans) }}</b>
          </div>
        </div>
      </div>

      <div class="h5-body">
        <div v-if="isFallback" class="notice notice--warn" style="margin-bottom: 13px">
          未查询到“{{ code || '空码' }}”对应的溯源批次，当前展示示例批次 {{ display.batchNo }} 的完整档案。
        </div>

        <div v-if="display.batchNo === 'B20261030-06'" class="notice notice--danger" style="margin-bottom: 13px">
          召回提示：该批次因农残检测结果超出内部验收标准，已启动产品召回，请勿继续食用；如已购买，请联系园区办理退换。
        </div>

        <section class="h5-card">
          <h2>产地信息</h2>
          <div class="h5-report">
            <div class="h5-report__row"><span>产地</span><b>{{ display.origin }}</b></div>
            <div class="h5-report__row"><span>地块</span><b>{{ display.plotName }}（{{ display.plotCode }}）</b></div>
            <div class="h5-report__row"><span>种植农户</span><b>{{ display.farmer }}</b></div>
            <div class="h5-report__row"><span>定植日期</span><b>{{ display.plantedAt }}</b></div>
            <div class="h5-report__row"><span>采收日期</span><b>{{ display.harvestedAt }}</b></div>
          </div>
        </section>

        <section class="h5-card">
          <h2>生长农事记录</h2>
          <div class="h5-timeline">
            <div v-for="(item, index) in traceTimeline" :key="`${item.date}-${index}`" class="h5-timeline__item">
              <div class="h5-timeline__date">{{ item.date }}</div>
              <div class="h5-timeline__title">{{ item.title }}</div>
              <div class="h5-timeline__desc">{{ item.desc }}</div>
            </div>
          </div>
        </section>

        <section class="h5-card">
          <h2>质量检测报告</h2>
          <div class="h5-report">
            <div class="h5-report__row"><span>报告编号</span><b>{{ report.reportNo }}</b></div>
            <div class="h5-report__row"><span>检测机构</span><b>{{ report.agency }}</b></div>
            <div class="h5-report__row"><span>检测日期</span><b>{{ report.testedAt }}</b></div>
            <div class="h5-report__row"><span>农药残留</span><b>{{ report.pesticide }}</b></div>
            <div class="h5-report__row"><span>重金属</span><b>{{ report.heavyMetal }}</b></div>
            <div class="h5-report__row">
              <span>结论</span>
              <b>
                <span class="tag" :class="report.conclusion === '合格' ? 'tag--ok' : 'tag--danger'">{{ report.conclusion }}</span>
              </b>
            </div>
          </div>
        </section>

        <section class="h5-card">
          <h2>批次档案</h2>
          <div class="h5-report">
            <div class="h5-report__row"><span>批次号</span><b>{{ display.batchNo }}</b></div>
            <div class="h5-report__row"><span>作物品种</span><b>{{ display.crop }} · {{ display.variety }}</b></div>
            <div class="h5-report__row"><span>地块编号</span><b>{{ display.plotCode }}</b></div>
            <div class="h5-report__row"><span>等级 / 重量</span><b>{{ display.grade }} · {{ display.weightText }}</b></div>
            <div class="h5-report__row"><span>赋码数量</span><b>{{ formatNumber(display.qrCount) }} 枚</b></div>
            <div class="h5-report__row"><span>扫码次数</span><b>{{ formatNumber(display.scans) }} 次</b></div>
            <div class="h5-report__row"><span>批次状态</span><b>{{ display.status }}</b></div>
          </div>
        </section>

        <section class="h5-card qr-card">
          <h2>溯源二维码</h2>
          <div class="qr-wrap">
            <QrCode :text="display.batchNo" :size="156" />
          </div>
          <p class="qr-note">
            一物一码：扫描二维码可查看该批次从定植、农事管理到采收检测的全流程记录，本页面无需登录即可访问。
          </p>
        </section>

        <div class="h5-footer">
          数据由云岭智慧农业示范园提供 · 本页面无需登录
          <div style="margin-top: 6px">
            <RouterLink class="h5-footer__link" to="/portals">返回平台总览</RouterLink>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.h5-shell .h5-hero__stats {
  grid-template-columns: repeat(2, minmax(0, 1fr));
}

.trace-code {
  margin-top: 8px;
  font-size: 11px;
  color: rgba(200, 240, 215, 0.62);
  font-family: var(--font-num);
}

.stat-batch {
  word-break: break-all;
  font-size: 12px;
}

.qr-wrap {
  display: flex;
  justify-content: center;
  padding: 6px 0 12px;
}

.qr-note {
  font-size: 11.5px;
  line-height: 1.7;
  color: var(--muted);
  text-align: center;
}

.h5-footer__link {
  color: var(--brand);
  border-bottom: 1px dashed var(--line-strong);
}
</style>
