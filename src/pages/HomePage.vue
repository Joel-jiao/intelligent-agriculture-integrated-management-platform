<script setup lang="ts"></script>

<template>
  <section class="home">
    <h1 class="home__title">主页</h1>
    <p class="home__desc">欢迎使用 Tamplate，这里可以开始搭建你的页面内容。</p>
  </section>
</template>

<style scoped>
.home {
  max-width: 1280px;
  margin: 0 auto;
  padding: 4rem 2rem;
}

.home__title {
  font-size: 2rem;
  font-weight: 700;
  color: var(--color-heading);
  margin-bottom: 1rem;
}

.home__desc {
  color: var(--color-text);
  line-height: 1.6;
}
</style>
