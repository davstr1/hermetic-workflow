#!/usr/bin/env bash
# orchestrator.sh — Launches the hermetic TDD workflow.
#
# Bash handles routing and looping. The orchestrator is invoked once per task
# with fresh context, preventing stale accumulation.
#
# Flow:
#   1. Git pre-flight (init repo + remote if needed)
#   2. If no tasks exist → run architect for interactive setup
#   3. While unchecked tasks remain → run orchestrator (one task per session)
#
# Usage:
#   ./orchestrator.sh                                # Full run
#   ./orchestrator.sh --dangerously-skip-permissions  # Skip permission prompts (hooks are the real guard)

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$PROJECT_DIR/workflow/state"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${BLUE}[orchestrator]${NC} $*"; }
ok()   { echo -e "${GREEN}[orchestrator]${NC} $*"; }
warn() { echo -e "${YELLOW}[orchestrator]${NC} $*"; }

# Ensure state directory exists
mkdir -p "$STATE_DIR"
BLOCK_LOG="$STATE_DIR/guard-blocks.log"

# ── Git repo pre-flight ──
# If no git repo exists, initialize one and create a private GitHub remote.
if ! git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree &>/dev/null; then
  log "No git repo found — initializing..."
  git -C "$PROJECT_DIR" init
  git -C "$PROJECT_DIR" add -A
  git -C "$PROJECT_DIR" commit -m "Initial commit"
  ok "Git repo initialized."
fi

if ! git -C "$PROJECT_DIR" remote get-url origin &>/dev/null; then
  log "No GitHub remote — creating private repo..."
  repo_name=$(basename "$PROJECT_DIR")
  gh repo create "$repo_name" --private --source "$PROJECT_DIR" --push
  ok "Private repo created and pushed: $repo_name"
fi

# Parse args
skip_permissions=""
for arg in "$@"; do
  case "$arg" in
    --dangerously-skip-permissions) skip_permissions="--dangerously-skip-permissions" ;;
  esac
done

# ── Setup check ──
# If no tasks exist, run the architect for interactive setup.
if ! grep -q '^\- \[' "$PROJECT_DIR/workflow/tasks.md" 2>/dev/null; then
  log "No tasks found — running Architect for setup..."
  echo ""

  echo "architect" > "$STATE_DIR/current-agent.txt"
  claude --agent architect $skip_permissions || true
fi

# ── Task loop: one task per session, fresh context ──
log "Starting task loop..."
echo ""

# Clear block log before starting
> "$BLOCK_LOG" 2>/dev/null || true

SENTINEL="$STATE_DIR/task-complete"
TOTAL_ACTIVE_TIME=0

while grep -q '^\- \[ \]' "$PROJECT_DIR/workflow/tasks.md" 2>/dev/null; do
  remaining=$(grep -c '^\- \[ \]' "$PROJECT_DIR/workflow/tasks.md" 2>/dev/null || echo "0")
  log "Tasks remaining: $remaining"

  # Track blocks from this session
  blocks_before=0
  if [[ -f "$BLOCK_LOG" ]]; then
    blocks_before=$(wc -l < "$BLOCK_LOG" 2>/dev/null || echo "0")
  fi

  # Clear sentinel and record start time
  rm -f "$SENTINEL"
  date +%s > "$STATE_DIR/task-start-time.txt"

  # Launch orchestrator in background
  echo "orchestrator" > "$STATE_DIR/current-agent.txt"
  echo "Process the next unchecked task from workflow/tasks.md. Run the full pipeline: Planner → Test Maker → Coder → Reviewer." \
    | claude --agent orchestrator $skip_permissions &
  CLAUDE_PID=$!

  # Watch for sentinel — kill session when task is done
  while kill -0 "$CLAUDE_PID" 2>/dev/null; do
    if [[ -f "$SENTINEL" ]]; then
      log "Task complete. Killing session for fresh context..."
      kill "$CLAUDE_PID" 2>/dev/null
      wait "$CLAUDE_PID" 2>/dev/null || true
      break
    fi
    sleep 2
  done

  # If process exited on its own (no sentinel), still reap it
  wait "$CLAUDE_PID" 2>/dev/null || true
  rm -f "$SENTINEL"

  # Track task duration
  task_start=$(cat "$STATE_DIR/task-start-time.txt" 2>/dev/null || echo "0")
  task_end=$(date +%s)
  task_duration=$((task_end - task_start))
  TOTAL_ACTIVE_TIME=$((TOTAL_ACTIVE_TIME + task_duration))
  task_min=$((task_duration / 60))
  task_sec=$((task_duration % 60))
  log "Task duration: ${task_min}m ${task_sec}s"

  # Report blocks from this session
  if [[ -f "$BLOCK_LOG" ]]; then
    blocks_after=$(wc -l < "$BLOCK_LOG" 2>/dev/null || echo "0")
    new_blocks=$((blocks_after - blocks_before))
    if [[ $new_blocks -gt 0 ]]; then
      echo ""
      warn "═══ Guard blocked $new_blocks tool calls during this task ═══"
      tail -n "$new_blocks" "$BLOCK_LOG" | while IFS= read -r line; do
        echo -e "  ${RED}✗${NC} $line"
      done
      echo ""
    fi
  fi
done

# Final summary
if [[ -f "$BLOCK_LOG" ]] && [[ -s "$BLOCK_LOG" ]]; then
  total_blocks=$(wc -l < "$BLOCK_LOG" 2>/dev/null || echo "0")
  echo ""
  warn "═══ Total guard blocks across all tasks: $total_blocks ═══"
  warn "Full log: $BLOCK_LOG"
  echo ""
fi

# Total active time
total_min=$((TOTAL_ACTIVE_TIME / 60))
total_sec=$((TOTAL_ACTIVE_TIME % 60))
ok "All tasks complete. Workflow finished."
ok "Total active time: ${total_min}m ${total_sec}s"
if [[ -f "$STATE_DIR/usage-log.md" ]]; then
  ok "Usage log: $STATE_DIR/usage-log.md"
fi
