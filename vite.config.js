import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import path from 'path'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 3000,
    host: true,
    // HMR réactivé (local)
    hmr: true,
    watch: {
      usePolling: false, // Désactivé en local pour meilleures performances
    },
  },
  preview: {
    port: 3000,
    host: true,
  },
  build: {
    sourcemap: true,
    // Optimisation des chunks pour le caching
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom', 'react-router-dom']
        }
      }
    },
    // Optimisations supplémentaires
    chunkSizeWarningLimit: 1000,
    minify: 'esbuild',
  },
  // Optimisation des dépendances
  optimizeDeps: {
    include: ['react', 'react-dom', 'react-router-dom'],
  },
})

