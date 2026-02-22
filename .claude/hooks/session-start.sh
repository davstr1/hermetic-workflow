#!/usr/bin/env bash
# session-start.sh — Captures session ID for transcript lookup.
#
# Claude Code passes session_id in the SessionStart JSON payload.
# We write it to workflow/state/session-id.txt so the closer agent
# can find the exact transcript JSONL file.
#
# Also injects CLAUDE_CODE_SESSION_ID into the shell environment
# via CLAUDE_ENV_FILE so Bash tool calls can access it.

INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)

if [[ -z "$SESSION_ID" ]]; then
  exit 0
fi

# Write session ID to state file
STATE_DIR="${CLAUDE_PROJECT_DIR:-}/workflow/state"
if [[ -d "$STATE_DIR" ]] || mkdir -p "$STATE_DIR" 2>/dev/null; then
  echo "$SESSION_ID" > "$STATE_DIR/session-id.txt" 2>/dev/null || true
fi

# Inject into shell environment for Bash tool calls
if [[ -n "${CLAUDE_ENV_FILE:-}" ]] && ! grep -q "CLAUDE_CODE_SESSION_ID" "$CLAUDE_ENV_FILE" 2>/dev/null; then
  echo "export CLAUDE_CODE_SESSION_ID=\"$SESSION_ID\"" >> "$CLAUDE_ENV_FILE" 2>/dev/null || true
fi
