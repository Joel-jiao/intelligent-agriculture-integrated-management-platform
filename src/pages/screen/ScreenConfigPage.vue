<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import PageHeader from '@/components/ui/PageHeader.vue'
import { useToast } from '@/composables/useToast'
import { plots, screenConfig as seedConfig } from '@/api/store'

const toast = useToast()
const router = useRouter()

interface Section {
  id: string
  name: string
  icon: string
  enabled: boolean
}

const sections = ref<Section[]>(seedConfig.sections.map((item) => ({ ...item })))
const form = reactive({
  interval: seedConfig.interval,
  theme: seedConfig.theme,
  resolution: seedConfig.resolution,
  defaultScope: seedConfig.defaultScope,
})

const enabledCount = computed(() => sections.value.filter((item) => item.enabled).length)

function toggleSection(section: Section) {
  section.enabled = !section.enabled
}

function moveUp(index: number) {
  if (index === 0) return
  const [item] = sections.value.splice(index, 1)
  if (item) sections.value.splice(index - 1, 0, item)
}

function moveDown(index: number) {
  if (index === sections.value.length - 1) return
  const [item] = sections.value.splice(index, 1)
  if (item) sections.value.splice(index + 1, 0, item)
}

function resetDefaults() {
  sections.value = seedConfig.sections.map((item) => ({ ...item }))
  form.interval = seedConfig.interval
  form.theme = seedConfig.theme
  form.resolution = seedConfig.resolution
  form.defaultScope = seedConfig.defaultScope
  toast.success('已恢复默认配置')
}

function saveConfig() {
  toast.success('大屏配置已保存，指挥中心大屏即时生效')
}

function preview() {
  router.push('/screen')
}
</script>

<template>
  <div>
    <PageHeader eyebrow="SCREEN CONFIG" title="大屏展示配置" description="配置大屏板块启停、轮播时间与顺序、默认展示范围，保存后指挥中心大屏即时生效">
      <template #actions>
        <button class="btn" type="button" @click="preview">打开大屏</button>
        <button class="btn btn--primary" type="button" @click="saveConfig">保存配置</button>
      </template>
    </PageHeader>

    <div class="config-grid">
      <section class="card">
        <div class="card__head">
          <div class="card__title">板块开关与播放顺序</div>
          <span class="tag tag--brand">{{ enabledCount }} / {{ sections.length }} 已启用</span>
        </div>
        <div class="card__body">
          <div class="notice notice--brand" style="margin-bottom: 12px">
            <span>已启用的板块将按下方顺序在指挥大屏中轮播展示。</span>
          </div>
          <div class="section-list">
            <div v-for="(section, index) in sections" :key="section.id" class="section-row" :class="{ 'is-disabled': !section.enabled }">
              <span class="section-row__icon">{{ section.icon }}</span>
              <div class="section-row__main">
                <b>{{ section.name }}</b>
                <span class="cell-muted">{{ index + 1 }} 号位</span>
              </div>
              <button class="section-row__arrow" type="button" :disabled="index === 0" @click="moveUp(index)">↑</button>
              <button class="section-row__arrow" type="button" :disabled="index === sections.length - 1" @click="moveDown(index)">↓</button>
              <button class="switch" :class="{ 'is-on': section.enabled }" type="button" @click="toggleSection(section)">
                <span class="switch__thumb" />
              </button>
            </div>
          </div>
        </div>
      </section>

      <div class="stack">
        <section class="card">
          <div class="card__head">
            <div class="card__title">轮播与主题</div>
          </div>
          <div class="card__body">
            <div class="form-grid">
              <label class="field">
                <span class="field__label">轮播间隔（秒）</span>
                <input v-model.number="form.interval" class="input" type="number" min="5" max="120" />
              </label>
              <label class="field">
                <span class="field__label">大屏主题</span>
                <select v-model="form.theme" class="select">
                  <option>深色主题</option>
                  <option>浅色主题</option>
                  <option>科技蓝主题</option>
                </select>
              </label>
              <label class="field">
                <span class="field__label">分辨率适配</span>
                <select v-model="form.resolution" class="select">
                  <option>1920 × 1080</option>
                  <option>2560 × 1440</option>
                  <option>3840 × 2160</option>
                </select>
              </label>
              <label class="field">
                <span class="field__label">默认展示范围</span>
                <select v-model="form.defaultScope" class="select">
                  <option>全部地块</option>
                  <option v-for="plot in plots" :key="plot.id" :value="plot.name">{{ plot.name }}</option>
                </select>
              </label>
            </div>
          </div>
        </section>

        <section class="card card--tint">
          <div class="card__head">
            <div class="card__title">大屏缩略预览</div>
          </div>
          <div class="card__body">
            <div class="screen-preview">
              <div class="screen-preview__head">
                <span>云岭智慧农业 · 指挥中心</span>
                <span class="screen-preview__clock">2026-11-06 09:42</span>
              </div>
              <div class="screen-preview__grid">
                <div v-for="section in sections.filter((item) => item.enabled).slice(0, 6)" :key="section.id" class="screen-preview__cell">
                  <span>{{ section.icon }}</span>
                  <em>{{ section.name }}</em>
                </div>
              </div>
              <div class="screen-preview__foot">已启用 {{ enabledCount }} 个板块 · 轮播间隔 {{ form.interval }}s</div>
            </div>
            <button class="btn btn--sm btn--full" type="button" style="margin-top: 12px" @click="preview">查看实际效果 →</button>
          </div>
        </section>

        <section class="card">
          <div class="card__body">
            <div class="notice notice--warn">保存后大屏即时生效，请确认轮播顺序与默认范围后再保存。</div>
          </div>
        </section>
      </div>
    </div>
  </div>
