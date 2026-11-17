<script setup lang="ts">
import { computed } from 'vue'
import { API_BASE_URL } from '@/api/http'
import { backend, reloadAllData } from '@/api/store'

const isLoading = computed(() => backend.status === 'idle' || backend.status === 'loading')
const isError = computed(() => backend.status === 'error')

function retry() {
  void reloadAllData()
}
</script>

<template>
  <div class="gate">
    <a-card class="gate__card">
      <template v-if="isLoading">
        <a-spin size="large" />
        <h1 class="gate__title">正在连接后端服务</h1>
        <p class="gate__desc">业务数据统一从后端接口读取，请稍候…</p>
        <p class="gate__meta">接口地址 {{ API_BASE_URL }}</p>
      </template>

      <a-result
        v-else-if="isError"
        status="error"
        title="后端服务不可用"
        sub-title="页面数据全部来自后端，当前无法获取数据，已阻止进入业务功能。"
      >
        <template #extra>
          <div class="gate__actions">
            <a-button type="primary" @click="retry">重新连接</a-button>
          </div>
          <div class="gate__hint">
            <b>启动后端后重试</b>
            <code>npm run dev:api</code>
            <span class="gate__hint-or">或前后端一起启动</span>
            <code>npm run dev:all</code>
          </div>
          <p class="gate__error">{{ backend.error }}</p>
          <p class="gate__meta">接口地址 {{ API_BASE_URL }} · 已尝试 {{ backend.attempts }} 次</p>
        </template>
      </a-result>
    </a-card>
  </div>
</template>

<style scoped>
.gate {
  display: grid;
  place-items: center;
  min-height: 100vh;
  padding: 24px;
  background: var(--bg, #f5f5f7);
}

.gate__card {
  width: min(460px, 100%);
  padding: 8px 12px;
  text-align: center;
  border-radius: 16px;
}

.gate__title {
  margin: 16px 0 6px;
  font-size: 17px;
  font-weight: 650;
  color: var(--ink, #1d1d1f);
}

.gate__desc {
  margin: 0;
  font-size: 12.5px;
  line-height: 1.6;
  color: var(--ink-2, #5f6368);
}

.gate__actions {
  margin-top: 4px;
}

.gate__hint {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin-top: 18px;
  padding-top: 16px;
  font-size: 11.5px;
  color: var(--ink-2, #5f6368);
  border-top: 1px dashed var(--line, #e5e5ea);
}

.gate__hint b {
  color: var(--ink, #1d1d1f);
  font-weight: 650;
}

.gate__hint code {
  padding: 4px 8px;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  background: var(--brand-soft, rgba(0, 122, 255, 0.08));
  border-radius: 6px;
  color: var(--brand, #007aff);
}

.gate__hint-or {
  font-size: 11px;
  opacity: 0.7;
}

.gate__error {
  margin: 14px 0 0;
  padding: 8px 10px;
  font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
  font-size: 11.5px;
  line-height: 1.5;
  color: #8a5a00;
  text-align: left;
  word-break: break-all;
  background: #fff6e5;
  border-radius: 8px;
}

.gate__meta {
  margin: 14px 0 0;
  font-size: 11px;
  color: var(--text-tertiary, #8e8e93);
  word-break: break-all;
}
</style>
