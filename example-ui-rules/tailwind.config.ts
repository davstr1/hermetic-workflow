/**
 * Nexum UI — Tailwind Preset
 *
 * Import in consumer projects:
 *   import nexumPreset from '@nexum/ui/tailwind-preset'
 *   export default { presets: [nexumPreset], content: [...] }
 */

import type { Config } from 'tailwindcss'
import plugin from 'tailwindcss/plugin'
import { colors } from './src/tokens/colors'
import { shadows } from './src/tokens/shadows'
import { radius } from './src/tokens/radius'

const nexumPreset: Partial<Config> = {
  darkMode: 'class',
  theme: {
    // ─── Restricted spacing scale ─────────────────────────────────────────
    // Only allow values from the design system. Arbitrary spacing is banned
    // by the @nexum/consistent-spacing eslint rule.
    spacing: {
      '0': '0px',
      '1': '0.25rem',
      '2': '0.5rem',
      '4': '1rem',
      '6': '1.5rem',
      '8': '2rem',
      '10': '2.5rem',
      '12': '3rem',
      '16': '4rem',
      '20': '5rem',
      '24': '6rem',
      '32': '8rem',
    },
    extend: {
      colors: {
        // Dark mode tokens (default — we're dark-first)
        'surface-primary': {
          DEFAULT: colors.dark['surface-primary'],
          light: colors.light['surface-primary'],
        },
        'surface-secondary': {
          DEFAULT: colors.dark['surface-secondary'],
          light: colors.light['surface-secondary'],
        },
        'surface-tertiary': {
          DEFAULT: colors.dark['surface-tertiary'],
          light: colors.light['surface-tertiary'],
        },
        'surface-inverse': {
          DEFAULT: colors.dark['surface-inverse'],
          light: colors.light['surface-inverse'],
        },
        'text-primary': {
          DEFAULT: colors.dark['text-primary'],
          light: colors.light['text-primary'],
        },
        'text-secondary': {
          DEFAULT: colors.dark['text-secondary'],
          light: colors.light['text-secondary'],
        },
        'text-muted': {
          DEFAULT: colors.dark['text-muted'],
          light: colors.light['text-muted'],
        },
        'text-inverse': {
          DEFAULT: colors.dark['text-inverse'],
          light: colors.light['text-inverse'],
        },
        'border-default': {
          DEFAULT: colors.dark['border-default'],
          light: colors.light['border-default'],
        },
        'border-subtle': {
          DEFAULT: colors.dark['border-subtle'],
          light: colors.light['border-subtle'],
        },
        'border-strong': {
          DEFAULT: colors.dark['border-strong'],
          light: colors.light['border-strong'],
        },
        accent: {
          DEFAULT: colors.dark['accent'],
          hover: colors.dark['accent-hover'],
        },
        success: {
          DEFAULT: colors.dark['success'],
          light: colors.light['success'],
        },
        warning: {
          DEFAULT: colors.dark['warning'],
          light: colors.light['warning'],
        },
        danger: {
          DEFAULT: colors.dark['danger'],
          light: colors.light['danger'],
        },
        info: {
          DEFAULT: colors.dark['info'],
          light: colors.light['info'],
        },
        // ─── Accent text ──────────────────────────────────────────────────
        // Text color on accent backgrounds. Controlled by --accent-text CSS var.
        // Presets override this (e.g. mono preset uses #09090b for dark text on white).
        'accent-text': colors.accentText,
      },

      borderRadius: {
        card: radius.card,
        button: radius.button,
        input: radius.input,
        pill: radius.pill,
        container: radius.container,
      },

      boxShadow: {
        card: shadows.card,
        subtle: shadows.subtle,
        glow: shadows.glow,
      },

      fontFamily: {
        sans: [
          'Inter',
          'ui-sans-serif',
          'system-ui',
          '-apple-system',
          'BlinkMacSystemFont',
          '"Segoe UI"',
          'Roboto',
          '"Helvetica Neue"',
          'Arial',
          '"Noto Sans"',
          'sans-serif',
        ],
        mono: [
          '"JetBrains Mono"',
          '"Fira Code"',
          'ui-monospace',
          'SFMono-Regular',
          '"SF Mono"',
          'Menlo',
          'Monaco',
          'Consolas',
          '"Liberation Mono"',
          '"Courier New"',
          'monospace',
        ],
      },
    },
  },
  plugins: [
    // Inject --accent-text default into :root so it works without applyPreset()
    plugin(({ addBase }) => {
      addBase({
        ':root': {
          '--accent-text': '#ffffff',
          '--accent': colors.dark['accent'],
          '--accent-hover': colors.dark['accent-hover'],
          '--glow-color': 'hsla(249, 91%, 77%, 0.1)',
        },
      })
    }),
  ],
}

export default nexumPreset

// Re-export presets so consumers can import them from the tailwind-preset entry:
//   import nexumPreset, { presets } from '@nexum/ui/tailwind-preset'
export { presets, presetNames } from './src/tokens/presets'
export type { ColorPreset } from './src/tokens/presets'
