#!/usr/bin/env bash
# orchestrator.sh — Launches the hermetic TDD workflow.
#
# Default: runs the Architect agent, which does interactive setup
# then spawns the Orchestrator as a subagent to process all tasks.
#
# --skip-setup: skip the Architect and run the Orchestrator directly.
#
# Usage:
#   ./orchestrator.sh                        # Full run (architect → orchestrator)
#   ./orchestrator.sh --skip-setup           # Skip architect, go straight to loop
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
skip_setup=false
skip_permissions=""
for arg in "$@"; do
  case "$arg" in
    --skip-setup|--loop-only) skip_setup=true ;;
    --dangerously-skip-permissions) skip_permissions="--dangerously-skip-permissions" ;;
  esac
done

if [[ "$skip_setup" == false ]]; then
  log "Starting Architect (interactive setup → orchestrator handoff)"
  echo ""

  echo "architect" > "$STATE_DIR/current-agent.txt"
  claude --agent architect $skip_permissions

else
  log "Skipping setup — launching Orchestrator directly"
  echo ""

  echo "orchestrator" > "$STATE_DIR/current-agent.txt"
  claude --agent orchestrator $skip_permissions
fi

ok "Workflow complete."
