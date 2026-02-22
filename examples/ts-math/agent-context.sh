#!/usr/bin/env bash
# agent-context.sh — Patches agent .md files with ts-math-specific Project Context.
#
# Usage:
#   ./examples/ts-math/agent-context.sh /path/to/project
#
# Run AFTER init.sh has copied agent templates into the target project.

set -euo pipefail

TARGET="${1:?Usage: $0 /path/to/project}"
AGENTS_DIR="$TARGET/.claude/agents"

if [[ ! -d "$AGENTS_DIR" ]]; then
  echo "Error: $AGENTS_DIR does not exist. Run init.sh first." >&2
  exit 1
fi

# patch_context <agent-file> <context-text>
patch_context() {
  local file="$1"
  local context="$2"

  if [[ ! -f "$file" ]]; then
    echo "Warning: $file not found, skipping." >&2
    return
  fi

  local line_num
  line_num=$(grep -n '^## Project Context' "$file" | head -1 | cut -d: -f1)

  if [[ -z "$line_num" ]]; then
    echo "Warning: No '## Project Context' section in $file, skipping." >&2
    return
  fi

  head -n "$((line_num - 1))" "$file" > "${file}.tmp"
  printf '%s\n' "$context" >> "${file}.tmp"
  mv "${file}.tmp" "$file"
}

# ── Planner ──
patch_context "$AGENTS_DIR/planner.md" "## Project Context

- Source files go in \`src/\` as \`.ts\` files. Each module is one file with one named export.
- Module boundaries: \`clamp.ts\` and \`lerp.ts\` are independent — no shared dependencies.
- This is a TypeScript project — run \`npm run build\` (tsc) before testing.
- Tasks are already atomic. Each task = one function = one file. Do not decompose further.
- If a task description matches reality, just update planner-context.md and exit."

# ── Test Maker ──
patch_context "$AGENTS_DIR/test-maker.md" "## Project Context

- Test framework: **vitest** (already in package.json). Use \`import { describe, it, expect } from 'vitest'\`.
- Test file location: colocated in \`src/\` as \`<module>.test.ts\` (e.g., \`src/clamp.test.ts\`).
- Import the function from the relative path: \`import { clamp } from './clamp.js'\`.
  Note: use \`.js\` extension in imports (TypeScript ES module resolution).
- File extension: use \`.ts\` for test files — this is a TypeScript project.
- Each test file covers one function. Name tests as behavior specs (e.g., \"clamps value to minimum\")."

# ── Coder ──
patch_context "$AGENTS_DIR/coder.md" "## Project Context

- Source files go in \`src/\` as TypeScript modules (\`.ts\` files with \`export\`).
- Each module exports a single named function with explicit types (e.g., \`export function clamp(value: number, min: number, max: number): number\`).
- Add a JSDoc comment with \`@param\`, \`@returns\`, and \`@example\` on every export.
- No dependencies — only use built-in JavaScript/TypeScript features.
- Handle edge cases: NaN, Infinity, negative values, boundary conditions.
- Code must pass \`tsc --strict\` — use explicit types, no \`any\`."

# ── Reviewer ──
patch_context "$AGENTS_DIR/reviewer.md" "## Project Context

- Build with: \`npm run build\` (runs \`tsc\`). Build MUST pass before running tests.
- Run tests with: \`npm test\` (runs \`vitest run\`).
- There is no nexum-lint configured for this project — skip the lint step. Only build + test.
- Check that every exported function has JSDoc with \`@param\`, \`@returns\`, and \`@example\`.
- Verify edge cases are handled: NaN, Infinity, negative values, boundary conditions.
- Verify git history: coder's commit should NOT touch test files."

echo "Agent context patched for ts-math example project."
