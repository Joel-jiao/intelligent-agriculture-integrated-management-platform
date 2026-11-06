<script setup lang="ts">
import PortalLogin from '@/components/ui/PortalLogin.vue'
</script>

<template>
  <PortalLogin
    portal="sup"
    title="监管端登录"
    subtitle="面向政府农业监管部门的辖区质量安全数据查询入口"
    redirect="/sup/overview"
    :features="['辖区农产品质量安全总览', '农产品全流程溯源台账查询', '农药农资使用记录合规核查', '异常预警管理与监管报表导出']"
  />
</template>
