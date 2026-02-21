import { defineConfig } from 'tsup'

export default defineConfig([
  // Component library bundle
  {
    entry: {
      index: 'src/index.ts',
    },
    format: ['esm', 'cjs'],
    dts: true,
    sourcemap: true,
    clean: true,
    treeshake: true,
    splitting: false,
    external: ['react', 'react-dom', 'tailwindcss'],
    // Add "use client" for React Server Component compatibility
    esbuildOptions(options) {
      options.banner = {
        js: '"use client";',
      }
    },
  },
  // Tailwind preset (no React banner needed)
  {
    entry: {
      'tailwind-preset': 'tailwind.config.ts',
    },
    format: ['esm', 'cjs'],
    dts: true,
    sourcemap: false,
    clean: false,
    splitting: false,
    external: ['tailwindcss'],
  },
])
