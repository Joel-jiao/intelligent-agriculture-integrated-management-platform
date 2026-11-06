<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import PageHeader from '@/components/ui/PageHeader.vue'
import StatusTag from '@/components/ui/StatusTag.vue'
import { useToast } from '@/composables/useToast'
import { loginLogs, plots, users } from '@/data/mock'
import { formatNumber } from '@/utils/format'

interface LoginDevice {
  id: string
  name: string
  client: string
  ip: string
  time: string
  current: boolean
}

const toast = useToast()

const currentUser = users[0]
const defaultProfile = {
  name: currentUser?.name ?? '李明',
  account: currentUser?.account ?? 'admin',
  role: currentUser?.role ?? '园区管理员',
  phone: '13800000001',
  email: 'liming@yunling-agri.com',
  position: '园区管理员',
  scope: '全部地块',
}

const profile = reactive({ ...defaultProfile })
const avatarText = computed(() => profile.name.slice(0, 1) || '李')
const phoneMasked = computed(() =>
  profile.phone.length >= 11 ? `${profile.phone.slice(0, 3)}****${profile.phone.slice(7)}` : profile.phone,
)
const lastLogin = currentUser?.lastLogin ?? '2026-11-06 09:32'
const createdAt = currentUser?.createdAt ?? '2026-03-01'

const scopeOptions = computed(() => [
  '全部地块',
  ...plots.map((plot) => `${plot.code} · ${plot.name}`),
])

const pwd = reactive({ old: '', next: '', confirm: '' })
const pwdError = ref('')

const prefs = reactive({
  alarmSms: true,
  workOrder: true,
  dailyReport: false,
})

const loginDevices = ref<LoginDevice[]>([
  { id: 'D-01', name: 'Windows 工作站', client: 'Chrome 122 · Windows 11', ip: '192.168.10.22', time: '2026-11-06 09:32', current: true },
  { id: 'D-02', name: 'iPhone 15', client: '飞书内置浏览器 · iOS 18', ip: '10.20.8.42', time: '2026-11-05 18:12', current: false },
  { id: 'D-03', name: 'iPad Air', client: 'Safari · iPadOS 18', ip: '10.20.8.55', time: '2026-11-03 08:26', current: false },
])

const securityLogs = computed(() => loginLogs.filter((item) => item.account === 'admin').slice(0, 5))

function saveProfile() {
  if (!profile.name.trim()) {
    toast.error('请填写姓名')
    return
  }
  if (!/^1\d{10}$/.test(profile.phone)) {
    toast.error('请输入 11 位有效手机号')
    return
  }
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(profile.email)) {
    toast.error('请输入有效的邮箱地址')
    return
  }
  if (!profile.position.trim()) {
    toast.error('请填写岗位')
    return
  }
  toast.success('个人资料已保存，账号信息已同步更新')
}

function resetProfile() {
  Object.assign(profile, defaultProfile)
  pwdError.value = ''
  toast.info('个人资料已恢复为默认值')
}

function changePassword() {
  pwdError.value = ''
  if (!pwd.old) {
    pwdError.value = '请输入原密码'
    toast.error(pwdError.value)
    return
  }
  if (pwd.next.length < 6) {
    pwdError.value = '新密码长度不能少于 6 位'
    toast.error(pwdError.value)
    return
  }
  if (pwd.next !== pwd.confirm) {
    pwdError.value = '两次输入的新密码不一致'
    toast.error(pwdError.value)
    return
  }
  pwd.old = ''
  pwd.next = ''
  pwd.confirm = ''
  toast.success('登录密码已更新，下次登录请使用新密码')
}

function savePrefs() {
  toast.success('消息偏好已保存')
}

function logoutDevice(device: LoginDevice) {
  loginDevices.value = loginDevices.value.filter((item) => item.id !== device.id)
  toast.success(`已退出 ${device.name} 的登录状态`)
}

function bindWechat() {
  toast.info('微信绑定二维码已生成，请使用手机微信扫码确认')
}

function formatRowsCount(value: number): string {
  return formatNumber(value)
}
</script>

