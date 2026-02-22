#!/usr/bin/env bash
# orchestrator.sh — Launches the hermetic TDD workflow.
#
# Runs two phases:
#   1. Architect agent (interactive setup, runs once)
#   2. Orchestrator agent (processes all tasks via Ralph Wiggum loop)
#
# Prerequisites:
#   Install the Ralph Wiggum plugin in Claude Code:
#     /plugin marketplace add anthropics/claude-code
#     /plugin install ralph-wiggum@anthropics-claude-code
#
# Usage:
#   ./orchestrator.sh                        # Full run (setup + loop)
#   ./orchestrator.sh --skip-setup           # Skip architect setup, go straight to loop
#   ./orchestrator.sh --dangerously-skip-permissions  # Skip permission prompts (hooks are the real guard)

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATE_DIR="$PROJECT_DIR/workflow/state"

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()  { echo -e "${BLUE}[orchestrator]${NC} $*"; }
ok()   { echo -e "${GREEN}[orchestrator]${NC} $*"; }
warn() { echo -e "${YELLOW}[orchestrator]${NC} $*"; }

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# Parse args
skip_setup=false
skip_permissions=""
for arg in "$@"; do
  case "$arg" in
    --skip-setup|--loop-only) skip_setup=true ;;
    --dangerously-skip-permissions) skip_permissions="--dangerously-skip-permissions" ;;
  esac
done

# Phase 1: Setup (Architect agent — interactive)
if [[ "$skip_setup" == false ]]; then
  log "═══════════════════════════════════════════════════"
  log "  SETUP PHASE — Architect Agent (Interactive)"
  log "═══════════════════════════════════════════════════"
  echo ""
  log "The Architect will set up CLAUDE.md, per-agent context,"
  log "lint rules, and the task list."
  echo ""

  # Set agent identity BEFORE launching Claude so guards apply from the first tool call
  echo "architect" > "$STATE_DIR/current-agent.txt"

  claude --agent architect $skip_permissions

  ok "Setup complete. Project context and tasks are ready."
  echo ""
else
  log "Skipping setup (--skip-setup)."
fi

# Phase 2: The Loop (Orchestrator agent — processes all tasks)
log "═══════════════════════════════════════════════════"
log "  LOOP PHASE — Orchestrator Agent (Ralph Wiggum)"
log "═══════════════════════════════════════════════════"
echo ""
log "The orchestrator will process all tasks from workflow/tasks.md."
log "It runs inside a Ralph Wiggum loop until all tasks are complete."
log "You will be consulted if escalation is needed."
echo ""

# Set agent identity BEFORE launching Claude so guards apply from the first tool call
echo "orchestrator" > "$STATE_DIR/current-agent.txt"

claude --agent orchestrator $skip_permissions

ok "Workflow complete."
