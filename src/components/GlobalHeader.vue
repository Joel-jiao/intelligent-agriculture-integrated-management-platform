<script setup lang="ts">
import { RouterLink } from 'vue-router'
</script>

<template>
  <header class="app-header">
    <div class="app-header__inner">
      <RouterLink to="/" class="app-header__logo">Tamplate</RouterLink>
      <nav class="app-header__nav">
        <RouterLink to="/">首页</RouterLink>
      </nav>
    </div>
  </header>
</template>

<style scoped>
.app-header {
  border-bottom: 1px solid var(--color-border);
  background-color: var(--color-background);
}

.app-header__inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  max-width: 1280px;
  margin: 0 auto;
  padding: 0 2rem;
  height: 60px;
}

.app-header__logo {
  font-size: 1.25rem;
  font-weight: 700;
  color: var(--color-heading);
  text-decoration: none;
}

.app-header__nav {
  display: flex;
  gap: 1.5rem;
}

.app-header__nav a {
  color: var(--color-text);
  text-decoration: none;
  transition: color 0.3s;
}

.app-header__nav a:hover,
.app-header__nav a.router-link-active {
  color: hsla(160, 100%, 37%, 1);
}
</style>
