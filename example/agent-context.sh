#!/usr/bin/env bash
# agent-context.sh — Patches agent .md files with example-specific Project Context.
#
# Usage:
#   ./example/agent-context.sh /path/to/project
#
# Run AFTER init.sh has copied agent templates into the target project.
# Replaces the placeholder "## Project Context" sections with concrete guidance
# for this string-utils example project.

set -euo pipefail

TARGET="${1:?Usage: $0 /path/to/project}"
AGENTS_DIR="$TARGET/.claude/agents"

if [[ ! -d "$AGENTS_DIR" ]]; then
  echo "Error: $AGENTS_DIR does not exist. Run init.sh first." >&2
  exit 1
fi

# patch_context <agent-file> <context-text>
# Replaces everything from "## Project Context" to end-of-file with the new context.
patch_context() {
  local file="$1"
  local context="$2"

  if [[ ! -f "$file" ]]; then
    echo "Warning: $file not found, skipping." >&2
    return
  fi

  # Find the line number of "## Project Context"
  local line_num
  line_num=$(grep -n '^## Project Context' "$file" | head -1 | cut -d: -f1)

  if [[ -z "$line_num" ]]; then
    echo "Warning: No '## Project Context' section in $file, skipping." >&2
    return
  fi

  # Keep everything before the Project Context section, append new context
  head -n "$((line_num - 1))" "$file" > "${file}.tmp"
  printf '%s\n' "$context" >> "${file}.tmp"
  mv "${file}.tmp" "$file"
}

# ── Planner ──
patch_context "$AGENTS_DIR/planner.md" "## Project Context

- Source files go in \`src/\`. Each module is one file with one named export.
- Module boundaries: \`capitalize.js\` and \`truncate.js\` are independent — no shared dependencies.
- Tasks are already atomic. Each task = one function = one file. Do not decompose further.
- If a task description matches reality, just update planner-context.md and exit."

# ── Test Maker ──
patch_context "$AGENTS_DIR/test-maker.md" "## Project Context

- Test framework: **vitest** (already in package.json). Use \`import { describe, it, expect } from 'vitest'\`.
- Test file location: colocated in \`src/\` as \`<module>.test.js\` (e.g., \`src/capitalize.test.js\`).
- Import the function from the relative path: \`import { capitalize } from './capitalize.js'\`.
- File extension: use \`.js\` (not \`.ts\`) — this is a plain JavaScript project with ES modules.
- Each test file covers one function. Name tests as behavior specs (e.g., \"capitalizes multiple words\")."

# ── Scaffolder ──
patch_context "$AGENTS_DIR/scaffolder.md" "## Project Context

- Source files go in \`src/\` as ES modules (\`.js\` files with \`export\`).
- Each stub exports a single named function with the correct signature.
- Add a JSDoc comment with \`@param\`, \`@returns\`, and \`@example\` on every export.
- Function bodies: \`throw new Error('Not implemented')\` — nothing else.
- No dependencies — only use built-in JavaScript features."

# ── Coder ──
patch_context "$AGENTS_DIR/coder.md" "## Project Context

- Source files go in \`src/\` as ES modules (\`.js\` files with \`export\`).
- Each module exports a single named function (e.g., \`export function capitalize(str)\`).
- Add a JSDoc comment with \`@param\`, \`@returns\`, and \`@example\` on every export.
- No dependencies — only use built-in JavaScript features.
- Handle edge cases: empty strings, null/undefined inputs, boundary values."

# ── Reviewer ──
patch_context "$AGENTS_DIR/reviewer.md" "## Project Context

- Run tests with: \`npm test\` (runs \`vitest run\`).
- There is no nexum-lint configured for this project — skip the lint step. Only run tests.
- Check that every exported function has JSDoc with \`@param\`, \`@returns\`, and \`@example\`.
- Verify edge cases are handled: empty string, null/undefined, boundary values.
- On PASS: \`git add -A && git commit -m \"feat: <description>\"\`."

echo "Agent context patched for example project."
