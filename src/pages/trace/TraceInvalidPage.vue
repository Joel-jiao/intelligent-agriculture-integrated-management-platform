<script setup lang="ts">
import { computed } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { park } from '@/data/mock'

const route = useRoute()
const router = useRouter()

const qrcodeId = computed(() => {
  const raw = route.query.qrcodeId
  const value = Array.isArray(raw) ? raw[0] : raw
  return value ?? ''
})

type InvalidReason = 'invalid' | 'expired' | 'recalled'

const reason = computed<InvalidReason>(() => {
  const raw = route.query.reason
  const value = Array.isArray(raw) ? raw[0] : raw
  if (value === 'expired') return 'expired'
  if (value === 'recalled') return 'recalled'
  return 'invalid'
})

const content = computed(() => {
  if (reason.value === 'recalled') {
    return {
      title: '该批次产品已启动召回',
      desc: '您查询的农产品所在批次已启动产品召回，溯源档案已暂停展示。如已购买，请勿继续食用并联系商家办理退换。',
      badge: '产品召回',
    }
  }
  if (reason.value === 'expired') {
    return {
      title: '溯源码已过期',
      desc: '该溯源码已超过有效查询期限，溯源档案已失效。如需核实产品信息，请联系商家或园区客服。',
      badge: '已过期',
    }
  }
  return {
    title: '溯源码无效',
    desc: '未查询到该溯源码对应的产品信息，可能为无效二维码或录入信息有误，请联系商家核实。',
    badge: '无效码',
  }
})

function goBack() {
  if (window.history.length > 1) {
    router.back()
  } else {
    router.push('/portals')
  }
}
</script>

<template>
  <div class="h5-page">
    <div class="h5-shell">
      <div class="h5-hero h5-hero--invalid">
        <span class="h5-hero__badge">{{ park.name }} · {{ content.badge }}</span>
        <div class="invalid-mark">!</div>
        <h1>{{ content.title }}</h1>
        <p>{{ content.desc }}</p>
        <p v-if="qrcodeId" class="trace-code">溯源码：{{ qrcodeId }}</p>
      </div>

      <div class="h5-body">
        <section class="h5-card">
          <h2>如何处理</h2>
          <div class="h5-report">
            <div class="h5-report__row"><span>联系商家</span><b>扫描产品包装上的商家联系方式</b></div>
            <div class="h5-report__row"><span>园区客服</span><b>023-6888-0000（工作日 9:00-18:00）</b></div>
            <div class="h5-report__row"><span>产地</span><b>{{ park.name }} · {{ park.location }}</b></div>
          </div>
        </section>

        <div class="invalid-actions">
          <button class="h5-btn h5-btn--ghost" type="button" @click="goBack">返回</button>
          <RouterLink class="h5-btn h5-btn--primary" to="/portals">进入平台总览</RouterLink>
        </div>

        <div class="h5-footer">
          数据由{{ park.name }}提供 · 本页面无需登录
          <div style="margin-top: 6px">
            <RouterLink class="h5-footer__link" to="/trace/h5/B20261105-03">查看示例溯源档案</RouterLink>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.h5-hero--invalid {
  text-align: center;
}

.invalid-mark {
  display: grid;
  place-items: center;
  width: 64px;
  height: 64px;
  margin: 4px auto 14px;
  border-radius: 50%;
  background: rgba(255, 255, 255, 0.12);
  color: #ffd9a8;
  font-size: 30px;
  font-weight: 800;
}

.trace-code {
  margin-top: 8px;
  font-size: 11px;
  color: rgba(200, 240, 215, 0.62);
  font-family: var(--font-num);
}

.invalid-actions {
  display: flex;
  gap: 10px;
  margin-top: 14px;
}

.h5-btn {
  flex: 1;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 12px 14px;
  border-radius: 10px;
  font-size: 13px;
  font-weight: 600;
  cursor: pointer;
}

.h5-btn--primary {
  border: 0;
  background: var(--brand);
  color: #fff;
}

.h5-btn--ghost {
  border: 1px solid var(--line-strong);
  background: var(--bg-card-solid);
  color: var(--ink);
}

.h5-footer__link {
  color: var(--brand);
  border-bottom: 1px dashed var(--line-strong);
}
</style>
