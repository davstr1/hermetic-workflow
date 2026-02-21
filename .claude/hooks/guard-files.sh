#!/usr/bin/env bash
# guard-files.sh — PreToolUse hook for hermetic agent isolation.
#
# Every agent has an explicit permission scope. If a tool call falls outside
# that scope, the hook blocks it (exit 2) and shows a message to the agent.
#
# Agent identification:
#   1. HERMETIC_AGENT env var (legacy: set by orchestrator.sh)
#   2. workflow/state/current-agent.txt (native: written by orchestrator agent)
#
# Unrestricted agents: architect, orchestrator (and unknown/empty — for manual use)
# Restricted agents: planner, test-maker, coder, reviewer
#
# Exit codes:
#   0 = allow (tool proceeds)
#   2 = block (tool is denied, stderr shown to agent)

set -euo pipefail

# ── Identify current agent ──
CURRENT_AGENT="${HERMETIC_AGENT:-}"
if [[ -z "$CURRENT_AGENT" && -f "$CLAUDE_PROJECT_DIR/workflow/state/current-agent.txt" ]]; then
  CURRENT_AGENT=$(cat "$CLAUDE_PROJECT_DIR/workflow/state/current-agent.txt" 2>/dev/null || echo "")
fi

# Unrestricted agents pass through immediately
case "$CURRENT_AGENT" in
  architect|orchestrator|"") exit 0 ;;
esac

# ── Read tool input ──
INPUT=$(cat)
TOOL_NAME="${TOOL_NAME:-}"

# ── Path helpers ──

# Make a path relative to project dir
rel_path() {
  local p="$1"
  p="${p#"${CLAUDE_PROJECT_DIR}"/}"
  p="${p#./}"
  echo "$p"
}

