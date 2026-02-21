/**
 * Color presets for @nexum/ui
 * Each preset overrides the accent + optional surface tweaks.
 * Inspired by top Product Hunt winners' color palettes.
 */

export interface ColorPreset {
  name: string
  label: string
  accent: string
  accentHover: string
  /** Text color on accent backgrounds (buttons, badges). Defaults to #fff. */
  accentText?: string
  /** Optional surface overrides */
  surfacePrimary?: string
  surfaceSecondary?: string
  surfaceTertiary?: string
  /** Optional text overrides */
  textPrimary?: string
  /** Optional glow color */
  glowColor?: string
}

export const presets: Record<string, ColorPreset> = {
  indigo: {
    name: 'indigo',
    label: 'Indigo',
    accent: '#6366f1',
    accentHover: '#818cf8',
    glowColor: 'hsla(249, 91%, 77%, 0.1)',
  },
  coral: {
    name: 'coral',
    label: 'Coral',
    accent: '#FF6363',
    accentHover: '#FF7F7F',
    glowColor: 'hsla(0, 100%, 77%, 0.1)',
  },
  emerald: {
    name: 'emerald',
    label: 'Emerald',
    accent: '#10b981',
    accentHover: '#34d399',
    glowColor: 'hsla(160, 84%, 60%, 0.1)',
  },
  amber: {
    name: 'amber',
    label: 'Amber',
    accent: '#f59e0b',
    accentHover: '#fbbf24',
    glowColor: 'hsla(38, 92%, 60%, 0.1)',
  },
  violet: {
    name: 'violet',
    label: 'Violet',
    accent: '#8b5cf6',
    accentHover: '#a78bfa',
    glowColor: 'hsla(263, 90%, 70%, 0.1)',
  },
  cyan: {
    name: 'cyan',
    label: 'Cyan',
    accent: '#06b6d4',
    accentHover: '#22d3ee',
    glowColor: 'hsla(188, 95%, 50%, 0.1)',
  },
  mono: {
    name: 'mono',
    label: 'Mono',
    accent: '#fafafa',
    accentHover: '#d4d4d8',
    accentText: '#09090b',
    glowColor: 'hsla(0, 0%, 100%, 0.05)',
  },
  'tech-noir': {
    name: 'tech-noir',
    label: 'Tech Noir',
    accent: '#fafafa',
    accentHover: '#e4e4e7',
    accentText: '#000000',
    surfacePrimary: '#000000',
    surfaceSecondary: '#0a0a0a',
    surfaceTertiary: '#141414',
    glowColor: 'hsla(0, 0%, 100%, 0.03)',
  },
  openclaw: {
    name: 'openclaw',
    label: 'OpenClaw',
    accent: '#FF4D4D',
    accentHover: '#FF6B6B',
    glowColor: 'hsla(0, 100%, 65%, 0.12)',
  },
  linear: {
    name: 'linear',
    label: 'Linear',
    accent: '#4354B8',
    accentHover: '#5B6BC9',
    glowColor: 'hsla(231, 50%, 55%, 0.1)',
  },
  bolt: {
    name: 'bolt',
    label: 'Bolt',
    accent: '#1488FC',
    accentHover: '#42A0FD',
    glowColor: 'hsla(210, 97%, 55%, 0.1)',
  },
}

export const presetNames = Object.keys(presets) as (keyof typeof presets)[]
