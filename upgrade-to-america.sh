#!/usr/bin/env bash
# upgrade-to-america.sh — Upgrade a project from USSR (hermetic isolation) to America (trust-based).
#
# Usage:
#   ./upgrade-to-america.sh /path/to/project
#
# What it does:
#   - Replaces agent definitions with America versions (trust-based, git-verified)
#   - Replaces guard-files.sh with lightweight catastrophic-only guard
#   - Removes USSR-only agents (scaffolder)
#   - Cleans up USSR-specific state files (task-type.txt)
#   - Updates orchestrator.sh and init.sh
#   - Commits the upgrade

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${BLUE}[upgrade]${NC} $*"; }
ok()   { echo -e "${GREEN}[upgrade]${NC} $*"; }
warn() { echo -e "${YELLOW}[upgrade]${NC} $*"; }
err()  { echo -e "${RED}[upgrade]${NC} $*"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 /path/to/project"
  echo ""
  echo "Upgrades a project from USSR (hermetic isolation) to America (trust-based)."
  echo "Run this from the hermetic-workflow repo on the 'america' branch."
  exit 1
fi

[[ -d "$TARGET" ]] || err "Target directory does not exist: $TARGET"
TARGET="$(cd "$TARGET" && pwd)"

# Verify we're on the america branch
current_branch=$(git -C "$SCRIPT_DIR" branch --show-current 2>/dev/null || echo "")
if [[ "$current_branch" != "america" ]]; then
  warn "Expected to run from 'america' branch, currently on '$current_branch'."
  warn "Proceeding anyway — make sure the source files are correct."
fi

# Verify target has an existing workflow
if [[ ! -d "$TARGET/.claude/agents" ]]; then
  err "No .claude/agents/ found in target. Run init.sh first, or is this the right directory?"
fi

log "Upgrading project to America edition: $TARGET"
echo ""

# ── Replace agent definitions ──
log "Replacing agent definitions..."

for agent in orchestrator.md architect.md planner.md test-maker.md coder.md reviewer.md closer.md; do
  if [[ -f "$SCRIPT_DIR/.claude/agents/$agent" ]]; then
    cp "$SCRIPT_DIR/.claude/agents/$agent" "$TARGET/.claude/agents/$agent"
    ok "Updated: $agent"
  fi
done

# Remove USSR-only agents
if [[ -f "$TARGET/.claude/agents/scaffolder.md" ]]; then
  rm "$TARGET/.claude/agents/scaffolder.md"
  ok "Removed: scaffolder.md (USSR-only)"
fi

# ── Replace guard-files.sh ──
log "Replacing guard-files.sh with lightweight version..."
cp "$SCRIPT_DIR/.claude/hooks/guard-files.sh" "$TARGET/.claude/hooks/guard-files.sh"
chmod +x "$TARGET/.claude/hooks/guard-files.sh"
ok "Guard replaced (catastrophic-only, no per-agent isolation)"

# ── Replace orchestrator.sh ──
log "Replacing orchestrator.sh..."
cp "$SCRIPT_DIR/orchestrator.sh" "$TARGET/orchestrator.sh"
chmod +x "$TARGET/orchestrator.sh"
ok "Updated orchestrator.sh"

# ── Clean USSR-specific state ──
log "Cleaning USSR-specific state files..."
rm -f "$TARGET/workflow/state/task-type.txt"
rm -f "$TARGET/workflow/state/current-agent.txt"
ok "Cleaned state files"

# ── Commit ──
if git -C "$TARGET" rev-parse --is-inside-work-tree &>/dev/null; then
  log "Committing upgrade..."
  git -C "$TARGET" add -A
  if ! git -C "$TARGET" diff --cached --quiet 2>/dev/null; then
    git -C "$TARGET" commit -m "chore: upgrade workflow from USSR to America edition

Switched from hermetic agent isolation to trust-based workflow:
- Agents have full codebase access (no per-agent file restrictions)
- Git history used to verify coder doesn't modify tests
- Guard reduced to catastrophic-only safety net
- Removed scaffolder agent (coder handles scaffolding)
- Each agent commits before handing off"
    ok "Committed upgrade."
  else
    log "No changes to commit."
  fi
fi

echo ""
ok "══════════════════════════════════════════════"
ok "  Upgraded to America edition!"
ok "══════════════════════════════════════════════"
echo ""
log "Changes:"
echo "  - Agents: planner, test-maker, coder, reviewer, closer (5 total)"
echo "  - Guard: catastrophic-only (no file isolation)"
echo "  - TDD: enforced by convention + git audit, not mechanical isolation"
echo ""
log "Run: cd $TARGET && ./orchestrator.sh"
echo ""
