#!/usr/bin/env bash
# orchestrator.sh — The Ralph Wiggum Loop (thin wrapper)
#
# Runs the hermetic TDD workflow using native Claude Code agents:
#   1. Architect agent (interactive setup, runs once)
#   2. Orchestrator agent (processes all tasks in a loop)
#
# Usage:
#   ./orchestrator.sh              # Full run (setup + loop)
#   ./orchestrator.sh --skip-setup # Skip architect setup, go straight to loop
#   ./orchestrator.sh --loop-only  # Alias for --skip-setup

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
for arg in "$@"; do
  case "$arg" in
    --skip-setup|--loop-only) skip_setup=true ;;
  esac
done

# Phase 1: Setup (Architect agent — interactive)
if [[ "$skip_setup" == false ]]; then
  log "═══════════════════════════════════════════════════"
  log "  SETUP PHASE — Architect Agent (Interactive)"
  log "═══════════════════════════════════════════════════"
  echo ""
  log "The Architect will help you set up project principles,"
  log "configure lint rules, and create the task list."
  echo ""

  claude --agent architect

  ok "Setup complete. Principles and tasks are ready."
  echo ""
else
  log "Skipping setup (--skip-setup)."
fi

# Phase 2: The Loop (Orchestrator agent — processes all tasks)
log "═══════════════════════════════════════════════════"
log "  LOOP PHASE — Orchestrator Agent"
log "═══════════════════════════════════════════════════"
echo ""

claude --agent orchestrator

ok "Workflow complete."
