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
NC='\033[0m'

log()  { echo -e "${BLUE}[orchestrator]${NC} $*"; }
ok()   { echo -e "${GREEN}[orchestrator]${NC} $*"; }

# Ensure state directory exists
mkdir -p "$STATE_DIR"

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

while grep -q '^\- \[ \]' "$PROJECT_DIR/workflow/tasks.md" 2>/dev/null; do
  remaining=$(grep -c '^\- \[ \]' "$PROJECT_DIR/workflow/tasks.md" 2>/dev/null || echo "0")
  log "Tasks remaining: $remaining"

  echo "orchestrator" > "$STATE_DIR/current-agent.txt"
  echo "Process the next unchecked task from workflow/tasks.md. Run the full pipeline: Planner → Test Maker → Coder → Reviewer." | claude --agent orchestrator $skip_permissions || true
done

ok "All tasks complete. Workflow finished."
