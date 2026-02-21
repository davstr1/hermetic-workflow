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
        'workflow/*' \
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

# ── Per-agent BASH restrictions (allowlist-based) ──

# Universal: detect shell-based file writes.
# Returns 0 if the command writes to files, 1 otherwise.
shell_writes_to_file() {
  local cmd="$1"
  # Output redirection (> >>). Match common patterns:
  #   cmd > file, cmd >file, cmd 2> file, cmd &> file, cmd 1> file
  [[ "$cmd" =~ [[:space:]]1?\>[[:space:]] ]] && return 0
  [[ "$cmd" =~ [[:space:]]2?\>[[:space:]] ]] && return 0
  [[ "$cmd" =~ [[:space:]]\&\>[[:space:]] ]] && return 0
  [[ "$cmd" == *">>"* ]] && return 0
  # Pipe to tee
  [[ "$cmd" =~ [[:space:]]tee[[:space:]] ]] && return 0
  # In-place sed
  [[ "$cmd" =~ [[:space:]]sed[[:space:]]+-i ]] && return 0
  [[ "$cmd" == sed\ -i* ]] && return 0
  # File manipulation
  [[ "$cmd" =~ [[:space:]]cp[[:space:]] ]] && return 0
  [[ "$cmd" == cp\ * ]] && return 0
  [[ "$cmd" =~ [[:space:]]mv[[:space:]] ]] && return 0
  [[ "$cmd" == mv\ * ]] && return 0
  [[ "$cmd" =~ [[:space:]]rm[[:space:]] ]] && return 0
  [[ "$cmd" == rm\ * ]] && return 0
  # Inline scripting that can write files
  [[ "$cmd" == *"node -e"* ]] && return 0
  [[ "$cmd" == *"node --eval"* ]] && return 0
  [[ "$cmd" == *"python -c"* ]] && return 0
  [[ "$cmd" == *"python3 -c"* ]] && return 0
  [[ "$cmd" == *"ruby -e"* ]] && return 0
  [[ "$cmd" == *"perl -e"* ]] && return 0
  # curl/wget download to file
  [[ "$cmd" == *"curl "* && "$cmd" == *" -o"* ]] && return 0
  [[ "$cmd" == *"curl "* && "$cmd" == *" -O"* ]] && return 0
  [[ "$cmd" == *"wget "* ]] && return 0
  # dd
  [[ "$cmd" == dd\ * || "$cmd" == *" dd "* ]] && return 0
  # install command
  [[ "$cmd" == install\ * || "$cmd" == *" install "* ]] && [[ "$cmd" != *"npm install"* && "$cmd" != *"npm i "* ]] && return 0
  return 1
}

