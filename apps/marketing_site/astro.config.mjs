import { defineConfig } from 'astro/config';

// Astro config for Sunil Trading Company marketing site.
// Per M5.1: pure static HTML+CSS output, <100KB bundle.
// Deployed to Firebase Hosting at sunil-trading-company.yugmalabs.ai.
export default defineConfig({
  site: 'https://sunil-trading-company.yugmalabs.ai',
  output: 'static',
  build: {
    // Inline small CSS to reduce requests.
    inlineStylesheets: 'auto',
  },
});
