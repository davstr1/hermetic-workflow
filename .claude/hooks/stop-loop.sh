#!/usr/bin/env bash
# stop-loop.sh — Stop hook that keeps the orchestrator looping until all tasks are done.
#
# When Claude tries to exit:
#   1. If stop_hook_active=true → allow exit (prevent infinite re-entry)
#   2. If last message contains the completion promise → allow exit
#   3. If unchecked tasks remain → block exit, re-feed the pipeline prompt
#
# This is the same mechanism the Ralph Wiggum plugin uses.

set -euo pipefail

INPUT=$(cat)

# Prevent infinite re-entry
STOP_HOOK_ACTIVE=$(echo "$INPUT" | jq -r '.stop_hook_active // false')
if [ "$STOP_HOOK_ACTIVE" = "true" ]; then
  exit 0
fi

# Check for completion promise
LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // ""')
if echo "$LAST_MSG" | grep -q '<promise>TASKS_COMPLETE</promise>'; then
  exit 0
fi

# Check if unchecked tasks remain
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')
TASKS_FILE="$CWD/workflow/tasks.md"

if [ ! -f "$TASKS_FILE" ]; then
  exit 0
fi

REMAINING=$(grep -c '^\- \[ \]' "$TASKS_FILE" 2>/dev/null || echo "0")

if [ "$REMAINING" -eq 0 ]; then
  exit 0
fi

# Tasks remain — block exit and re-feed the orchestrator
jq -n \
  --arg remaining "$REMAINING" \
  '{
    "decision": "block",
    "reason": ("There are still " + $remaining + " unchecked tasks in workflow/tasks.md. Go back to step 1: spawn the Planner for the next unchecked task, then Test Maker, then Coder, then Reviewer. Every task starts at step 1.")
  }'
exit 0