# Check a single command (no chaining) against per-agent allowlist.
# Returns 0 if allowed, 1 if blocked.
check_single_command() {
  local cmd="$1"
  # Trim leading/trailing whitespace
  cmd=$(echo "$cmd" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
  [[ -z "$cmd" ]] && return 0  # empty segment is fine

  # Universal write guard for all restricted agents
  if shell_writes_to_file "$cmd"; then
    return 1
  fi

  case "$CURRENT_AGENT" in
    planner)
      # Git read-only commands
      [[ "$cmd" == git\ log* ]] && return 0
      [[ "$cmd" == git\ diff* ]] && return 0
      [[ "$cmd" == git\ status* ]] && return 0
      [[ "$cmd" == git\ show* ]] && return 0
      # Read-only utilities
      [[ "$cmd" == ls* ]] && return 0
      [[ "$cmd" == cat\ * ]] && return 0
      [[ "$cmd" == head\ * ]] && return 0
      [[ "$cmd" == tail\ * ]] && return 0
      [[ "$cmd" == wc\ * ]] && return 0
      # Everything else is blocked
      return 1
      ;;
    test-maker)
      # npm install / test commands
      [[ "$cmd" == npm\ install* ]] && return 0
      [[ "$cmd" == npm\ i\ * ]] && return 0
      [[ "$cmd" == npm\ test* ]] && return 0
      [[ "$cmd" == npm\ run\ test* ]] && return 0
      [[ "$cmd" == npx\ jest* ]] && return 0
      [[ "$cmd" == npx\ vitest* ]] && return 0
      # Node (verify test setup)
      [[ "$cmd" == node\ * ]] && return 0
      # Git read-only
      [[ "$cmd" == git\ log* ]] && return 0
      [[ "$cmd" == git\ diff* ]] && return 0
      [[ "$cmd" == git\ status* ]] && return 0
      [[ "$cmd" == git\ show* ]] && return 0
      # Read-only utilities
      [[ "$cmd" == ls* ]] && return 0
      [[ "$cmd" == cat\ * ]] && return 0
      [[ "$cmd" == head\ * ]] && return 0
      [[ "$cmd" == tail\ * ]] && return 0
      [[ "$cmd" == wc\ * ]] && return 0
      return 1
      ;;
    coder)
      # Forbidden path check first — coder can't reference these in ANY command
      for forbidden in ".claude/agents/" "example-ui-rules/eslint-rules" "example-ui-rules/stylelint-rules" "example-ui-rules/bin" "review-feedback.md" "review-status.txt" "escalation-context.md"; do
        if [[ "$cmd" == *"$forbidden"* ]]; then
          return 1
        fi
      done
      # Block test file references in any command
      if [[ "$cmd" == *".test."* || "$cmd" == *".spec."* || "$cmd" == *"__tests__"* ]]; then
        return 1
      fi
      # npm / build / run commands
      [[ "$cmd" == npm\ install* ]] && return 0
      [[ "$cmd" == npm\ i\ * ]] && return 0
      [[ "$cmd" == npm\ run\ * ]] && return 0
      [[ "$cmd" == npm\ test* ]] && return 0
      [[ "$cmd" == npx\ * ]] && return 0
      # Node / TypeScript
      [[ "$cmd" == node\ * ]] && return 0
      [[ "$cmd" == tsc* ]] && return 0
      # Directory creation
      [[ "$cmd" == mkdir\ * ]] && return 0
      # Git read-only
      [[ "$cmd" == git\ log* ]] && return 0
      [[ "$cmd" == git\ diff* ]] && return 0
      [[ "$cmd" == git\ status* ]] && return 0
      [[ "$cmd" == git\ show* ]] && return 0
      # Read-only utilities
      [[ "$cmd" == ls* ]] && return 0
      [[ "$cmd" == cat\ * ]] && return 0
      [[ "$cmd" == head\ * ]] && return 0
      [[ "$cmd" == tail\ * ]] && return 0
      [[ "$cmd" == wc\ * ]] && return 0
      return 1
      ;;
    reviewer)
      # Test / lint commands
      [[ "$cmd" == npm\ test* ]] && return 0
      [[ "$cmd" == npm\ run\ test* ]] && return 0
      [[ "$cmd" == npx\ jest* ]] && return 0
      [[ "$cmd" == npx\ vitest* ]] && return 0
      [[ "$cmd" == node\ example-ui-rules/bin/nexum-lint* ]] && return 0
      [[ "$cmd" == node\ */nexum-lint* ]] && return 0
      # npm run (for lint/build scripts)
      [[ "$cmd" == npm\ run\ * ]] && return 0
      # Git commit workflow (but block destructive operations)
      [[ "$cmd" == git\ add* ]] && return 0
      [[ "$cmd" == git\ commit* ]] && return 0
      [[ "$cmd" == git\ log* ]] && return 0
      [[ "$cmd" == git\ diff* ]] && return 0
      [[ "$cmd" == git\ status* ]] && return 0
      [[ "$cmd" == git\ show* ]] && return 0
      # Block destructive git
      [[ "$cmd" == git\ push* ]] && return 1
      [[ "$cmd" == git\ reset* ]] && return 1
      [[ "$cmd" == git\ checkout* ]] && return 1
      [[ "$cmd" == git\ restore* ]] && return 1
      [[ "$cmd" == git\ clean* ]] && return 1
      [[ "$cmd" == git\ rebase* ]] && return 1
      [[ "$cmd" == git\ merge* ]] && return 1
      [[ "$cmd" == git\ branch\ -[dD]* ]] && return 1
      # Node (for running lint/test scripts)
      [[ "$cmd" == node\ * ]] && return 0
      # Read-only utilities
      [[ "$cmd" == ls* ]] && return 0
      [[ "$cmd" == cat\ * ]] && return 0
      [[ "$cmd" == head\ * ]] && return 0
      [[ "$cmd" == tail\ * ]] && return 0
      [[ "$cmd" == wc\ * ]] && return 0
      return 1
      ;;
  esac
  return 0
}

