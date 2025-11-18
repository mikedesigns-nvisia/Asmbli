import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { resolve } from 'path'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  build: {
    rollupOptions: {
      input: {
        plugin: resolve(__dirname, 'src/plugin.ts'),
        index: resolve(__dirname, 'index.html'),
      },
      output: {
        entryFileNames: '[name].js',
      },
    },
  },
})
