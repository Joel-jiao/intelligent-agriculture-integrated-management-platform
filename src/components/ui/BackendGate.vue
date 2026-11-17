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
    <div class="gate__card">
      <template v-if="isLoading">
        <span class="gate__spinner" aria-hidden="true" />
        <h1 class="gate__title">正在连接后端服务</h1>
        <p class="gate__desc">业务数据统一从后端接口读取，请稍候…</p>
        <p class="gate__meta">接口地址 {{ API_BASE_URL }}</p>
      </template>

      <template v-else-if="isError">
        <span class="gate__badge" aria-hidden="true">!</span>
        <h1 class="gate__title">后端服务不可用</h1>
        <p class="gate__desc">页面数据全部来自后端，当前无法获取数据，已阻止进入业务功能。</p>
        <p class="gate__error">{{ backend.error }}</p>
        <div class="gate__actions">
          <button class="btn btn--primary" type="button" @click="retry">重新连接</button>
        </div>
        <div class="gate__hint">
          <b>启动后端后重试</b>
          <code>npm run dev:api</code>
          <span class="gate__hint-or">或前后端一起启动</span>
          <code>npm run dev:all</code>
        </div>
        <p class="gate__meta">接口地址 {{ API_BASE_URL }} · 已尝试 {{ backend.attempts }} 次</p>
      </template>
    </div>
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
  width: min(440px, 100%);
  padding: 32px 28px;
  text-align: center;
  background: var(--surface, #fff);
  border: 1px solid var(--line, #e5e5ea);
  border-radius: 16px;
  box-shadow: 0 18px 48px rgba(15, 23, 42, 0.08);
}

.gate__spinner {
  display: inline-block;
  width: 28px;
  height: 28px;
  border: 3px solid var(--brand-soft, rgba(0, 122, 255, 0.18));
  border-top-color: var(--brand, #007aff);
  border-radius: 50%;
  animation: gate-spin 0.9s linear infinite;
}

.gate__badge {
  display: inline-grid;
  place-items: center;
  width: 34px;
  height: 34px;
  font-size: 18px;
  font-weight: 700;
  color: #fff;
  background: var(--danger, #e5484d);
  border-radius: 50%;
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

.gate__error {
  margin: 12px 0 0;
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

.gate__actions {
  margin-top: 16px;
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

.gate__meta {
  margin: 14px 0 0;
  font-size: 11px;
  color: var(--ink-3, #8e8e93);
  word-break: break-all;
}

@keyframes gate-spin {
  to {
    transform: rotate(360deg);
  }
}
</style>
