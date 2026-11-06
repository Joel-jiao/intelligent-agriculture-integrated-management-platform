<template>
  <footer class="app-footer">
    <div class="app-footer__inner">
      <span>© {{ new Date().getFullYear() }} Tamplate by 249980937吴鸿宇 </span>
    </div>
  </footer>
</template>

<style scoped>
.app-footer {
  border-top: 1px solid var(--color-border);
  background-color: var(--color-background);
}

.app-footer__inner {
  display: flex;
  align-items: center;
  justify-content: center;
  max-width: 1280px;
  margin: 0 auto;
  padding: 1.5rem 2rem;
  font-size: 0.875rem;
  color: var(--color-text);
}
</style>
