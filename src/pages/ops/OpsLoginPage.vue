<script setup lang="ts">
import PortalLogin from '@/components/ui/PortalLogin.vue'
</script>

<template>
  <PortalLogin
    portal="ops"
    title="平台运维登录"
    subtitle="面向系统运维人员的底层维护、权限与审计入口"
    redirect="/ops/workbench"
    :features="['用户权限与 RBAC 角色配置', '物联网设备接入与网关注册', '系统参数、字典与第三方接口管理', '登录日志、操作审计与数据库备份']"
  />
</template>
