/**
 * Nexum UI — Raw CSS tokens as a string.
 * For projects that serve inline HTML (no Tailwind, no build step).
 *
 * Usage:
 *   import { cssTokens } from '@nexum/ui/tokens/css-string'
 *   const html = `<style>${cssTokens}</style>`
 */

import { colors } from './colors.js'
import { shadows } from './shadows.js'
import { radius } from './radius.js'

export const cssTokens = `
:root {
  /* Surfaces */
  --surface-primary: ${colors.dark['surface-primary']};
  --surface-secondary: ${colors.dark['surface-secondary']};
  --surface-tertiary: ${colors.dark['surface-tertiary']};
  --surface-inverse: ${colors.dark['surface-inverse']};

  /* Text */
  --text-primary: ${colors.dark['text-primary']};
  --text-secondary: ${colors.dark['text-secondary']};
  --text-muted: ${colors.dark['text-muted']};
  --text-inverse: ${colors.dark['text-inverse']};

  /* Borders */
  --border-default: ${colors.dark['border-default']};
  --border-subtle: ${colors.dark['border-subtle']};
  --border-strong: ${colors.dark['border-strong']};

  /* Accent */
  --accent: ${colors.dark.accent};
  --accent-hover: ${colors.dark['accent-hover']};
  --accent-text: #ffffff;

  /* Status */
  --success: ${colors.dark.success};
  --warning: ${colors.dark.warning};
  --danger: ${colors.dark.danger};
  --info: ${colors.dark.info};

  /* Radius */
  --radius-card: ${radius.card};
  --radius-button: ${radius.button};
  --radius-input: ${radius.input};
  --radius-pill: ${radius.pill};
  --radius-container: ${radius.container};

  /* Shadows */
  --shadow-card: ${shadows.card};
  --shadow-subtle: ${shadows.subtle};
  --shadow-glow: ${shadows.glow};

  /* Fonts */
  --font-sans: -apple-system, BlinkMacSystemFont, 'Segoe UI', system-ui, sans-serif;
  --font-mono: ui-monospace, 'SF Mono', 'Cascadia Code', monospace;
}

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
body {
  background: var(--surface-primary);
  color: var(--text-primary);
  font-family: var(--font-sans);
  line-height: 1.6;
  -webkit-font-smoothing: antialiased;
}
::-webkit-scrollbar { width: 6px; height: 6px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: var(--surface-tertiary); border-radius: var(--radius-pill); }
::selection { background: rgba(99,102,241,0.3); }
`
