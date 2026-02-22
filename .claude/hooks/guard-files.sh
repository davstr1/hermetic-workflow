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
# All agents are restricted to their owned files.
# Restricted agents: architect, orchestrator, planner, test-maker, coder, reviewer
# Unknown/empty: reads allowed, all writes blocked
#
# Exit codes:
#   0 = allow (tool proceeds)
#   2 = block (tool is denied, stderr shown to agent)
#
# IMPORTANT: This script must NEVER exit 1 by accident.
# Exit 1 = error = Claude Code lets the tool through.
# Exit 2 = intentional block = Claude Code shows stderr to agent.
# So: no set -e, no set -u, no set -o pipefail. Handle errors explicitly.

# ── Path helpers (must be defined before first use) ──

# Make a path relative to project dir
rel_path() {
  local p="$1"
  local project_dir="${CLAUDE_PROJECT_DIR:-}"
  if [[ -n "$project_dir" ]]; then
    p="${p#"${project_dir}"/}"
  fi
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

# ── Block logging ──
# Append blocked attempts to a persistent log for orchestrator visibility.
BLOCK_LOG="${CLAUDE_PROJECT_DIR:-/tmp}/workflow/state/guard-blocks.log"

log_block() {
  local msg="$1"
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  echo "[$timestamp] $msg" >> "$BLOCK_LOG" 2>/dev/null || true
}

# ── Read tool input once, up front (stdin can only be read once) ──
INPUT=$(cat)
BLOCK_REASON=""

# Extract tool name from JSON stdin (Claude Code passes it in the JSON payload, NOT as an env var)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)
if [[ -z "$TOOL_NAME" ]]; then
  # Fallback: check env var (in case Claude Code version sets it)
  TOOL_NAME="${TOOL_NAME:-}"
fi

# ── Identify current agent ──
CURRENT_AGENT="${HERMETIC_AGENT:-}"
IN_WORKFLOW=false
if [[ -z "$CURRENT_AGENT" ]]; then
  local_state="${CLAUDE_PROJECT_DIR:-}/workflow/state/current-agent.txt"
  if [[ -f "$local_state" ]]; then
    IN_WORKFLOW=true
    CURRENT_AGENT=$(cat "$local_state" 2>/dev/null || echo "")
  fi
else
  IN_WORKFLOW=true
fi

# ── Debug trace — logs EVERY hook invocation ──
TRACE_LOG="${CLAUDE_PROJECT_DIR:-/tmp}/workflow/state/guard-trace.log"
{
  trace_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.pattern // .tool_input.path // empty' 2>/dev/null | head -c 120)
  trace_cmd=""
  if [[ "$TOOL_NAME" == "Bash" ]]; then
    trace_cmd=$(echo "$INPUT" | jq -r '.tool_input.command // .command // empty' 2>/dev/null | head -c 120)
  fi
  if [[ -n "$trace_cmd" ]]; then
    echo "[$(date '+%H:%M:%S')] agent=${CURRENT_AGENT:-EMPTY} tool=${TOOL_NAME:-EMPTY} cmd=${trace_cmd}"
  else
    echo "[$(date '+%H:%M:%S')] agent=${CURRENT_AGENT:-EMPTY} tool=${TOOL_NAME:-EMPTY} path=${trace_path}"
  fi
} >> "$TRACE_LOG" 2>/dev/null || true

# Dump first raw JSON for structure debugging (one-time)
DEBUG_DUMP="${CLAUDE_PROJECT_DIR:-/tmp}/workflow/state/guard-debug-input.json"
if [[ ! -f "$DEBUG_DUMP" ]]; then
  echo "$INPUT" | jq '.' > "$DEBUG_DUMP" 2>/dev/null || echo "$INPUT" > "$DEBUG_DUMP"
fi

# ── Universal block: node_modules is off-limits to ALL agents ──
nm_path=""
case "$TOOL_NAME" in
  Read|Write|Edit) nm_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // .file_path // empty' 2>/dev/null) ;;
  Grep) nm_path=$(echo "$INPUT" | jq -r '.tool_input.path // .path // empty' 2>/dev/null) ;;
  Glob) nm_path=$(echo "$INPUT" | jq -r '.tool_input.pattern // .pattern // empty' 2>/dev/null) ;;
  Bash) nm_path=$(echo "$INPUT" | jq -r '.tool_input.command // .command // empty' 2>/dev/null) ;;
esac
if [[ "${nm_path:-}" == *"node_modules"* ]]; then
  echo "BLOCKED: node_modules/ is off-limits to all agents." >&2
  exit 2
fi

