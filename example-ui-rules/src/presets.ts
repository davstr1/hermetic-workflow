/**
 * Nexum UI — Runtime Preset System
 *
 * Presets override CSS custom properties on document.documentElement,
 * enabling live theme switching without a rebuild.
 *
 * Usage:
 *   import { applyPreset } from '@nexum/ui'
 *   applyPreset('coral')          // switches to Coral theme
 *   applyPreset('tech-noir')      // switches to Tech Noir
 */

export { presets, presetNames } from './tokens/presets'
export type { ColorPreset } from './tokens/presets'

import { presets, presetNames } from './tokens/presets'

/**
 * Apply a named preset at runtime by setting CSS custom properties on
 * document.documentElement. Safe to call on every render or on user action.
 *
 * @param name - Preset key (e.g. 'indigo', 'coral', 'tech-noir')
 */
export function applyPreset(name: string): void {
  const preset = presets[name]

  if (!preset) {
    console.warn(
      `[nexum/ui] Unknown preset: "${name}". Available: ${presetNames.join(', ')}`
    )
    return
  }

  const root = document.documentElement

  // Core accent
  root.style.setProperty('--accent', preset.accent)
  root.style.setProperty('--accent-hover', preset.accentHover)

  // Text on accent backgrounds (defaults to white if not specified)
  root.style.setProperty('--accent-text', preset.accentText ?? '#ffffff')

  // Optional surface overrides
  if (preset.surfacePrimary) {
    root.style.setProperty('--surface-primary', preset.surfacePrimary)
  } else {
    root.style.removeProperty('--surface-primary')
  }

  if (preset.surfaceSecondary) {
    root.style.setProperty('--surface-secondary', preset.surfaceSecondary)
  } else {
    root.style.removeProperty('--surface-secondary')
  }

  if (preset.surfaceTertiary) {
    root.style.setProperty('--surface-tertiary', preset.surfaceTertiary)
  } else {
    root.style.removeProperty('--surface-tertiary')
  }

  // Optional text overrides
  if (preset.textPrimary) {
    root.style.setProperty('--text-primary', preset.textPrimary)
  } else {
    root.style.removeProperty('--text-primary')
  }

  // Glow color (used in shadow-glow and focus rings)
  if (preset.glowColor) {
    root.style.setProperty('--glow-color', preset.glowColor)
  } else {
    root.style.removeProperty('--glow-color')
  }
}

/**
 * Reset all preset overrides back to the design system defaults.
 */
export function resetPreset(): void {
  const root = document.documentElement
  const props = [
    '--accent',
    '--accent-hover',
    '--accent-text',
    '--surface-primary',
    '--surface-secondary',
    '--surface-tertiary',
    '--text-primary',
    '--glow-color',
  ]
  for (const prop of props) {
    root.style.removeProperty(prop)
  }
}
