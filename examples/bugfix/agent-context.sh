#!/usr/bin/env bash
# agent-context.sh — Patches agent .md files with bugfix-specific Project Context.
#
# Usage:
#   ./examples/bugfix/agent-context.sh /path/to/project
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

- This is a bugfix project — source code and tests already exist.
- Source files are in \`src/\` as ES modules. Tests are colocated as \`<module>.test.js\`.
- Tasks are about fixing bugs in existing code, NOT creating new files.
- The Planner should verify the bug exists by noting the failing tests, then pass through.
- Tasks are already atomic. Each task = one bug fix. Do not decompose further.
- If a task description matches reality, just update planner-context.md and exit."

# ── Test Maker ──
patch_context "$AGENTS_DIR/test-maker.md" "## Project Context

- Test framework: **vitest** (already in package.json). Use \`import { describe, it, expect } from 'vitest'\`.
- Test files ALREADY EXIST in \`src/\` as \`<module>.test.js\`.
- IMPORTANT: Tests are pre-written and intentionally failing to expose bugs.
- Do NOT create new test files. Do NOT modify existing test files.
- The Test Maker's job for this project is to verify the existing tests capture the bug, then exit.
- If tests already exist and cover the bug described in the task, commit nothing and exit."

# ── Coder ──
patch_context "$AGENTS_DIR/coder.md" "## Project Context

- Source files are in \`src/\` as ES modules (\`.js\` files with \`export\`).
- IMPORTANT: Fix the bug in the existing implementation. Do NOT rewrite the function from scratch.
- Make the minimal change needed to fix the specific bug described in the task.
- Keep existing JSDoc comments intact. Update them only if the fix changes behavior.
- The tests already exist — your code must make the failing tests pass.
- Do NOT touch test files."

# ── Reviewer ──
patch_context "$AGENTS_DIR/reviewer.md" "## Project Context

- Run tests with: \`npm test\` (runs \`vitest run\`).
- There is no nexum-lint configured for this project — skip the lint step. Only run tests.
- This is a bugfix project: verify that the specific bug is fixed, not a rewrite.
- Check that existing JSDoc is intact and accurate.
- Verify git history: coder's commit should NOT touch test files.
- All pre-existing tests must pass after the fix."

echo "Agent context patched for bugfix example project."
