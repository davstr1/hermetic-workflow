#!/usr/bin/env node
/**
 * nexum-lint — Universal design system enforcer for @nexum/ui.
 * 
 * One tool, all rules, all file types. No framework dependency.
 * Scans .ts, .tsx, .js, .html, .css — enforces everywhere.
 * 
 * Rules:
 *   1. no-raw-colors     — CSS: ban hex/rgb/hsl, force var(--token)
 *   2. spacing-scale      — CSS: ban off-scale px values
 *   3. no-emoji-in-ui     — All: ban emoji in UI-facing code
 *   4. no-ai-slop         — All: ban corporate filler phrases
 *   5. no-placeholder     — All: ban lorem ipsum, example.com, etc.
 *   6. no-ai-comments     — JS/TS: ban "this function handles..." comments
 * 
 * Usage:
 *   npx nexum-lint                    # auto-detect files
 *   npx nexum-lint src/dashboard.ts   # specific file
 */
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

// ═══════════════════════════════════════════════════════════════════════════
// RULES — direct scan, no framework needed
// ═══════════════════════════════════════════════════════════════════════════

// Emoji ranges — excludes common typographic symbols (✓✗✕✔✖ arrows dingbats)
// that are legitimate in CSS content properties
const EMOJI_RE = /[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{FE00}-\u{FE0F}\u{1FA00}-\u{1FA9F}\u{1FAA0}-\u{1FAFF}]/u;

const PLACEHOLDER_PATTERNS = [
  'lorem ipsum', 'example.com', 'john@example',
  'your title here', 'description goes here',
  'via.placeholder.com', 'picsum.photos', 'jane doe', 'john doe',
  'foo bar', 'test@test', 'acme corp', 'your name here',
  'content goes here', 'add your',
];

const AI_COMMENT_PATTERNS = [
  /^\/\/\s*this (?:component|function|hook|module|file) (?:renders?|handles?|is responsible|manages?|creates?|defines?)/i,
  /^\/\/\s*here we (?:handle|define|create|render|manage|set up)/i,
  /^\/\/\s*the following (?:code|function|component|section)/i,
  /^\/\/\s*we need to/i,
  /^\/\/\s*this is (?:the|a|an|where)/i,
  /^\/\/\s*import(?:ing)? (?:the|all|necessary)/i,
  /^\/\/\s*(?:first|next|then|finally),? we/i,
  /^\/\/\s*set(?:ting)? up the/i,
];

// Load banlist
let slopBanlist = [];
try {
  const banlistPath = path.resolve(__dirname, '..', '..', 'frontend-specs', 'banlists', 'ai-slop.txt');
  if (fs.existsSync(banlistPath)) {
    slopBanlist = fs.readFileSync(banlistPath, 'utf8')
      .split('\n').map(l => l.trim()).filter(l => l && !l.startsWith('#'));
  }
} catch {}
if (slopBanlist.length === 0) {
  slopBanlist = [
    "we're thrilled", "don't hesitate", "groundbreaking", "seamless", "delve",
    "leveraging", "cutting-edge", "game-changing", "revolutionary", "state-of-the-art",
    "best-in-class", "unlock the full potential", "take it to the next level",
    "empower", "streamline", "synergy", "paradigm", "robust", "scalable solution",
    "elevate your", "supercharge your", "turbocharge", "unleash", "deep dive",
    "holistic", "ecosystem", "harness the power", "bridge the gap",
  ];
}
const slopLower = slopBanlist.map(b => b.toLowerCase());

// Tailwind raw color classes
const TAILWIND_RAW_COLOR_RE = /(?:^|\s)(?:bg|text|border|ring|outline|decoration|shadow|divide|from|via|to)-(?:gray|zinc|slate|neutral|stone|blue|red|green|yellow|purple|pink|orange|indigo|violet|emerald|teal|cyan|amber|lime|rose|fuchsia|sky)-\d{1,3}(?:\/\d+)?/g;

// ═══════════════════════════════════════════════════════════════════════════
// SCANNER
// ═══════════════════════════════════════════════════════════════════════════

