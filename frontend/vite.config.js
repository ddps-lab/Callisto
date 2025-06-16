import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';
import tailwindcss from '@tailwindcss/vite';
import process from 'node:process';

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');

  const config = {
    plugins: [react(), tailwindcss()]
  };

  if (mode === 'development') {
    config.server = {
      proxy: {
        '/api': env.VITE_CF_URL
      }
    };
  }

  return config;
});