# Architect: unrestricted reads/glob/grep, restricted writes and bash
if [[ "$CURRENT_AGENT" == "architect" ]]; then
  case "$TOOL_NAME" in
    Write|Edit)
      file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // .file_path // empty' 2>/dev/null)
      file_path=$(rel_path "$file_path")
      if matches_any "$file_path" \
        'CLAUDE.md' \
        '.claude/agents/*' \
        'example-ui-rules/*' \
        'workflow/tasks.md' 'workflow/state/*'; then
        exit 0
      fi
      echo "BLOCKED: architect cannot write to '$file_path'. Only CLAUDE.md, agent defs, lint rules, and tasks." >&2
      log_block "architect | ${TOOL_NAME} | $file_path"
      exit 2
      ;;
    Bash)
      # Architect gets unrestricted bash for npm install, lint setup, etc.
      exit 0
      ;;
    *)
      # Reads, Glob, Grep — unrestricted
      exit 0
      ;;
  esac
fi

# Unknown/empty agent
if [[ -z "$CURRENT_AGENT" ]]; then
  if [[ "$IN_WORKFLOW" == true ]]; then
    # current-agent.txt exists but is empty — likely a bypass attempt.
    # Block writes, allow reads.
    case "$TOOL_NAME" in
      Write|Edit|Bash)
        echo "BLOCKED: agent identity is empty but workflow is active. Cannot write without a valid agent identity." >&2
        log_block "EMPTY_AGENT | ${TOOL_NAME} | bypass attempt"
        exit 2
        ;;
      *)
        exit 0
        ;;
    esac
  else
    # No current-agent.txt file at all — not in workflow mode, allow everything
    exit 0
  fi
fi

# ── Per-agent READ restrictions ──
# Returns 0 if read is allowed, 1 if blocked
check_read() {
  local path="$1"

  case "$CURRENT_AGENT" in
    orchestrator)
      # Orchestrator: unrestricted reads for workflow state, tasks, agent defs
      ;;
    coder|scaffolder)
      # Coder/Scaffolder cannot read: tests, lint rules, agent defs, review state
      if matches_any "$path" '*.test.*' '*.spec.*' '__tests__/*' 'tests/*'; then
        BLOCK_REASON="Test files are hidden from the ${CURRENT_AGENT}. Write code that fulfills the task description — tests are the test-maker's job."
        return 1
      fi
      if matches_any "$path" \
        'example-ui-rules/eslint-rules/*' 'example-ui-rules/stylelint-rules/*' \
        'example-ui-rules/bin/*' 'example-ui-rules/.eslintrc*' \
        'eslint-config.*' '.eslintrc*' 'stylelint.config.*'; then
        BLOCK_REASON="Lint rules are hidden from the ${CURRENT_AGENT}."
        return 1
      fi
      if matches_any "$path" '.claude/agents/*'; then
        BLOCK_REASON="Agent definitions are off-limits to the ${CURRENT_AGENT}."
        return 1
      fi
      if matches_any "$path" \
        'workflow/state/review-feedback.md' 'workflow/state/review-status.txt' \
        'workflow/state/escalation-context.md'; then
        BLOCK_REASON="Review state is off-limits. The orchestrator will provide feedback if you need to retry."
        return 1
      fi
      ;;
    planner)
      # Planner cannot read: tests, lint rules, or agent defs
      if matches_any "$path" '*.test.*' '*.spec.*' '__tests__/*' 'tests/*'; then
        BLOCK_REASON="Test files are hidden from the planner. Plan from task descriptions and source code only."
        return 1
      fi
      if matches_any "$path" '.claude/agents/*'; then
        BLOCK_REASON="Agent definitions are off-limits to the planner."
        return 1
      fi
      if matches_any "$path" \
        'example-ui-rules/eslint-rules/*' 'example-ui-rules/stylelint-rules/*' \
        'example-ui-rules/bin/*'; then
        BLOCK_REASON="Lint rules are hidden from the planner."
        return 1
      fi
      ;;
    test-maker)
      # Test-maker cannot read: lint rules, agent defs
      if matches_any "$path" '.claude/agents/*'; then
        BLOCK_REASON="Agent definitions are off-limits to the test-maker."
        return 1
      fi
      if matches_any "$path" \
        'example-ui-rules/eslint-rules/*' 'example-ui-rules/stylelint-rules/*' \
        'example-ui-rules/bin/*'; then
        BLOCK_REASON="Lint rules are hidden from the test-maker."
        return 1
      fi
      ;;
    reviewer)
      # Reviewer works from test/lint OUTPUT only — cannot read source files for either.
      if matches_any "$path" '*.test.*' '*.spec.*' '__tests__/*' 'tests/*'; then
        BLOCK_REASON="Test SOURCE files are hidden from the reviewer. Run tests with 'npm test' and judge from the output only."
        return 1
      fi
      if matches_any "$path" \
        'example-ui-rules/eslint-rules/*' 'example-ui-rules/stylelint-rules/*' \
        'example-ui-rules/bin/*' 'example-ui-rules/.eslintrc*' \
        'eslint-config.*' '.eslintrc*' 'stylelint.config.*'; then
        BLOCK_REASON="Lint rule SOURCE files are hidden from the reviewer. Run lint and judge from the output only."
        return 1
      fi
      ;;
  esac
  return 0
}