function scanFile(filePath) {
  const content = fs.readFileSync(filePath, 'utf-8');
  const lines = content.split('\n');
  const errors = [];

  function err(line, col, rule, msg) {
    errors.push({ file: filePath, line, col, rule, msg });
  }

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const trimmed = line.trim();
    const lineNum = i + 1;

    // Skip pure comment lines for content rules (but still check ai-comments)
    const isComment = trimmed.startsWith('//') || trimmed.startsWith('*') || trimmed.startsWith('/*');
    // Skip console.log/error — developer terminal output, not UI
    const isConsole = /console\.\w+\(/.test(trimmed);

    // ── no-emoji-in-ui ──
    if (!isComment && !isConsole) {
      const emojiMatch = line.match(EMOJI_RE);
      if (emojiMatch) {
        err(lineNum, line.indexOf(emojiMatch[0]) + 1, 'no-emoji-in-ui',
          `Emoji "${emojiMatch[0]}" in UI. Use text or SVG icons. Emoji break professional tone.`);
      }
    }

    // ── no-ai-slop ──
    if (!isComment) {
      const lower = line.toLowerCase();
      for (const phrase of slopLower) {
        const idx = lower.indexOf(phrase);
        if (idx !== -1) {
          err(lineNum, idx + 1, 'no-ai-slop',
            `AI slop: "${phrase}". Use direct, human language. No corporate filler.`);
          break; // one per line
        }
      }
    }

    // ── no-placeholder ──
    if (!isComment) {
      const lower = line.toLowerCase();
      for (const p of PLACEHOLDER_PATTERNS) {
        const idx = lower.indexOf(p);
        if (idx !== -1) {
          err(lineNum, idx + 1, 'no-placeholder',
            `Placeholder content: "${p}". Replace with real content before shipping.`);
          break;
        }
      }
    }

    // ── no-ai-comments ──
    if (trimmed.startsWith('//')) {
      for (const pattern of AI_COMMENT_PATTERNS) {
        if (pattern.test(trimmed)) {
          err(lineNum, 1, 'no-ai-comments',
            'AI-style comment. Comments should explain WHY, not WHAT. The code shows what it does.');
          break;
        }
      }
    }

    // ── prefer-semantic-tokens (Tailwind raw colors in strings) ──
    if (!isComment) {
      const matches = line.match(TAILWIND_RAW_COLOR_RE);
      if (matches) {
        for (const cls of matches) {
          err(lineNum, line.indexOf(cls.trim()) + 1, 'prefer-semantic-tokens',
            `Raw Tailwind color "${cls.trim()}". Use semantic token (surface-primary, text-secondary, etc.).`);
        }
      }
    }
  }

  return errors;
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN
// ═══════════════════════════════════════════════════════════════════════════

const args = process.argv.slice(2);
const fix = args.includes('--fix');
const inputFiles = args.filter(a => !a.startsWith('--'));

// Resolve targets
let targets = inputFiles;
if (targets.length === 0) {
  const cwd = process.cwd();
  targets = [];
  // Auto-detect: look for common dashboard/UI files
  function walk(dir, exts) {
    if (!fs.existsSync(dir)) return;
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
      if (entry.name === 'node_modules' || entry.name === 'dist' || entry.name === '.git') continue;
      // Skip test files — they use placeholder data by design
      if (entry.name.includes('.test.') || entry.name.includes('.spec.') || entry.name === '__tests__') continue;
      const full = path.join(dir, entry.name);
      if (entry.isDirectory()) walk(full, exts);
      else if (exts.some(e => entry.name.endsWith(e))) targets.push(full);
    }
  }
  walk(path.join(cwd, 'src'), ['.ts', '.tsx', '.js', '.jsx', '.css', '.html', '.vue']);
  walk(path.join(cwd, 'public'), ['.html', '.css']);
  // Root html/css
  for (const f of fs.readdirSync(cwd)) {
    if ((f.endsWith('.html') || f.endsWith('.css')) && !f.startsWith('.')) targets.push(path.join(cwd, f));
  }
}

