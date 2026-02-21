#!/usr/bin/env bash
# init.sh — Bootstrap the hermetic workflow into a target project.
#
# Usage:
#   # From the hermetic-workflow repo:
#   ./init.sh /path/to/my-project
#
#   # Or clone + init in one shot:
#   git clone git@github.com:davstr1/hermetic-workflow.git /tmp/hw && /tmp/hw/init.sh /path/to/my-project
#
# What it does:
#   - Copies all workflow files into the target project
#   - Preserves any existing files in the target (no overwrites without confirmation)
#   - Installs the example-ui-rules linter dependencies
#   - Creates the workflow/state/ directory
#   - Makes scripts executable

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log()  { echo -e "${BLUE}[init]${NC} $*"; }
ok()   { echo -e "${GREEN}[init]${NC} $*"; }
warn() { echo -e "${YELLOW}[init]${NC} $*"; }
err()  { echo -e "${RED}[init]${NC} $*"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET="${1:-}"

if [[ -z "$TARGET" ]]; then
  echo "Usage: $0 /path/to/target-project"
  echo ""
  echo "Bootstraps the hermetic TDD workflow into the target project."
  exit 1
fi

# Resolve to absolute path
TARGET="$(cd "$TARGET" 2>/dev/null && pwd || mkdir -p "$TARGET" && cd "$TARGET" && pwd)"

log "Bootstrapping hermetic workflow into: $TARGET"
echo ""

# ── Copy workflow files ──

copy_if_missing() {
  local src="$1"
  local dest="$2"
  local dest_dir
  dest_dir=$(dirname "$dest")
  mkdir -p "$dest_dir"

  if [[ -f "$dest" ]]; then
    warn "EXISTS (skipping): $dest"
  else
    cp "$src" "$dest"
    ok "Copied: $dest"
  fi
}

copy_always() {
  local src="$1"
  local dest="$2"
  local dest_dir
  dest_dir=$(dirname "$dest")
  mkdir -p "$dest_dir"
  cp "$src" "$dest"
  ok "Copied: $dest"
}

# Core infrastructure — always overwrite (these are the workflow engine)
log "Copying workflow engine..."
copy_always "$SCRIPT_DIR/.claude/hooks/guard-files.sh"  "$TARGET/.claude/hooks/guard-files.sh"
copy_always "$SCRIPT_DIR/.claude/hooks/enforce-lint.sh" "$TARGET/.claude/hooks/enforce-lint.sh"
copy_always "$SCRIPT_DIR/.claude/settings.json"         "$TARGET/.claude/settings.json"
copy_always "$SCRIPT_DIR/orchestrator.sh"               "$TARGET/orchestrator.sh"

# Agent definitions — always overwrite (these define agent behavior)
log "Copying agent definitions..."
copy_always "$SCRIPT_DIR/.claude/agents/orchestrator.md" "$TARGET/.claude/agents/orchestrator.md"
copy_always "$SCRIPT_DIR/.claude/agents/architect.md"    "$TARGET/.claude/agents/architect.md"
copy_always "$SCRIPT_DIR/.claude/agents/planner.md"      "$TARGET/.claude/agents/planner.md"
copy_always "$SCRIPT_DIR/.claude/agents/test-maker.md"   "$TARGET/.claude/agents/test-maker.md"
copy_always "$SCRIPT_DIR/.claude/agents/coder.md"        "$TARGET/.claude/agents/coder.md"
copy_always "$SCRIPT_DIR/.claude/agents/reviewer.md"     "$TARGET/.claude/agents/reviewer.md"

# Templates — only copy if missing (user may have customized these)
log "Copying templates (skip if exist)..."
copy_if_missing "$SCRIPT_DIR/workflow/tasks.md"   "$TARGET/workflow/tasks.md"
copy_if_missing "$SCRIPT_DIR/CLAUDE.md"           "$TARGET/CLAUDE.md"

# Linter — copy the whole example-ui-rules directory
log "Copying linter (example-ui-rules)..."
if [[ -d "$TARGET/example-ui-rules" ]]; then
  warn "example-ui-rules/ already exists, skipping copy."
  warn "To update, delete it first and re-run init.sh"
else
  # Copy everything except node_modules and .git
  rsync -a \
    --exclude='node_modules' \
    --exclude='.git' \
    --exclude='.DS_Store' \
    --exclude='dist' \
    "$SCRIPT_DIR/example-ui-rules/" "$TARGET/example-ui-rules/"
  ok "Copied example-ui-rules/"
fi

# ── Make scripts executable ──
chmod +x "$TARGET/orchestrator.sh"
chmod +x "$TARGET/.claude/hooks/guard-files.sh"
chmod +x "$TARGET/.claude/hooks/enforce-lint.sh"

# ── Create state directory ──
mkdir -p "$TARGET/workflow/state"

# ── Install linter dependencies ──
if [[ -f "$TARGET/example-ui-rules/package.json" ]]; then
  log "Installing linter dependencies..."
  (cd "$TARGET/example-ui-rules" && npm install --silent 2>&1) || warn "npm install failed — run manually in example-ui-rules/"
  ok "Linter dependencies installed."
fi

# ── Summary ──
echo ""
ok "══════════════════════════════════════════════"
ok "  Hermetic workflow bootstrapped!"
ok "══════════════════════════════════════════════"
echo ""
log "Next steps:"
echo "  cd $TARGET"
echo "  ./orchestrator.sh          # Run setup + task loop"
echo ""
log "Or skip setup if you already have tasks defined:"
echo "  ./orchestrator.sh --skip-setup"
echo ""