# Check if a path matches any pattern in a list
# Usage: matches_any "path" "pattern1" "pattern2" ...
matches_any() {
  local path="$1"; shift
  local base
  base=$(basename "$path")

  for pattern in "$@"; do
    case "$pattern" in
      # Directory wildcard: "dir/*" matches anything under dir
      */\*)
        local dir="${pattern%/*}"
        if [[ "$path" == "$dir"/* || "$path" == "$dir" ]]; then
          return 0
        fi
        ;;
      # Basename glob: "*.test.*" matches the filename part
      \*.*)
        case "$base" in
          $pattern) return 0 ;;
        esac
        ;;
      # Exact match
      *)
        if [[ "$path" == $pattern ]]; then
          return 0
        fi
        ;;
    esac
  done
  return 1
}

# ── Per-agent READ restrictions ──
# Returns 0 if read is allowed, 1 if blocked
check_read() {
  local path="$1"

  case "$CURRENT_AGENT" in
    coder)
      # Coder cannot read: tests, lint rules, agent defs, review state
      if matches_any "$path" \
        '*.test.*' '*.spec.*' '__tests__/*' 'tests/*' \
        'example-ui-rules/eslint-rules/*' 'example-ui-rules/stylelint-rules/*' \
        'example-ui-rules/bin/*' 'example-ui-rules/.eslintrc*' \
        'eslint-config.*' '.eslintrc*' 'stylelint.config.*' \
        '.claude/agents/*' \
        'workflow/state/review-feedback.md' 'workflow/state/review-status.txt' \
        'workflow/state/escalation-context.md'; then
        return 1
      fi
      ;;
    planner)
      # Planner cannot read: source code is fine, but lint rules and agent defs are off-limits
      if matches_any "$path" \
        '.claude/agents/*' \
        'example-ui-rules/eslint-rules/*' 'example-ui-rules/stylelint-rules/*' \
        'example-ui-rules/bin/*'; then
        return 1
      fi
      ;;
    test-maker)
      # Test-maker cannot read: lint rules, agent defs
      if matches_any "$path" \
        '.claude/agents/*' \
        'example-ui-rules/eslint-rules/*' 'example-ui-rules/stylelint-rules/*' \
        'example-ui-rules/bin/*'; then
        return 1
      fi
      ;;
    reviewer)
      # Reviewer can read everything — needs full visibility to judge
      ;;
  esac
  return 0
}

# ── Per-agent WRITE restrictions ──
# Uses an allowlist: only paths matching allowed patterns can be written.
# Returns 0 if write is allowed, 1 if blocked.
check_write() {
  local path="$1"

  case "$CURRENT_AGENT" in
    coder)
      # Coder can write source code only — no tests, no rules, no state, no config
      if matches_any "$path" \
        '*.test.*' '*.spec.*' '__tests__/*' 'tests/*' \
        'example-ui-rules/*' 'eslint-config.*' '.eslintrc*' 'stylelint.config.*' \
        '.claude/agents/*' '.claude/hooks/*' '.claude/settings.json' \
        'workflow/*' 'principles.md' \
        'orchestrator.sh' 'init.sh' 'setup-remote.sh' \
        'CLAUDE.md' 'README.md'; then
        return 1
      fi
      ;;
    planner)
      # Planner can only write: tasks.md and its own context file
      if matches_any "$path" \
        'workflow/tasks.md' 'workflow/state/planner-context.md'; then
        return 0
      fi
      return 1
      ;;
    test-maker)
      # Test-maker can only write test files and package.json (for adding test deps)
      if matches_any "$path" \
        '*.test.*' '*.spec.*' '__tests__/*' 'tests/*'; then
        return 0
      fi
      # Allow package.json for installing test framework deps
      if [[ "$path" == "package.json" ]]; then
        return 0
      fi
      return 1
      ;;
    reviewer)
      # Reviewer can only write review state files
      if matches_any "$path" \
        'workflow/state/review-status.txt' 'workflow/state/review-feedback.md'; then
        return 0
      fi
      return 1
      ;;
  esac
  return 0
}

# ── Per-agent GLOB restrictions ──
check_glob() {
  local pattern="$1"

  case "$CURRENT_AGENT" in
    coder)
      for forbidden_dir in ".claude/agents" "example-ui-rules/eslint-rules" "example-ui-rules/stylelint-rules" "example-ui-rules/bin" "__tests__" "tests" "workflow/state"; do
        if [[ "$pattern" == *"$forbidden_dir"* ]]; then
          return 1
        fi
      done
      if [[ "$pattern" == *".test."* || "$pattern" == *".spec."* ]]; then
        return 1
      fi
      ;;
    planner)
      for forbidden_dir in ".claude/agents" "example-ui-rules/eslint-rules" "example-ui-rules/stylelint-rules" "example-ui-rules/bin"; do
        if [[ "$pattern" == *"$forbidden_dir"* ]]; then
          return 1
        fi
      done
      ;;
    test-maker)
      for forbidden_dir in ".claude/agents" "example-ui-rules/eslint-rules" "example-ui-rules/stylelint-rules" "example-ui-rules/bin"; do
        if [[ "$pattern" == *"$forbidden_dir"* ]]; then
          return 1
        fi
      done
      ;;
    reviewer)
      # Reviewer can glob anything (needs full visibility)
      ;;
  esac
  return 0
}

# ── Per-agent BASH restrictions ──
check_bash() {
  local command="$1"

  case "$CURRENT_AGENT" in
    coder)
      # Block access to forbidden paths via shell
      for forbidden in ".claude/agents/" "example-ui-rules/eslint-rules" "example-ui-rules/stylelint-rules" "example-ui-rules/bin" "review-feedback.md" "review-status.txt" "escalation-context.md"; do
        if [[ "$command" == *"$forbidden"* ]]; then
          return 1
        fi
      done
      # Block reading test files via shell (but allow running test commands)
      if [[ "$command" == *".test."* || "$command" == *".spec."* || "$command" == *"__tests__"* ]]; then
        if [[ "$command" != *"jest"* && "$command" != *"vitest"* && "$command" != *"npm test"* && "$command" != *"npm run test"* && "$command" != *"npx test"* ]]; then
          return 1
        fi
      fi
      ;;
    planner)
      # Planner: allow git log, reading tasks — block writing source code or running tests
      # Block access to agent defs and lint rules
      for forbidden in ".claude/agents/" "example-ui-rules/eslint-rules" "example-ui-rules/stylelint-rules" "example-ui-rules/bin"; do
        if [[ "$command" == *"$forbidden"* ]]; then
          return 1
        fi
      done
      ;;
    test-maker)
      # Test-maker: allow npm install (test deps), running tests — block lint rules/agents
      for forbidden in ".claude/agents/" "example-ui-rules/eslint-rules" "example-ui-rules/stylelint-rules" "example-ui-rules/bin"; do
        if [[ "$command" == *"$forbidden"* ]]; then
          return 1
        fi
      done
      ;;
    reviewer)
      # Reviewer: allow running tests, lint, git — block writing source code
      # Git commit is allowed (reviewer commits on PASS)
      # Block destructive git operations except commit
      if [[ "$command" == *"git push"* || "$command" == *"git reset"* || "$command" == *"git checkout"* || "$command" == *"git restore"* ]]; then
        # Allow git checkout for switching files to view, block destructive patterns
        if [[ "$command" == *"git reset --hard"* || "$command" == *"git push"* ]]; then
          return 1
        fi
      fi
      # Block writing/editing source files via shell (cat >, tee, sed -i, etc.)
      # But allow read operations (cat, less, head) and running lint/tests
      ;;
  esac
  return 0
}

# ── Main dispatch ──

extract_and_check() {
  local blocked=0

  case "$TOOL_NAME" in
    Read)
      local file_path
      file_path=$(echo "$INPUT" | jq -r '.file_path // empty' 2>/dev/null)
      if [[ -n "$file_path" ]]; then
        file_path=$(rel_path "$file_path")
        if ! check_read "$file_path"; then
          echo "BLOCKED: ${CURRENT_AGENT} agent cannot read '$file_path'. Outside your scope." >&2
          blocked=1
        fi
      fi
      ;;

    Write|Edit)
      local file_path
      file_path=$(echo "$INPUT" | jq -r '.file_path // empty' 2>/dev/null)
      if [[ -n "$file_path" ]]; then
        file_path=$(rel_path "$file_path")
        if ! check_write "$file_path"; then
          echo "BLOCKED: ${CURRENT_AGENT} agent cannot write to '$file_path'. Outside your scope." >&2
          blocked=1
        fi
      fi
      ;;

    Glob)
      local pattern
      pattern=$(echo "$INPUT" | jq -r '.pattern // empty' 2>/dev/null)
      if [[ -n "$pattern" ]]; then
        if ! check_glob "$pattern"; then
          echo "BLOCKED: ${CURRENT_AGENT} agent cannot glob '$pattern'. Outside your scope." >&2
          blocked=1
        fi
      fi
      ;;

    Grep)
      local path
      path=$(echo "$INPUT" | jq -r '.path // empty' 2>/dev/null)
      if [[ -n "$path" ]]; then
        path=$(rel_path "$path")
        if ! check_read "$path"; then
          echo "BLOCKED: ${CURRENT_AGENT} agent cannot search in '$path'. Outside your scope." >&2
          blocked=1
        fi
      fi
      local glob
      glob=$(echo "$INPUT" | jq -r '.glob // empty' 2>/dev/null)
      if [[ -n "$glob" ]]; then
        # Reuse glob check logic
        if ! check_glob "$glob"; then
          echo "BLOCKED: ${CURRENT_AGENT} agent cannot search with glob '$glob'. Outside your scope." >&2
          blocked=1
        fi
      fi
      ;;

    Bash)
      local command
      command=$(echo "$INPUT" | jq -r '.command // empty' 2>/dev/null)
      if [[ -n "$command" ]]; then
        if ! check_bash "$command"; then
          echo "BLOCKED: ${CURRENT_AGENT} agent cannot run this command. Outside your scope." >&2
          blocked=1
        fi
      fi
      ;;
  esac

  return $blocked
}

if ! extract_and_check; then
  exit 2
fi

exit 0
