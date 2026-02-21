#!/usr/bin/env node
/**
 * Generate standalone tokens.css from TypeScript token definitions.
 * Output: dist/tokens.css — importable by any HTML page via <link>.
 */
import { colors } from '../src/tokens/colors.js';
import { shadows } from '../src/tokens/shadows.js';
import { radius } from '../src/tokens/radius.js';

const SPACING_SCALE = [0, 1, 2, 4, 6, 8, 10, 12, 16, 20, 24, 32];

const css = `/* ═══════════════════════════════════════════════════════════
 * @nexum/ui — Design Tokens (auto-generated, do not edit)
 * Dark-mode-first · Framework-agnostic
 * ═══════════════════════════════════════════════════════════ */

:root {
  /* ── Surfaces ── */
  --surface-primary: ${colors.dark['surface-primary']};
  --surface-secondary: ${colors.dark['surface-secondary']};
  --surface-tertiary: ${colors.dark['surface-tertiary']};
  --surface-inverse: ${colors.dark['surface-inverse']};

  /* ── Text ── */
  --text-primary: ${colors.dark['text-primary']};
  --text-secondary: ${colors.dark['text-secondary']};
  --text-muted: ${colors.dark['text-muted']};
  --text-inverse: ${colors.dark['text-inverse']};

  /* ── Borders ── */
  --border-default: ${colors.dark['border-default']};
  --border-subtle: ${colors.dark['border-subtle']};
  --border-strong: ${colors.dark['border-strong']};

  /* ── Accent ── */
  --accent: ${colors.dark.accent};
  --accent-hover: ${colors.dark['accent-hover']};
  --accent-text: #ffffff;

  /* ── Status ── */
  --success: ${colors.dark.success};
  --warning: ${colors.dark.warning};
  --danger: ${colors.dark.danger};
  --info: ${colors.dark.info};

  /* ── Radius ── */
  --radius-sm: 6px;
  --radius-md: 10px;
  --radius-lg: 14px;
  --radius-card: ${radius.card};
  --radius-button: ${radius.button};
  --radius-input: ${radius.input};
  --radius-pill: ${radius.pill};
  --radius-container: ${radius.container};

  /* ── Shadows ── */
  --shadow-card: ${shadows.card};
  --shadow-subtle: ${shadows.subtle};
  --shadow-glow: ${shadows.glow};

  /* ── Spacing scale ── */
${SPACING_SCALE.map(v => `  --space-${v}: ${v * 4}px;`).join('\n')}

  /* ── Fonts ── */
  --font-sans: system-ui, -apple-system, 'Segoe UI', sans-serif;
  --font-mono: ui-monospace, 'SF Mono', 'Cascadia Code', monospace;
}

/* ── Light mode ── */
@media (prefers-color-scheme: light) {
  :root:not([data-theme="dark"]) {
    --surface-primary: ${colors.light['surface-primary']};
    --surface-secondary: ${colors.light['surface-secondary']};
    --surface-tertiary: ${colors.light['surface-tertiary']};
    --surface-inverse: ${colors.light['surface-inverse']};
    --text-primary: ${colors.light['text-primary']};
    --text-secondary: ${colors.light['text-secondary']};
    --text-muted: ${colors.light['text-muted']};
    --text-inverse: ${colors.light['text-inverse']};
    --border-default: ${colors.light['border-default']};
    --border-subtle: ${colors.light['border-subtle']};
    --border-strong: ${colors.light['border-strong']};
    --accent: ${colors.light.accent};
    --accent-hover: ${colors.light['accent-hover']};
    --success: ${colors.light.success};
    --warning: ${colors.light.warning};
    --danger: ${colors.light.danger};
    --info: ${colors.light.info};
  }
}

/* ── Force dark ── */
[data-theme="dark"] {
  --surface-primary: ${colors.dark['surface-primary']};
  --surface-secondary: ${colors.dark['surface-secondary']};
  --surface-tertiary: ${colors.dark['surface-tertiary']};
  --surface-inverse: ${colors.dark['surface-inverse']};
  --text-primary: ${colors.dark['text-primary']};
  --text-secondary: ${colors.dark['text-secondary']};
  --text-muted: ${colors.dark['text-muted']};
  --text-inverse: ${colors.dark['text-inverse']};
  --border-default: ${colors.dark['border-default']};
  --border-subtle: ${colors.dark['border-subtle']};
  --border-strong: ${colors.dark['border-strong']};
  --accent: ${colors.dark.accent};
  --accent-hover: ${colors.dark['accent-hover']};
  --success: ${colors.dark.success};
  --warning: ${colors.dark.warning};
  --danger: ${colors.dark.danger};
  --info: ${colors.dark.info};
}

/* ── Base reset ── */
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

body {
  background: var(--surface-primary);
  color: var(--text-primary);
  font-family: var(--font-sans);
  line-height: 1.5;
  -webkit-font-smoothing: antialiased;
}

::-webkit-scrollbar { width: 6px; height: 6px; }
::-webkit-scrollbar-track { background: transparent; }
::-webkit-scrollbar-thumb { background: var(--surface-tertiary); border-radius: var(--radius-pill); }
::selection { background: rgba(99, 102, 241, 0.3); }
`;

import * as fs from 'node:fs';
import * as path from 'node:path';

const outDir = path.resolve(import.meta.dirname, '..', 'dist');
if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });
fs.writeFileSync(path.join(outDir, 'tokens.css'), css);
console.log(`✅ dist/tokens.css generated (${css.length} bytes)`);
