#!/usr/bin/env bash
# guard-files.sh — Lightweight PreToolUse hook.
#
# America edition: no per-agent isolation. Only prevents catastrophic
# operations (node_modules access, destructive git, etc.).
#
# Exit codes:
#   0 = allow (tool proceeds)
#   2 = block (tool is denied, stderr shown to agent)

# ── Read tool input once ──
INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)

# ── Agent identity (for logging only, not enforcement) ──
CURRENT_AGENT="${HERMETIC_AGENT:-}"
if [[ -z "$CURRENT_AGENT" ]]; then
  local_state="${CLAUDE_PROJECT_DIR:-}/workflow/state/current-agent.txt"
  if [[ -f "$local_state" ]]; then
    CURRENT_AGENT=$(cat "$local_state" 2>/dev/null || echo "")
  fi
fi

# ── Debug trace ──
TRACE_LOG="${CLAUDE_PROJECT_DIR:-/tmp}/workflow/state/guard-trace.log"
{
  trace_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.pattern // .tool_input.path // empty' 2>/dev/null | head -c 120)
  trace_cmd=""
  if [[ "$TOOL_NAME" == "Bash" ]]; then
    trace_cmd=$(echo "$INPUT" | jq -r '.tool_input.command // .command // empty' 2>/dev/null | head -c 120)
  fi
  if [[ -n "$trace_cmd" ]]; then
    echo "[$(date '+%H:%M:%S')] agent=${CURRENT_AGENT:-NONE} tool=${TOOL_NAME:-EMPTY} cmd=${trace_cmd}"
  else
    echo "[$(date '+%H:%M:%S')] agent=${CURRENT_AGENT:-NONE} tool=${TOOL_NAME:-EMPTY} path=${trace_path}"
  fi
} >> "$TRACE_LOG" 2>/dev/null || true

# ── Universal: node_modules is off-limits ──
nm_path=""
case "$TOOL_NAME" in
  Read|Write|Edit) nm_path=$(echo "$INPUT" | jq -r '.tool_input.file_path // .file_path // empty' 2>/dev/null) ;;
  Grep) nm_path=$(echo "$INPUT" | jq -r '.tool_input.path // .path // empty' 2>/dev/null) ;;
  Glob) nm_path=$(echo "$INPUT" | jq -r '.tool_input.pattern // .pattern // empty' 2>/dev/null) ;;
  Bash) nm_path=$(echo "$INPUT" | jq -r '.tool_input.command // .command // empty' 2>/dev/null) ;;
esac
if [[ "${nm_path:-}" == *"node_modules"* ]]; then
  echo "BLOCKED: node_modules/ is off-limits." >&2
  exit 2
fi

# ── Block destructive git commands ──
if [[ "$TOOL_NAME" == "Bash" ]]; then
  cmd=$(echo "$INPUT" | jq -r '.tool_input.command // .command // empty' 2>/dev/null)
  if [[ "$cmd" == git\ push\ --force* || "$cmd" == git\ push\ -f* ]]; then
    echo "BLOCKED: force push is not allowed." >&2
    exit 2
  fi
  if [[ "$cmd" == git\ reset\ --hard* ]]; then
    echo "BLOCKED: git reset --hard is not allowed." >&2
    exit 2
  fi
  if [[ "$cmd" == git\ clean\ -f* ]]; then
    echo "BLOCKED: git clean -f is not allowed." >&2
    exit 2
  fi
  if [[ "$cmd" == rm\ -rf\ /* || "$cmd" == rm\ -rf\ ~* || "$cmd" == rm\ -rf\ \$HOME* ]]; then
    echo "BLOCKED: recursive delete of system paths is not allowed." >&2
    exit 2
  fi
fi

# Everything else: allowed
exit 0
