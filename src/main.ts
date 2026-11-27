import './assets/main.css'

import { createApp } from 'vue'
// 按需显式注册项目实际使用的 AntD 组件：
// 未注册的组件不会进入产物（ant-design-vue es 模块支持摇树），
// 后续页面逐步接入 antd 时，在此追加即可。
import {
  Alert,
  App as AntdApp,
  Button,
  Card,
  ConfigProvider,
  Form,
  Input,
  Modal,
  Pagination,
  Result,
  Spin,
  Statistic,
  Tag,
} from 'ant-design-vue'
import 'ant-design-vue/dist/reset.css'
// antd 内部样式覆盖（统一收敛到独立 CSS 文件，避免 .vue 内样式块的 IDE 误报）
import './assets/antd-overrides.css'
// GIS 底图（Leaflet）样式与项目皮肤
import 'leaflet/dist/leaflet.css'
import './assets/leaflet-overrides.css'
import App from './App.vue'
import router from './router'
import { initTheme } from './composables/useTheme'

initTheme()

createApp(App)
  .use(ConfigProvider)
  .use(AntdApp)
  .use(Modal)
  .use(Pagination)
  .use(Tag)
  .use(Card)
  .use(Statistic)
  .use(Alert)
  .use(Result)
  .use(Spin)
  .use(Button)
  .use(Form)
  .use(Input)
  .use(router)
  .mount('#app')
