/**
 * Nexum UI — Semantic Color Tokens
 * Dark-mode-first design system colors.
 */

export const colors = {
  dark: {
    // Surfaces
    'surface-primary': '#09090b',
    'surface-secondary': '#141416',
    'surface-tertiary': '#1e1e21',
    'surface-inverse': '#fafafa',

    // Text
    'text-primary': '#fafafa',
    'text-secondary': '#a1a1aa',
    'text-muted': '#52525b',
    'text-inverse': '#09090b',

    // Borders
    'border-default': 'rgba(255,255,255,0.12)',
    'border-subtle': 'rgba(255,255,255,0.08)',
    'border-strong': 'rgba(255,255,255,0.22)',

    // Accent
    accent: '#6366f1',
    'accent-hover': '#818cf8',

    // Semantic
    success: '#22c55e',
    warning: '#f59e0b',
    danger: '#ef4444',
    info: '#3b82f6',
  },

  light: {
    // Surfaces
    'surface-primary': '#ffffff',
    'surface-secondary': '#f4f4f5',
    'surface-tertiary': '#e4e4e7',
    'surface-inverse': '#09090b',

    // Text
    'text-primary': '#09090b',
    'text-secondary': '#52525b',
    'text-muted': '#a1a1aa',
    'text-inverse': '#fafafa',

    // Borders
    'border-default': 'rgba(0,0,0,0.10)',
    'border-subtle': 'rgba(0,0,0,0.06)',
    'border-strong': 'rgba(0,0,0,0.20)',

    // Accent
    accent: '#6366f1',
    'accent-hover': '#4f46e5',

    // Semantic
    success: '#16a34a',
    warning: '#d97706',
    danger: '#dc2626',
    info: '#2563eb',
  },

  // ─── Accent text ────────────────────────────────────────────────────────────
  // Text color on solid accent backgrounds (buttons, filled badges).
  // Points to the --accent-text CSS variable so applyPreset() can override it
  // at runtime (e.g. mono preset uses #09090b — dark text on white accent).
  accentText: 'var(--accent-text)',
} as const

export type ColorToken = keyof typeof colors.dark
