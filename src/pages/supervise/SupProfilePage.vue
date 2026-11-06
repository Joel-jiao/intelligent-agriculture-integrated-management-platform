<script setup lang="ts">
import { reactive, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import { useToast } from '@/composables/useToast'
import { loginLogs, operationLogs } from '@/data/mock'
import { nowDateTime } from '@/utils/format'

interface SecurityRecord {
  id: string
  time: string
  action: string
  module: string
  ip: string
  result: '成功' | '失败'
}

const toast = useToast()

const profile = reactive({
  name: '黄洁',
  account: 'sup01',
  role: '监管人员',
  unit: '璧山区农业农村委员会',
  phone: '135****1180',
  email: 'huangjie@bishan.gov.cn',
  jurisdiction: '璧山区辖区（12 个农业园区）',
  address: '重庆市璧山区璧城街道双龙大道 118 号',
  remark: '负责辖区农产品质量安全抽检、溯源台账核查、农药使用合规检查与预警闭环处置。',
})
const savedProfile = reactive({ ...profile })

const notify = reactive({
  sms: true,
  weekly: true,
})

const pwd = reactive({
  old: '',
  next: '',
  confirm: '',
})

const securityRecords = reactive<SecurityRecord[]>([
  ...loginLogs
    .filter((item) => item.account === 'sup01')
    .map((item) => ({ id: item.id, time: item.time, action: item.action, module: item.module, ip: item.ip, result: item.result })),
  ...operationLogs
    .filter((item) => item.account === 'sup01')
    .map((item) => ({ id: item.id, time: item.time, action: item.action, module: item.module, ip: item.ip, result: item.result })),
  { id: 'SR-PWD', time: '2026-11-03 18:22:41', action: '修改登录密码', module: '账号安全', ip: '10.20.5.118', result: '成功' },
  { id: 'SR-SMS', time: '2026-10-29 09:14:07', action: '绑定监管短信通道', module: '账号安全', ip: '10.20.5.118', result: '成功' },
])
securityRecords.sort((a, b) => b.time.localeCompare(a.time))

const lastSavedAt = ref('2026-11-05 17:20')

function saveProfile() {
  if (!profile.name.trim() || !profile.unit.trim() || !profile.jurisdiction.trim()) {
    toast.warn('请完善姓名、所属单位与辖区范围')
    return
  }
  Object.assign(savedProfile, profile)
  lastSavedAt.value = nowDateTime()
  toast.success('监管人员资料已保存')
}

function resetProfile() {
  Object.assign(profile, savedProfile)
  toast.info('已还原为上次保存的监管人员资料')
}

function saveNotify() {
  toast.success(`通知偏好已更新：预警短信${notify.sms ? '开启' : '关闭'}，监管周报${notify.weekly ? '开启' : '关闭'}`)
}

function changePassword() {
  if (!pwd.old) {
    toast.warn('请输入原密码')
    return
  }
  if (pwd.next.length < 8) {
    toast.error('新密码长度不能少于 8 位')
    return
  }
  if (!/[A-Za-z]/.test(pwd.next) || !/\d/.test(pwd.next)) {
    toast.error('新密码需同时包含字母与数字')
    return
  }
  if (pwd.next !== pwd.confirm) {
    toast.error('两次输入的新密码不一致')
    return
  }
  securityRecords.unshift({
    id: `SR-${Date.now().toString().slice(-6)}`,
    time: nowDateTime(),
    action: '修改登录密码',
    module: '账号安全',
    ip: '10.20.5.118',
    result: '成功',
  })
  if (securityRecords.length > 8) securityRecords.splice(8)
  pwd.old = ''
  pwd.next = ''
  pwd.confirm = ''
  toast.success('密码修改成功，请使用新密码重新登录')
}
</script>

<template>
  <div>
    <PageHeader
      eyebrow="SUPERVISION ACCOUNT"
      title="监管账号设置"
      description="监管人员资料、通知偏好与账号安全设置 · 监管账号 sup01"
    >
      <template #actions>
        <span class="tag tag--ok">账号状态：正常</span>
      </template>
    </PageHeader>

    <div class="grid grid--main">
      <div class="stack">
        <section class="card">
          <div class="card__head">
            <div class="card__title">监管人员资料 <span class="card__sub">上次保存 {{ lastSavedAt }}</span></div>
            <span class="tag tag--brand">璧山区农业农村委员会</span>
          </div>
          <div class="card__body">
            <div class="form-grid">
              <div class="field">
                <span class="field__label">姓名</span>
                <input v-model="profile.name" class="input" />
              </div>
              <div class="field">
                <span class="field__label">监管账号</span>
                <input v-model="profile.account" class="input" readonly style="background: var(--surface-2); color: var(--muted)" />
              </div>
              <div class="field">
                <span class="field__label">所属单位</span>
                <input v-model="profile.unit" class="input" />
              </div>
              <div class="field">
                <span class="field__label">岗位</span>
                <input v-model="profile.role" class="input" />
              </div>
              <div class="field">
                <span class="field__label">联系电话</span>
                <input v-model="profile.phone" class="input" />
              </div>
              <div class="field">
                <span class="field__label">工作邮箱</span>
                <input v-model="profile.email" class="input" />
              </div>
              <div class="field span-2">
                <span class="field__label">辖区范围</span>
                <input v-model="profile.jurisdiction" class="input" />
              </div>
              <div class="field span-2">
                <span class="field__label">办公地址</span>
                <input v-model="profile.address" class="input" />
              </div>
              <div class="field span-2">
                <span class="field__label">监管职责说明</span>
                <textarea v-model="profile.remark" class="textarea" />
              </div>
            </div>
            <div class="form-foot">
              <button class="btn" type="button" @click="resetProfile">还原</button>
              <button class="btn btn--primary" type="button" @click="saveProfile">保存资料</button>
            </div>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">账号安全记录 <span class="card__sub">最近 8 条</span></div>
            <span class="tag tag--outline">登录与敏感操作</span>
          </div>
          <div class="table-wrap" style="border: 0; border-radius: 0 0 14px 14px">
            <table class="data-table">
              <thead>
                <tr>
                  <th>时间</th>
                  <th>操作</th>
                  <th>模块</th>
                  <th>IP 地址</th>
                  <th>结果</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="item in securityRecords" :key="item.id">
                  <td class="num cell-muted">{{ item.time }}</td>
                  <td class="cell-strong">{{ item.action }}</td>
                  <td>{{ item.module }}</td>
                  <td class="num">{{ item.ip }}</td>
                  <td><StatusTag :text="item.result" :tone="item.result === '成功' ? 'ok' : 'danger'" dot /></td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>
      </div>

      <div class="stack">
        <section class="card">
          <div class="card__head">
            <div class="card__title">通知偏好</div>
            <span class="tag tag--brand">即时生效</span>
          </div>
          <div class="card__body">
            <div class="pref-row">
              <div>
                <div class="pref-row__title">预警短信</div>
                <div class="pref-row__desc">高危预警发生时通过短信推送至绑定手机号</div>
              </div>
              <label class="switch">
                <input v-model="notify.sms" type="checkbox" />
                <span class="switch__track" />
              </label>
            </div>
            <div class="pref-row">
              <div>
                <div class="pref-row__title">监管周报</div>
                <div class="pref-row__desc">每周一推送辖区质量、溯源与预警处置摘要</div>
              </div>
              <label class="switch">
                <input v-model="notify.weekly" type="checkbox" />
                <span class="switch__track" />
              </label>
            </div>
            <div class="notice notice--brand" style="margin-top: 14px">
              短信通道已绑定 {{ profile.phone }}，修改联系电话后需重新验证。
            </div>
            <button class="btn btn--primary btn--full" type="button" style="margin-top: 14px" @click="saveNotify">保存通知偏好</button>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">修改密码</div>
            <span class="tag tag--outline">至少 8 位</span>
          </div>
          <div class="card__body">
            <div class="field" style="margin-bottom: 12px">
              <span class="field__label">原密码</span>
              <input v-model="pwd.old" type="password" class="input" placeholder="请输入当前登录密码" />
            </div>
            <div class="field" style="margin-bottom: 12px">
              <span class="field__label">新密码</span>
              <input v-model="pwd.next" type="password" class="input" placeholder="需包含字母与数字，不少于 8 位" />
            </div>
            <div class="field" style="margin-bottom: 14px">
              <span class="field__label">确认新密码</span>
              <input v-model="pwd.confirm" type="password" class="input" placeholder="再次输入新密码" @keyup.enter="changePassword" />
            </div>
            <div class="notice notice--warn" style="margin-bottom: 14px">
              密码修改后需重新登录，历史会话将在 5 分钟内失效。
            </div>
            <button class="btn btn--primary btn--full" type="button" @click="changePassword">确认修改密码</button>
          </div>
        </section>
      </div>
    </div>
  </div>
</template>

<style scoped>
.pref-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
  padding: 10px 0;
  border-bottom: 1px dashed var(--line);
}

.pref-row:last-of-type {
  border-bottom: 0;
}

.pref-row__title {
  font-size: 12.5px;
  font-weight: 600;
  color: var(--ink);
}

.pref-row__desc {
  margin-top: 2px;
  font-size: 11.5px;
  color: var(--muted);
}
</style>