<template>
  <div>
    <PageHeader
      eyebrow="ACCOUNT"
      title="个人信息修改"
      description="维护管理员个人资料、安全设置与消息偏好，保障账号与园区数据安全"
    >
      <template #actions>
        <button class="btn" type="button" @click="resetProfile">恢复默认</button>
        <button class="btn btn--primary" type="button" @click="saveProfile">保存资料</button>
      </template>
    </PageHeader>

    <div class="grid grid--sidebar">
      <div class="stack">
        <section class="card">
          <div class="profile-hero">
            <div class="avatar avatar--xl">{{ avatarText }}</div>
            <div>
              <div style="font-size: 18px; font-weight: 700">{{ profile.name }}</div>
              <div style="font-size: 12px; color: var(--muted)">{{ profile.role }} · {{ profile.account }}</div>
              <div class="row wrap" style="gap: 6px; margin-top: 8px">
                <StatusTag text="账号启用" tone="ok" dot />
                <span class="tag tag--brand">{{ profile.scope }}</span>
              </div>
            </div>
          </div>
          <div class="card__body" style="padding-top: 8px">
            <div class="kv">
              <div class="kv__item"><span>最近登录</span><b>{{ lastLogin }}</b></div>
              <div class="kv__item"><span>账号创建</span><b>{{ createdAt }}</b></div>
              <div class="kv__item"><span>手机号</span><b>{{ phoneMasked }}</b></div>
              <div class="kv__item"><span>邮箱</span><b>{{ profile.email }}</b></div>
            </div>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">账号绑定</div>
            <span class="tag tag--brand">安全等级 高</span>
          </div>
          <div class="card__body bind-list">
            <div class="bind-row">
              <div>
                <b>手机号</b>
                <span>{{ phoneMasked }}</span>
              </div>
              <StatusTag text="已绑定" tone="ok" />
            </div>
            <div class="bind-row">
              <div>
                <b>邮箱</b>
                <span>{{ profile.email }}</span>
              </div>
              <StatusTag text="已绑定" tone="ok" />
            </div>
            <div class="bind-row">
              <div>
                <b>微信</b>
                <span>用于接收告警与工单通知</span>
              </div>
              <div class="row" style="gap: 8px">
                <StatusTag text="未绑定" tone="mute" />
                <button class="link-action" type="button" @click="bindWechat">立即绑定</button>
              </div>
            </div>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">登录设备 <span class="card__sub">{{ loginDevices.length }} 台</span></div>
          </div>
          <div class="card__body device-list">
            <div v-for="device in loginDevices" :key="device.id" class="device-row">
              <div class="device-row__body">
                <div class="device-row__name">
                  {{ device.name }}
                  <span v-if="device.current" class="tag tag--brand">当前设备</span>
                </div>
                <div class="device-row__meta">{{ device.client }} · {{ device.ip }} · {{ device.time }}</div>
              </div>
              <button v-if="!device.current" class="link-action" type="button" @click="logoutDevice(device)">退出登录</button>
            </div>
            <div v-if="loginDevices.length === 0" class="empty">
              <div class="empty__mark">设</div>
              <span>暂无其他登录设备</span>
            </div>
          </div>
        </section>
      </div>

      <div class="stack">
        <section class="card">
          <div class="card__head">
            <div class="card__title">个人资料</div>
            <span class="tag tag--outline">管理员档案</span>
          </div>
          <div class="card__body">
            <div class="form-grid">
              <label class="field">
                <span class="field__label">姓名</span>
                <input v-model="profile.name" class="input" type="text" placeholder="请输入姓名" />
              </label>
              <label class="field">
                <span class="field__label">登录账号</span>
                <input v-model="profile.account" class="input" type="text" disabled />
              </label>
              <label class="field">
                <span class="field__label">手机号</span>
                <input v-model="profile.phone" class="input" type="tel" maxlength="11" placeholder="请输入手机号" />
              </label>
              <label class="field">
                <span class="field__label">邮箱</span>
                <input v-model="profile.email" class="input" type="email" placeholder="请输入邮箱" />
              </label>
              <label class="field">
                <span class="field__label">岗位</span>
                <input v-model="profile.position" class="input" type="text" placeholder="如 园区管理员" />
              </label>
              <label class="field">
                <span class="field__label">地块负责范围</span>
                <select v-model="profile.scope" class="select">
                  <option v-for="item in scopeOptions" :key="item" :value="item">{{ item }}</option>
                </select>
              </label>
              <div class="field span-2">
                <span class="field__label">角色权限</span>
                <div class="notice notice--brand">
                  当前角色为{{ profile.role }}，拥有综合看板、物联网、农事、溯源、GIS、告警与报表等模块权限。
                </div>
              </div>
            </div>
            <div class="form-foot">
              <button class="btn" type="button" @click="resetProfile">取消</button>
              <button class="btn btn--primary" type="button" @click="saveProfile">保存修改</button>
            </div>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">安全设置 <span class="card__sub">修改登录密码</span></div>
          </div>
          <div class="card__body">
            <div class="form-grid">
              <label class="field span-2">
                <span class="field__label">原密码</span>
                <input v-model="pwd.old" class="input" type="password" placeholder="请输入当前登录密码" autocomplete="current-password" />
              </label>
              <label class="field">
                <span class="field__label">新密码</span>
                <input v-model="pwd.next" class="input" type="password" placeholder="不少于 6 位" autocomplete="new-password" />
              </label>
              <label class="field">
                <span class="field__label">确认新密码</span>
                <input v-model="pwd.confirm" class="input" type="password" placeholder="再次输入新密码" autocomplete="new-password" />
              </label>
              <div v-if="pwdError" class="field span-2">
                <div class="notice notice--danger">{{ pwdError }}</div>
              </div>
            </div>
            <div class="form-foot">
              <button class="btn btn--primary" type="button" @click="changePassword">修改密码</button>
            </div>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">消息偏好</div>
            <button class="link-action" type="button" @click="savePrefs">保存偏好</button>
          </div>
          <div class="card__body pref-list">
            <div class="pref-row">
              <div>
                <b>告警短信</b>
                <span>紧急与重要告警通过短信即时推送</span>
              </div>
              <label class="switch">
                <input v-model="prefs.alarmSms" type="checkbox" />
                <span class="switch__track" />
              </label>
            </div>
            <div class="pref-row">
              <div>
                <b>工单提醒</b>
                <span>新工单派发、超时未完成时提醒</span>
              </div>
              <label class="switch">
                <input v-model="prefs.workOrder" type="checkbox" />
                <span class="switch__track" />
              </label>
            </div>
            <div class="pref-row">
              <div>
                <b>日报推送</b>
                <span>每日 08:00 推送园区运营日报</span>
              </div>
              <label class="switch">
                <input v-model="prefs.dailyReport" type="checkbox" />
                <span class="switch__track" />
              </label>
            </div>
          </div>
        </section>

        <section class="card">
          <div class="card__head">
            <div class="card__title">最近安全记录</div>
            <span class="tag tag--outline">仅展示本账号</span>
          </div>
          <div class="table-wrap" style="border: 0; border-radius: 0 0 14px 14px; margin-top: 14px">
            <table class="data-table">
              <thead>
                <tr>
                  <th>操作</th>
                  <th>时间</th>
                  <th>IP 地址</th>
                  <th>结果</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="log in securityLogs" :key="log.id">
                  <td>{{ log.action }}<span class="cell-muted"> · {{ log.module }}</span></td>
                  <td class="num">{{ log.time }}</td>
                  <td class="num">{{ log.ip }}</td>
                  <td><StatusTag :text="log.result" :tone="log.result === '成功' ? 'ok' : 'danger'" dot /></td>
                </tr>
                <tr v-if="securityLogs.length === 0">
                  <td colspan="4">
                    <div class="empty">
                      <div class="empty__mark">安</div>
                      <span>暂无安全记录</span>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="card__footer" style="padding-top: 10px">
            <span class="cell-muted" style="font-size: 11.5px">共 {{ formatRowsCount(securityLogs.length) }} 条记录，异常登录请及时修改密码</span>
          </div>
        </section>
      </div>
    </div>
  </div>
</template>

<style scoped>
.profile-hero {
  display: flex;
  align-items: center;
  gap: 15px;
  padding: 18px;
  border-bottom: 1px solid var(--line);
  background: linear-gradient(160deg, var(--brand-softer), #fff 78%);
  border-radius: 14px 14px 0 0;
}

.bind-list,
.device-list,
.pref-list {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.bind-row,
.device-row,
.pref-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 11px 0;
  border-bottom: 1px dashed var(--line);
}

.bind-row:last-child,
.device-row:last-child,
.pref-row:last-child {
  border-bottom: 0;
}

.bind-row b,
.pref-row b {
  display: block;
  font-size: 12.5px;
  font-weight: 600;
  color: var(--ink);
}

.bind-row span,
.pref-row span {
  display: block;
  margin-top: 1px;
  font-size: 11px;
  color: var(--muted);
}

.device-row__body {
  min-width: 0;
}

.device-row__name {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 12.5px;
  font-weight: 600;
  color: var(--ink);
}

.device-row__meta {
  margin-top: 2px;
  font-size: 10.5px;
  color: var(--faint);
}

.profile-hero + .card__body {
  padding-top: 12px;
}
</style>