# ── Per-agent WRITE restrictions ──
# Uses an allowlist: only paths matching allowed patterns can be written.
# Returns 0 if write is allowed, 1 if blocked.
check_write() {
  local path="$1"

  # current-agent.txt is a coordination file — the orchestrator must update it
  # between every Task() spawn, even when the guard thinks a subagent is active.
  # Allow ALL agents to write it, but ONLY with valid agent names.
  # This prevents agents from clearing it to get empty-agent (allow-all) bypass.
  if [[ "$path" == "workflow/state/current-agent.txt" ]]; then
    local content
    content=$(echo "$INPUT" | jq -r '.tool_input.content // .content // empty' 2>/dev/null)
    content=$(echo "$content" | tr -d '[:space:]')  # strip whitespace/newlines
    case "$content" in
      orchestrator|architect|planner|scaffolder|test-maker|coder|reviewer|closer)
        return 0
        ;;
      *)
        BLOCK_REASON="Only valid agent names can be written to current-agent.txt."
        return 1
        ;;
    esac
  fi

  case "$CURRENT_AGENT" in
    orchestrator)
      # Orchestrator can only write workflow state files and tasks — no source, no tests
      if matches_any "$path" \
        'workflow/tasks.md' 'workflow/state/*'; then
        return 0
      fi
      return 1
      ;;
    coder|scaffolder)
      # Coder/Scaffolder can write source code + config — no tests, no rules, no state, no workflow
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
      # Planner can only write: tasks.md, its own context file, and task-type.txt
      if matches_any "$path" \
        'workflow/tasks.md' 'workflow/state/planner-context.md' 'workflow/state/task-type.txt'; then
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
    closer)
      # Closer can only write: usage log and task-complete sentinel
      if matches_any "$path" \
        'workflow/state/usage-log.md' 'workflow/state/task-complete'; then
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
    orchestrator|closer)
      # Orchestrator and Closer have no Glob access
      return 1
      ;;
    coder|scaffolder)
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
      if [[ "$pattern" == *".test."* || "$pattern" == *".spec."* || "$pattern" == *"__tests__"* || "$pattern" == *"tests/"* ]]; then
        return 1
      fi
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
      # Reviewer cannot glob test files or lint rules
      if [[ "$pattern" == *".test."* || "$pattern" == *".spec."* || "$pattern" == *"__tests__"* || "$pattern" == *"tests/"* ]]; then
        return 1
      fi
      for forbidden_dir in "example-ui-rules/eslint-rules" "example-ui-rules/stylelint-rules" "example-ui-rules/bin"; do
        if [[ "$pattern" == *"$forbidden_dir"* ]]; then
          return 1
        fi
      done
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
    orchestrator)
      # Orchestrator has no Bash access — only Read and Write via dedicated tools
      return 1
      ;;
    closer)
      # Closer: read-only commands for finding and parsing transcript JSONL
      [[ "$cmd" == ls\ * ]] && return 0
      [[ "$cmd" == grep\ * ]] && return 0
      [[ "$cmd" == jq\ * ]] && return 0
      [[ "$cmd" == head\ * ]] && return 0
      [[ "$cmd" == tail\ * ]] && return 0
      [[ "$cmd" == cat\ * ]] && return 0
      [[ "$cmd" == wc\ * ]] && return 0
      [[ "$cmd" == date* ]] && return 0   # timestamps
      [[ "$cmd" == echo\ * ]] && return 0 # variable output
      [[ "$cmd" == expr\ * ]] && return 0 # arithmetic
      [[ "$cmd" == sed\ * ]] && return 0  # path slug
      return 1
      ;;
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
    scaffolder)
      # Forbidden path check — same as coder
      for forbidden in ".claude/agents/" "example-ui-rules/eslint-rules" "example-ui-rules/stylelint-rules" "example-ui-rules/bin" "review-feedback.md" "review-status.txt" "escalation-context.md"; do
        if [[ "$cmd" == *"$forbidden"* ]]; then
          return 1
        fi
      done
      # Block test file references
      if [[ "$cmd" == *".test."* || "$cmd" == *".spec."* || "$cmd" == *"__tests__"* ]]; then
        return 1
      fi
      # Directory creation
      [[ "$cmd" == mkdir\ * ]] && return 0
      # npm install (but NOT npm test or npx — scaffolder doesn't run tests)
      [[ "$cmd" == npm\ install* ]] && return 0
      [[ "$cmd" == npm\ i\ * ]] && return 0
      # Node / TypeScript (verify setup)
      [[ "$cmd" == node\ * ]] && return 0
      [[ "$cmd" == tsc* ]] && return 0
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
    fi
    # Allow $() for closer — all individual commands are read-only restricted
    # shell_writes_to_file() already ran on full_cmd above, blocking redirects/rm/cp/mv/etc.
    if [[ "$CURRENT_AGENT" == "closer" ]]; then
      return 0
    fi
    return 1
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

