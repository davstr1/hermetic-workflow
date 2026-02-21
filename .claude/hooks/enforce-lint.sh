#!/usr/bin/env bash
# enforce-lint.sh — PostToolUse hook for lint + test enforcement.
#
# When the coder agent is active, after every Write/Edit of a source file:
#   1. Runs nexum-lint.cjs on the written file (lint feedback)
#   2. Runs the test suite (test feedback)
#
# Identifies the current agent via:
#   1. HERMETIC_AGENT env var (legacy: set by orchestrator.sh)
#   2. workflow/state/current-agent.txt (native: written by orchestrator agent)
#
# The coder sees error messages but never rule definitions or test source code.
#
# Exit codes:
#   0 = always (feedback only, never blocks the write)

set -euo pipefail

# Identify current agent: env var first, then state file fallback
CURRENT_AGENT="${HERMETIC_AGENT:-}"
if [[ -z "$CURRENT_AGENT" && -f "$CLAUDE_PROJECT_DIR/workflow/state/current-agent.txt" ]]; then
  CURRENT_AGENT=$(cat "$CLAUDE_PROJECT_DIR/workflow/state/current-agent.txt" 2>/dev/null || echo "")
fi

# Only enforce for the coder agent
if [[ "$CURRENT_AGENT" != "coder" ]]; then
  exit 0
fi

TOOL_NAME="${TOOL_NAME:-}"

# Only run after Write or Edit
if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
  exit 0
fi

# Read tool input from stdin
INPUT=$(cat)

# Extract the file path that was just written/edited
FILE_PATH=$(echo "$INPUT" | jq -r '.file_path // empty' 2>/dev/null)

if [[ -z "$FILE_PATH" ]]; then
  exit 0
fi

# Only lint source files (not config, not markdown, etc.)
case "$FILE_PATH" in
  *.ts|*.tsx|*.js|*.jsx|*.css|*.html|*.vue)
    ;;
  *)
    exit 0
    ;;
esac

# Skip test files (they shouldn't be written by coder, but just in case)
case "$(basename "$FILE_PATH")" in
  *.test.*|*.spec.*)
    exit 0
    ;;
esac

# Locate nexum-lint.cjs relative to project dir
LINT_BIN="${CLAUDE_PROJECT_DIR}/example-ui-rules/bin/nexum-lint.cjs"

if [[ ! -f "$LINT_BIN" ]]; then
  # Linter not found — don't block, just warn
  echo "Warning: nexum-lint.cjs not found at $LINT_BIN" >&2
  exit 0
fi

# Run the linter on the specific file
LINT_OUTPUT=$(node "$LINT_BIN" "$FILE_PATH" 2>&1) || true
LINT_EXIT=$?

if [[ $LINT_EXIT -ne 0 && -n "$LINT_OUTPUT" ]]; then
  echo "LINT ERRORS in $(basename "$FILE_PATH"):" >&2
  echo "$LINT_OUTPUT" >&2
  echo "" >&2
  echo "Fix these lint violations. The design system is enforced, not suggested." >&2
  HAS_ERRORS=1
fi

# ── Run tests ──
# Detect test runner from package.json
TEST_CMD=""
if [[ -f "${CLAUDE_PROJECT_DIR}/package.json" ]]; then
  # Check for test script in package.json
  HAS_TEST_SCRIPT=$(node -e "
    const pkg = require('${CLAUDE_PROJECT_DIR}/package.json');
    console.log(pkg.scripts && pkg.scripts.test ? 'yes' : 'no');
  " 2>/dev/null || echo "no")

  if [[ "$HAS_TEST_SCRIPT" == "yes" ]]; then
    TEST_CMD="npm test --"
  fi
fi

# Fallback: detect vitest or jest directly
if [[ -z "$TEST_CMD" ]]; then
  if [[ -f "${CLAUDE_PROJECT_DIR}/node_modules/.bin/vitest" ]]; then
    TEST_CMD="npx vitest run"
  elif [[ -f "${CLAUDE_PROJECT_DIR}/node_modules/.bin/jest" ]]; then
    TEST_CMD="npx jest"
  fi
fi

if [[ -n "$TEST_CMD" ]]; then
  TEST_OUTPUT=$(cd "$CLAUDE_PROJECT_DIR" && $TEST_CMD --no-color 2>&1) || true
  TEST_EXIT=$?

  if [[ $TEST_EXIT -ne 0 ]]; then
    echo "" >&2
    echo "TEST FAILURES:" >&2
    # Show only the summary/failure lines, not the full verbose output
    echo "$TEST_OUTPUT" | tail -40 >&2
    echo "" >&2
    echo "Tests are failing. Fix your implementation to make them pass." >&2
    HAS_ERRORS=1
  else
    echo "" >&2
    echo "Tests: ALL PASSING" >&2
  fi
fi

exit 0
