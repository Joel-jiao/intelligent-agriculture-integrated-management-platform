<script setup lang="ts">
import { reactive, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import { useToast } from '@/composables/useToast'
import { nowDateTime } from '@/utils/format'

const toast = useToast()

type TabKey = 'basic' | 'security' | 'keys' | 'notify'
const activeTab = ref<TabKey>('basic')

const tabs: { key: TabKey; label: string }[] = [
  { key: 'basic', label: '基本资料' },
  { key: 'security', label: '安全设置' },
  { key: 'keys', label: '密钥与设备' },
  { key: 'notify', label: '通知偏好' },
]

const profile = reactive({
  name: '张运维',
  account: 'ops',
  phone: '136****5521',
  email: 'ops@yunling-agri.com',
  department: '运维中心',
  position: '系统运维工程师',
  office: '园区机房 · A 区 2F',
  dutyPhone: '023-8888 6612',
  bio: '负责园区物联网接入、服务器与数据库运维、账号权限及日志审计工作，值班时间 08:30-18:00。',
})

let profileSnapshot = { ...profile }

function saveProfile() {
  if (!profile.name.trim()) {
    toast.error('姓名不能为空')
    return
  }
  if (!profile.email.includes('@')) {
    toast.error('请输入有效的邮箱地址')
    return
  }
  if (!profile.phone.trim()) {
    toast.error('手机号不能为空')
    return
  }
  profileSnapshot = { ...profile }
  toast.success('个人资料已保存，变更内容已同步至运维端')
}

function resetProfile() {
  Object.assign(profile, profileSnapshot)
  toast.info('已恢复为上次保存的个人资料')
}

const pwdForm = reactive({ current: '', next: '', confirm: '' })
const pwdError = ref('')
const twoFactor = ref(true)
const loginGuard = ref(true)
const sessionTimeout = ref('30')

function changePassword() {
  pwdError.value = ''
  if (!pwdForm.current) {
    pwdError.value = '请输入当前登录密码'
  } else if (pwdForm.next.length < 8) {
    pwdError.value = '新密码长度不得少于 8 位'
  } else if (!/[A-Za-z]/.test(pwdForm.next) || !/\d/.test(pwdForm.next)) {
    pwdError.value = '新密码需同时包含字母与数字'
  } else if (pwdForm.next !== pwdForm.confirm) {
    pwdError.value = '两次输入的新密码不一致'
  } else if (pwdForm.next === pwdForm.current) {
    pwdError.value = '新密码不能与当前密码相同'
  }
  if (pwdError.value) {
    toast.error(pwdError.value)
    return
  }
  pwdForm.current = ''
  pwdForm.next = ''
  pwdForm.confirm = ''
  toast.success('登录密码已更新，其他设备上的会话将在 5 分钟内失效')
}

function toggleTwoFactor() {
  toast.success(`双因素认证已${twoFactor.value ? '开启' : '关闭'}${twoFactor.value ? '，下次登录需输入动态口令' : ''}`)
}

function saveSession() {
  toast.success(`登录安全策略已保存，会话超时时间设为 ${sessionTimeout.value} 分钟`)
}

interface ApiKey {
  id: string
  name: string
  key: string
  scope: string
  createdAt: string
}

const apiKeys = ref<ApiKey[]>([
  { id: 'K-01', name: '运维自动化脚本', key: 'ak_ops_a12f****90bc', scope: '设备读写 / 备份查询', createdAt: '2026-09-12 10:20' },
  { id: 'K-02', name: '监控告警回调', key: 'ak_mon_7c3d****e481', scope: '只读 / 告警订阅', createdAt: '2026-10-08 15:42' },
])

function genKey(): string {
  const hex = (length: number) => Math.random().toString(16).slice(2, 2 + length).padEnd(length, '0')
  return `ak_ops_${hex(4)}****${hex(4)}`
}

function copyText(text: string, label: string) {
  const clipboard = navigator.clipboard
  if (clipboard) {
    void clipboard.writeText(text).catch(() => undefined)
  }
  toast.success(`${label}已复制到剪贴板`)
}

function regenerate(item: ApiKey) {
  item.key = genKey()
  item.createdAt = nowDateTime()
  toast.success(`密钥「${item.name}」已重新生成，旧密钥立即失效`)
}

function removeKey(item: ApiKey) {
  apiKeys.value = apiKeys.value.filter((entry) => entry.id !== item.id)
  toast.success(`密钥「${item.name}」已删除`)
}

interface SessionDevice {
  id: string
  device: string
  browser: string
  ip: string
  location: string
  time: string
  current: boolean
}

const devices = ref<SessionDevice[]>([
  { id: 'D-01', device: '运维工作站', browser: 'Chrome 130 · Windows 11', ip: '192.168.10.31', location: '园区机房内网', time: '2026-11-06 09:10', current: true },
  { id: 'D-02', device: '值班笔记本', browser: 'Edge 130 · Windows 11', ip: '10.20.8.42', location: '璧山办公区', time: '2026-11-05 18:22', current: false },
  { id: 'D-03', device: '移动巡检终端', browser: 'Safari · iPadOS 18', ip: '10.20.8.57', location: '园区东门值班室', time: '2026-11-04 08:15', current: false },
])

function offlineDevice(item: SessionDevice) {
  devices.value = devices.value.filter((entry) => entry.id !== item.id)
  toast.success(`设备「${item.device}」已下线`)
}

const notify = reactive({
  alarm: true,
  backup: true,
  loginRisk: true,
  weekly: false,
  sms: true,
  channel: '站内 + 邮件',
})

function saveNotify() {
  toast.success('通知偏好已保存，新的设置将用于后续运维事件推送')
}

function refreshSession() {
  toast.info('会话信息已刷新，当前连接安全')
}
</script>

<template>
  <div>
    <PageHeader eyebrow="OPS ACCOUNT" title="运维个人设置" description="维护运维账号的基础资料、安全策略、API 密钥与通知偏好">
      <template #actions>
        <button class="btn" type="button" @click="refreshSession">刷新会话</button>
        <button class="btn btn--primary" type="button" @click="saveProfile">保存资料</button>
      </template>
    </PageHeader>

    <div class="grid grid--sidebar">
      <section class="card profile-card">
        <div class="card__body profile-card__body">
          <div class="avatar avatar--xl">{{ profile.name.slice(0, 1) }}</div>
          <b class="profile-card__name">{{ profile.name }}</b>
          <span class="profile-card__account">账号 {{ profile.account }}</span>
          <div class="row" style="justify-content: center; margin-top: 6px">
            <span class="tag tag--brand">运维</span>
            <StatusTag text="在线" tone="ok" dot />
            <span class="tag">系统全部</span>
          </div>
          <div class="kv" style="margin-top: 18px; grid-template-columns: 1fr">
            <div class="kv__item"><span>所属部门</span><b>{{ profile.department }} · {{ profile.position }}</b></div>
            <div class="kv__item"><span>办公位置</span><b>{{ profile.office }}</b></div>
            <div class="kv__item"><span>手机号</span><b>{{ profile.phone }}</b></div>
            <div class="kv__item"><span>邮箱</span><b>{{ profile.email }}</b></div>
            <div class="kv__item"><span>值班电话</span><b>{{ profile.dutyPhone }}</b></div>
            <div class="kv__item"><span>最后登录</span><b>2026-11-06 09:10 · 192.168.10.31</b></div>
            <div class="kv__item"><span>账号创建</span><b>2026-03-01</b></div>
            <div class="kv__item"><span>双因素认证</span><b>{{ twoFactor ? '已开启' : '未开启' }}</b></div>
          </div>
        </div>
      </section>

      <section class="card">
        <div class="card__head">
          <div class="title-group">
            <div class="card__title">账号设置</div>
          </div>
          <div class="tabs">
            <button
              v-for="tab in tabs"
              :key="tab.key"
              class="tab"
              :class="{ 'tab--active': activeTab === tab.key }"
              type="button"
              @click="activeTab = tab.key"
            >
              {{ tab.label }}
            </button>
          </div>
        </div>
        <div class="card__body">
          <template v-if="activeTab === 'basic'">
            <div class="form-grid">
              <label class="field">
                <span class="field__label">姓名</span>
                <input v-model="profile.name" class="input" />
              </label>
              <label class="field">
                <span class="field__label">登录账号</span>
                <input v-model="profile.account" class="input" disabled />
              </label>
              <label class="field">
                <span class="field__label">手机号</span>
                <input v-model="profile.phone" class="input" />
              </label>
              <label class="field">
                <span class="field__label">邮箱</span>
                <input v-model="profile.email" class="input" type="email" />
              </label>
              <label class="field">
                <span class="field__label">所属部门</span>
                <input v-model="profile.department" class="input" />
              </label>
              <label class="field">
                <span class="field__label">岗位</span>
                <input v-model="profile.position" class="input" />
              </label>
              <label class="field">
                <span class="field__label">办公位置</span>
                <input v-model="profile.office" class="input" />
              </label>
              <label class="field">
                <span class="field__label">值班电话</span>
                <input v-model="profile.dutyPhone" class="input" />
              </label>
              <label class="field span-2">
                <span class="field__label">个人简介</span>
                <textarea v-model="profile.bio" class="textarea" />
              </label>
            </div>
            <div class="form-foot">
              <button class="btn" type="button" @click="resetProfile">重置</button>
              <button class="btn btn--primary" type="button" @click="saveProfile">保存资料</button>
            </div>
          </template>

          <template v-else-if="activeTab === 'security'">
            <div class="form-grid">
              <label class="field span-2">
                <span class="field__label">当前密码</span>
                <input v-model="pwdForm.current" class="input" type="password" placeholder="请输入当前登录密码" />
              </label>
              <label class="field">
                <span class="field__label">新密码</span>
                <input v-model="pwdForm.next" class="input" type="password" placeholder="至少 8 位，含字母与数字" />
              </label>
              <label class="field">
                <span class="field__label">确认新密码</span>
                <input v-model="pwdForm.confirm" class="input" type="password" placeholder="请再次输入新密码" />
              </label>
            </div>
            <div v-if="pwdError" class="notice notice--danger" style="margin-top: 12px">
              <span>{{ pwdError }}</span>
            </div>
            <div class="form-foot" style="justify-content: flex-start">
              <button class="btn btn--primary" type="button" @click="changePassword">修改密码</button>
            </div>

            <div class="divider" />

            <div class="setting-row">
              <div>
                <b>双因素认证</b>
                <div class="setting-row__desc">登录时需输入手机动态口令，可显著降低账号被盗风险</div>
              </div>
              <label class="switch">
                <input v-model="twoFactor" type="checkbox" @change="toggleTwoFactor" />
                <span class="switch__track" />
                <span>{{ twoFactor ? '已开启' : '未开启' }}</span>
              </label>
            </div>
            <div class="setting-row">
              <div>
                <b>异地登录提醒</b>
                <div class="setting-row__desc">检测到非常用 IP 登录时发送站内与短信提醒</div>
              </div>
              <label class="switch">
                <input v-model="loginGuard" type="checkbox" />
                <span class="switch__track" />
                <span>{{ loginGuard ? '已开启' : '未开启' }}</span>
              </label>
            </div>
            <div class="setting-row">
              <div>
                <b>会话超时时间</b>
                <div class="setting-row__desc">无操作超过设定时间后自动退出登录</div>
              </div>
              <select v-model="sessionTimeout" class="select" style="width: 140px">
                <option value="15">15 分钟</option>
                <option value="30">30 分钟</option>
                <option value="60">60 分钟</option>
                <option value="120">120 分钟</option>
              </select>
            </div>
            <div class="form-foot">
              <button class="btn btn--primary" type="button" @click="saveSession">保存安全策略</button>
            </div>
          </template>

          <template v-else-if="activeTab === 'keys'">
            <div class="section-head">
              <b>API 密钥</b>
              <span class="cell-muted">用于运维自动化脚本与监控系统调用</span>
            </div>
            <div class="table-wrap">
              <table class="data-table">
                <thead>
                  <tr>
                    <th>名称</th>
                    <th>密钥</th>
                    <th>作用域</th>
                    <th>创建时间</th>
                    <th>操作</th>
                  </tr>
                </thead>
                <tbody>
                  <tr v-for="item in apiKeys" :key="item.id">
                    <td class="cell-strong">{{ item.name }}</td>
                    <td class="num">{{ item.key }}</td>
                    <td class="cell-muted">{{ item.scope }}</td>
                    <td class="num">{{ item.createdAt }}</td>
                    <td>
                      <div class="table-actions">
                        <button class="link-action" type="button" @click="copyText(item.key, '密钥')">复制</button>
                        <button class="link-action" type="button" @click="regenerate(item)">重新生成</button>
                        <button class="link-action link-action--danger" type="button" @click="removeKey(item)">删除</button>
                      </div>
                    </td>
                  </tr>
                  <tr v-if="apiKeys.length === 0">
                    <td colspan="5">
                      <div class="empty"><span class="empty__mark">空</span>当前账号暂无 API 密钥</div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>

            <div class="section-head" style="margin-top: 20px">
              <b>登录设备</b>
              <span class="cell-muted">共 {{ devices.length }} 台设备保持登录</span>
            </div>
            <div class="device-list">
              <div v-for="item in devices" :key="item.id" class="device-row">
                <div class="device-row__mark">{{ item.device.slice(0, 1) }}</div>
                <div class="device-row__text">
                  <div class="device-row__title">
                    {{ item.device }}
                    <span v-if="item.current" class="tag tag--brand">当前设备</span>
                  </div>
                  <div class="device-row__meta">{{ item.browser }} · {{ item.ip }} · {{ item.location }}</div>
                  <div class="device-row__meta">最近活跃 {{ item.time }}</div>
                </div>
                <button v-if="!item.current" class="link-action" type="button" @click="offlineDevice(item)">下线</button>
                <span v-else class="tag tag--ok">在线</span>
              </div>
            </div>
          </template>

          <template v-else>
            <div class="setting-row">
              <div>
                <b>设备与告警通知</b>
                <div class="setting-row__desc">设备离线、故障与告警升级时推送提醒</div>
              </div>
              <label class="switch">
                <input v-model="notify.alarm" type="checkbox" />
                <span class="switch__track" />
              </label>
            </div>
            <div class="setting-row">
              <div>
                <b>备份执行结果</b>
                <div class="setting-row__desc">自动备份成功或失败时接收结果摘要</div>
              </div>
              <label class="switch">
                <input v-model="notify.backup" type="checkbox" />
                <span class="switch__track" />
              </label>
            </div>
            <div class="setting-row">
              <div>
                <b>登录异常提醒</b>
                <div class="setting-row__desc">异常登录、连续失败与账号锁定事件</div>
              </div>
              <label class="switch">
                <input v-model="notify.loginRisk" type="checkbox" />
                <span class="switch__track" />
              </label>
            </div>
            <div class="setting-row">
              <div>
                <b>运维周报摘要</b>
                <div class="setting-row__desc">每周一 09:00 推送上周系统健康与工单摘要</div>
              </div>
              <label class="switch">
                <input v-model="notify.weekly" type="checkbox" />
                <span class="switch__track" />
              </label>
            </div>
            <div class="setting-row">
              <div>
                <b>短信通道</b>
                <div class="setting-row__desc">紧急事件同时通过短信下发至值班手机</div>
              </div>
              <label class="switch">
                <input v-model="notify.sms" type="checkbox" />
                <span class="switch__track" />
              </label>
            </div>
            <div class="setting-row">
              <div>
                <b>通知方式</b>
                <div class="setting-row__desc">选择接收运维通知的渠道组合</div>
              </div>
              <select v-model="notify.channel" class="select" style="width: 160px">
                <option value="仅站内">仅站内</option>
                <option value="站内 + 邮件">站内 + 邮件</option>
                <option value="站内 + 短信">站内 + 短信</option>
                <option value="站内 + 邮件 + 短信">站内 + 邮件 + 短信</option>
              </select>
            </div>
            <div class="notice notice--brand" style="margin-top: 14px">
              <span>紧急告警不受通知偏好限制，将始终通过值班电话与短信触达。</span>
            </div>
            <div class="form-foot">
              <button class="btn btn--primary" type="button" @click="saveNotify">保存通知偏好</button>
            </div>
          </template>
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped>
.profile-card {
  align-self: start;
}

.profile-card__body {
  display: flex;
  flex-direction: column;
  align-items: center;
  padding-top: 24px;
}

.profile-card__name {
  margin-top: 12px;
  font-size: 18px;
  font-weight: 700;
  color: var(--ink);
}

.profile-card__account {
  margin-top: 2px;
  font-size: 11.5px;
  color: var(--muted);
  font-family: var(--font-num);
}

.profile-card .kv {
  width: 100%;
  padding-top: 16px;
  border-top: 1px solid var(--line);
}

.title-group {
  display: flex;
  align-items: center;
  gap: 12px;
}

.divider {
  height: 1px;
  margin: 20px 0 4px;
  background: var(--line);
}

.setting-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 16px;
  padding: 12px 0;
  border-bottom: 1px dashed var(--line);
}

.setting-row:last-of-type {
  border-bottom: 0;
}

.setting-row b {
  display: block;
  font-size: 12.5px;
  color: var(--ink);
}

.setting-row__desc {
  margin-top: 2px;
  font-size: 11.5px;
  color: var(--muted);
}

.section-head {
  display: flex;
  align-items: baseline;
  gap: 9px;
  margin-bottom: 10px;
  font-size: 13px;
  color: var(--ink);
}

.section-head b {
  font-weight: 650;
}

.section-head .cell-muted {
  font-size: 11.5px;
}

.device-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.device-row {
  display: flex;
  align-items: center;
  gap: 11px;
  padding: 11px 12px;
  border: 1px solid var(--line);
  border-radius: 10px;
  background: var(--surface-2);
}

.device-row__mark {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  border-radius: 9px;
  background: var(--brand-soft);
  color: var(--brand);
  font-size: 13px;
  font-weight: 700;
  flex: 0 0 auto;
}

.device-row__text {
  flex: 1;
  min-width: 0;
}

.device-row__title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-size: 12.5px;
  font-weight: 600;
  color: var(--ink);
}

.device-row__meta {
  font-size: 11px;
  color: var(--muted);
}

.link-action--danger {
  color: var(--danger);
}
</style>