# ── Main dispatch ──

extract_and_check() {
  local blocked=0

  case "$TOOL_NAME" in
    Read)
      local file_path
      file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // .file_path // empty' 2>/dev/null)
      if [[ -n "$file_path" ]]; then
        file_path=$(rel_path "$file_path")
        BLOCK_REASON=""
        if ! check_read "$file_path"; then
          local msg="BLOCKED: ${CURRENT_AGENT} cannot read '$file_path'."
          [[ -n "$BLOCK_REASON" ]] && msg="$msg $BLOCK_REASON"
          echo "$msg" >&2
          log_block "${CURRENT_AGENT} | Read | $file_path"
          blocked=1
        fi
      fi
      ;;

    Write|Edit)
      local file_path
      file_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // .file_path // empty' 2>/dev/null)
      if [[ -n "$file_path" ]]; then
        file_path=$(rel_path "$file_path")
        BLOCK_REASON=""
        if ! check_write "$file_path"; then
          local msg="BLOCKED: ${CURRENT_AGENT} cannot write to '$file_path'."
          [[ -n "$BLOCK_REASON" ]] && msg="$msg $BLOCK_REASON"
          echo "$msg" >&2
          log_block "${CURRENT_AGENT} | ${TOOL_NAME} | $file_path"
          blocked=1
        fi
      fi
      ;;

    Glob)
      local pattern
      pattern=$(echo "$INPUT" | jq -r '.tool_input.pattern // .pattern // empty' 2>/dev/null)
      if [[ -n "$pattern" ]]; then
        BLOCK_REASON=""
        if ! check_glob "$pattern"; then
          local msg="BLOCKED: ${CURRENT_AGENT} cannot glob '$pattern'."
          [[ -n "$BLOCK_REASON" ]] && msg="$msg $BLOCK_REASON"
          echo "$msg" >&2
          log_block "${CURRENT_AGENT} | Glob | $pattern"
          blocked=1
        fi
      fi
      ;;

    Grep)
      local path
      path=$(echo "$INPUT" | jq -r '.tool_input.path // .path // empty' 2>/dev/null)
      if [[ -n "$path" ]]; then
        path=$(rel_path "$path")
        BLOCK_REASON=""
        if ! check_read "$path"; then
          local msg="BLOCKED: ${CURRENT_AGENT} cannot search in '$path'."
          [[ -n "$BLOCK_REASON" ]] && msg="$msg $BLOCK_REASON"
          echo "$msg" >&2
          log_block "${CURRENT_AGENT} | Grep | $path"
          blocked=1
        fi
      fi
      local glob
      glob=$(echo "$INPUT" | jq -r '.tool_input.glob // .glob // empty' 2>/dev/null)
      if [[ -n "$glob" ]]; then
        BLOCK_REASON=""
        if ! check_glob "$glob"; then
          local msg="BLOCKED: ${CURRENT_AGENT} cannot search with glob '$glob'."
          [[ -n "$BLOCK_REASON" ]] && msg="$msg $BLOCK_REASON"
          echo "$msg" >&2
          log_block "${CURRENT_AGENT} | Grep(glob) | $glob"
          blocked=1
        fi
      fi
      ;;

    Bash)
      local command
      command=$(echo "$INPUT" | jq -r '.tool_input.command // .command // empty' 2>/dev/null)
      if [[ -n "$command" ]]; then
        BLOCK_REASON=""
        if ! check_bash "$command"; then
          local msg="BLOCKED: ${CURRENT_AGENT} cannot run this command."
          [[ -n "$BLOCK_REASON" ]] && msg="$msg $BLOCK_REASON"
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
