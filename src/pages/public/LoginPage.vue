<script setup lang="ts">
import PortalLogin from '@/components/ui/PortalLogin.vue'
</script>

<template>
  <PortalLogin
    portal="admin"
    title="园区业务管理登录"
    subtitle="面向园区管理员的业务运营、设备控制与农事管理入口"
    redirect="/dashboard"
    :features="['物联网环境监测与设备远程控制', '农事工单派发与执行闭环', '农产品质量溯源与召回管理', 'GIS 地图分析与可视化指挥大屏']"
  />
</template>