# Split a compound command on &&, ||, ;, | and check each segment.
# Returns 0 if all segments pass, 1 if any segment fails.
check_bash() {
  local full_cmd="$1"

  # Block subshell/eval-based bypass attempts for all restricted agents
  if [[ "$full_cmd" == *'$('* || "$full_cmd" == *'`'* || "$full_cmd" == *"eval "* || "$full_cmd" == *"bash -c"* || "$full_cmd" == *"sh -c"* || "$full_cmd" == *"zsh -c"* ]]; then
    # Allow $() in safe contexts: git commit -m "$(cat <<'EOF'...)" (heredoc message)
    if [[ "$CURRENT_AGENT" == "reviewer" && "$full_cmd" == git\ commit* && "$full_cmd" == *'$(cat <<'* ]]; then
      return 0  # safe: reviewer git commit with heredoc message, skip splitting
    else
      return 1
    fi
  fi

  # Split on && || ; | — replace delimiters with newlines, then iterate.
  # Use a simple approach: replace unquoted delimiters.
  # (This won't handle all quoting edge cases but covers practical usage)
  local segments
  segments=$(echo "$full_cmd" | sed 's/&&/\n/g; s/||/\n/g; s/;/\n/g' | sed 's/|/\n/g')

  local failed=0
  while IFS= read -r segment; do
    segment=$(echo "$segment" | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')
    [[ -z "$segment" ]] && continue
    if ! check_single_command "$segment"; then
      failed=1
      break
    fi
  done <<< "$segments"

  return $failed
}

# ── Block logging ──
# Append blocked attempts to a persistent log for orchestrator visibility.
BLOCK_LOG="${CLAUDE_PROJECT_DIR}/workflow/state/guard-blocks.log"

log_block() {
  local msg="$1"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] $msg" >> "$BLOCK_LOG" 2>/dev/null || true
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
          local msg="BLOCKED: ${CURRENT_AGENT} agent cannot read '$file_path'. Outside your scope."
          echo "$msg" >&2
          log_block "${CURRENT_AGENT} | Read | $file_path"
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
          local msg="BLOCKED: ${CURRENT_AGENT} agent cannot write to '$file_path'. Outside your scope."
          echo "$msg" >&2
          log_block "${CURRENT_AGENT} | ${TOOL_NAME} | $file_path"
          blocked=1
        fi
      fi
      ;;

    Glob)
      local pattern
      pattern=$(echo "$INPUT" | jq -r '.pattern // empty' 2>/dev/null)
      if [[ -n "$pattern" ]]; then
        if ! check_glob "$pattern"; then
          local msg="BLOCKED: ${CURRENT_AGENT} agent cannot glob '$pattern'. Outside your scope."
          echo "$msg" >&2
          log_block "${CURRENT_AGENT} | Glob | $pattern"
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
          local msg="BLOCKED: ${CURRENT_AGENT} agent cannot search in '$path'. Outside your scope."
          echo "$msg" >&2
          log_block "${CURRENT_AGENT} | Grep | $path"
          blocked=1
        fi
      fi
      local glob
      glob=$(echo "$INPUT" | jq -r '.glob // empty' 2>/dev/null)
      if [[ -n "$glob" ]]; then
        # Reuse glob check logic
        if ! check_glob "$glob"; then
          local msg="BLOCKED: ${CURRENT_AGENT} agent cannot search with glob '$glob'. Outside your scope."
          echo "$msg" >&2
          log_block "${CURRENT_AGENT} | Grep(glob) | $glob"
          blocked=1
        fi
      fi
      ;;

    Bash)
      local command
      command=$(echo "$INPUT" | jq -r '.command // empty' 2>/dev/null)
      if [[ -n "$command" ]]; then
        if ! check_bash "$command"; then
          local msg="BLOCKED: ${CURRENT_AGENT} agent cannot run this command. Outside your scope."
          echo "$msg" >&2
          # Truncate long commands in the log
          local log_cmd="${command:0:200}"
          log_block "${CURRENT_AGENT} | Bash | $log_cmd"
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