</template>

<style scoped>
.config-grid {
  display: grid;
  grid-template-columns: 1.1fr 1fr;
  gap: 16px;
  align-items: start;
}

.section-list {
  display: grid;
  gap: 8px;
}

.section-row {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 9px 12px;
  border: 1px solid var(--line);
  border-radius: 9px;
  background: var(--bg-card-solid);
  transition: 0.18s;
}

.section-row.is-disabled {
  opacity: 0.55;
}

.section-row__icon {
  display: grid;
  place-items: center;
  width: 30px;
  height: 30px;
  border-radius: 8px;
  background: var(--brand-soft);
  color: var(--brand);
  font-size: 14px;
  font-weight: 700;
}

.section-row__main {
  flex: 1;
  min-width: 0;
}

.section-row__main b {
  display: block;
  font-size: 12.5px;
  color: var(--ink);
}

.section-row__main .cell-muted {
  font-size: 10.5px;
}

.section-row__arrow {
  width: 24px;
  height: 24px;
  border: 1px solid var(--line);
  border-radius: 6px;
  background: var(--bg-card-solid);
  color: var(--muted);
  cursor: pointer;
}

.section-row__arrow:disabled {
  opacity: 0.35;
  cursor: not-allowed;
}

.switch {
  position: relative;
  width: 40px;
  height: 22px;
  border: 0;
  border-radius: 999px;
  background: #d6ded9;
  cursor: pointer;
  transition: 0.2s;
}

.switch.is-on {
  background: var(--brand);
}

.switch__thumb {
  position: absolute;
  top: 3px;
  left: 3px;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background: var(--bg-card-solid);
  transition: 0.2s;
}

.switch.is-on .switch__thumb {
  transform: translateX(18px);
}

.screen-preview {
  border: 1px solid rgba(90, 220, 150, 0.18);
  border-radius: 10px;
  background: linear-gradient(150deg, #0b3220, #061a10);
  padding: 12px;
  color: #eaf6ee;
}

.screen-preview__head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding-bottom: 10px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.1);
  font-size: 11px;
  color: rgba(234, 246, 238, 0.8);
}

.screen-preview__clock {
  font-family: var(--font-num);
  color: #b5ecc7;
}

.screen-preview__grid {
  display: grid;
  grid-template-columns: repeat(3, minmax(0, 1fr));
  gap: 8px;
  padding: 12px 0;
}

.screen-preview__cell {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 4px;
  padding: 12px 6px;
  border: 1px solid rgba(255, 255, 255, 0.08);
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.05);
}

.screen-preview__cell span {
  display: grid;
  place-items: center;
  width: 22px;
  height: 22px;
  border-radius: 6px;
  background: rgba(181, 236, 199, 0.16);
  color: #b5ecc7;
  font-size: 12px;
}

.screen-preview__cell em {
  font-style: normal;
  font-size: 10px;
  color: rgba(234, 246, 238, 0.6);
}

.screen-preview__foot {
  padding-top: 10px;
  border-top: 1px solid rgba(255, 255, 255, 0.1);
  text-align: center;
  font-size: 10px;
  color: rgba(234, 246, 238, 0.45);
}

@media (max-width: 900px) {
  .config-grid {
    grid-template-columns: 1fr;
  }
}
</style>