if (targets.length === 0) {
  console.log('nexum-lint: no files to scan.');
  process.exit(0);
}

// ── Pass 0: Reject .js/.jsx files in TypeScript projects ──
// In a TS project, all logic files must be .ts/.tsx. Plain JS is not allowed.
const tsConfigExists = fs.existsSync(path.join(process.cwd(), 'tsconfig.json'));

// ── Pass 1: Direct scan (all rules except CSS-specific) ──
let totalErrors = 0;
const allErrors = [];

for (const f of targets) {
  if (!fs.existsSync(f)) continue;
  if (tsConfigExists && (f.endsWith('.js') || f.endsWith('.jsx'))) {
    const rel = path.relative(process.cwd(), f);
    allErrors.push({ file: f, line: 1, col: 1, rule: 'no-js-in-ts-project',
      msg: `"${rel}" is a .js file in a TypeScript project. Rename to .ts/.tsx.` });
    continue;
  }
  allErrors.push(...scanFile(f));
}

// ── Pass 2: Stylelint for CSS-specific rules (raw colors in CSS, spacing) ──
const configPath = path.resolve(__dirname, '..', 'stylelint.config.cjs');
const tempFiles = [];
const cssTargets = [];

for (const f of targets) {
  if (f.endsWith('.css')) {
    cssTargets.push(`"${f}"`);
  } else if (f.endsWith('.ts') || f.endsWith('.tsx') || f.endsWith('.vue') || f.endsWith('.html')) {
    try {
      const content = fs.readFileSync(f, 'utf-8');
      const styleRe = /<style[^>]*>([\s\S]*?)<\/style>/gi;
      let match;
      const blocks = [];
      while ((match = styleRe.exec(content)) !== null) blocks.push(match[1]);
      if (blocks.length > 0) {
        const tmp = path.join(require('os').tmpdir(), `nexum-lint-${path.basename(f)}.css`);
        fs.writeFileSync(tmp, blocks.join('\n\n'));
        tempFiles.push({ tmp, original: f });
        cssTargets.push(`"${tmp}"`);
      }
    } catch {}
  }
}

let stylelintOutput = '';
if (cssTargets.length > 0) {
  const stylelintBin = path.resolve(__dirname, '..', 'node_modules', '.bin', 'stylelint');
  const cmd = `"${stylelintBin}" ${cssTargets.join(' ')} --config "${configPath}"${fix ? ' --fix' : ''} --no-color`;
  try {
    execSync(cmd, { cwd: process.cwd(), encoding: 'utf-8', stdio: 'pipe' });
  } catch (e) {
    stylelintOutput = (e.stdout || '') + (e.stderr || '');
    for (const { tmp, original } of tempFiles) {
      stylelintOutput = stylelintOutput.replaceAll(tmp, original);
      stylelintOutput = stylelintOutput.replaceAll(path.relative(process.cwd(), tmp), original);
    }
    const m = stylelintOutput.match(/(\d+) problems?/);
    totalErrors += m ? parseInt(m[1]) : 1;
  }
}

// Cleanup temp
for (const { tmp } of tempFiles) { try { fs.unlinkSync(tmp); } catch {} }

// ── Output ──
if (allErrors.length > 0) {
  for (const e of allErrors) {
    const rel = path.relative(process.cwd(), e.file);
    console.error(`${rel}:${e.line}:${e.col}  \u2716  ${e.msg}  nexum/${e.rule}`);
  }
  totalErrors += allErrors.length;
}

if (stylelintOutput) {
  console.error(stylelintOutput);
}

if (totalErrors > 0) {
  console.error(`\n\u274C nexum-lint: ${totalErrors} design system violation${totalErrors > 1 ? 's' : ''}.`);
  console.error('   The design system is enforced, not suggested. Fix before building.');
  process.exit(2);
} else {
  console.log('\u2705 nexum-lint: all clear');
  process.exit(0);
}
