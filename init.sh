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
#   - Commits and pushes only the modified files

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
[[ -d "$TARGET" ]] || mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

# Read version
VERSION="unknown"
if [[ -f "$SCRIPT_DIR/VERSION" ]]; then
  VERSION=$(cat "$SCRIPT_DIR/VERSION" | tr -d '[:space:]')
fi

log "Bootstrapping hermetic workflow v${VERSION} into: $TARGET"
echo ""

# Track modified files for git commit
MODIFIED_FILES=()

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
    MODIFIED_FILES+=("$dest")
    ok "Copied: $dest"
  fi
}

copy_always() {
  local src="$1"
  local dest="$2"
  local dest_dir
  dest_dir=$(dirname "$dest")
  mkdir -p "$dest_dir"

  # Only track as modified if content actually changed
  if [[ -f "$dest" ]] && diff -q "$src" "$dest" &>/dev/null; then
    return 0
  fi

  cp "$src" "$dest"
  MODIFIED_FILES+=("$dest")
  ok "Copied: $dest"
}

# Core infrastructure — always overwrite (these are the workflow engine)
log "Copying workflow engine..."
copy_always "$SCRIPT_DIR/.claude/hooks/guard-files.sh"  "$TARGET/.claude/hooks/guard-files.sh"
copy_always "$SCRIPT_DIR/.claude/hooks/enforce-lint.sh" "$TARGET/.claude/hooks/enforce-lint.sh"
copy_always "$SCRIPT_DIR/.claude/hooks/session-start.sh" "$TARGET/.claude/hooks/session-start.sh"
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
copy_always "$SCRIPT_DIR/.claude/agents/closer.md"      "$TARGET/.claude/agents/closer.md"
copy_always "$SCRIPT_DIR/.claude/agents/frontend-validator.md" "$TARGET/.claude/agents/frontend-validator.md"

# Version file — always overwrite
copy_always "$SCRIPT_DIR/VERSION" "$TARGET/VERSION"

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
  MODIFIED_FILES+=("$TARGET/example-ui-rules")
fi

# ── Make scripts executable ──
chmod +x "$TARGET/orchestrator.sh"
chmod +x "$TARGET/.claude/hooks/guard-files.sh"
chmod +x "$TARGET/.claude/hooks/enforce-lint.sh"
chmod +x "$TARGET/.claude/hooks/session-start.sh"

# ── Create state directory ──
mkdir -p "$TARGET/workflow/state"

# ── Ensure workflow state is gitignored ──
gitignore_file="$TARGET/.gitignore"
if ! grep -qF 'workflow/state/' "$gitignore_file" 2>/dev/null; then
  log "Adding workflow state to .gitignore..."
  {
    echo ""
    echo "# Workflow runtime state (generated per-run, never commit)"
    echo "workflow/state/"
  } >> "$gitignore_file"
  MODIFIED_FILES+=("$gitignore_file")
  ok "Added workflow/state/ to .gitignore"
fi

# ── Install linter dependencies ──
if [[ -f "$TARGET/example-ui-rules/package.json" ]]; then
  log "Installing linter dependencies..."
  (cd "$TARGET/example-ui-rules" && npm install --silent 2>&1) || warn "npm install failed — run manually in example-ui-rules/"
  ok "Linter dependencies installed."
fi

# ── Commit and push modified files ──
if [[ ${#MODIFIED_FILES[@]} -gt 0 ]] && git -C "$TARGET" rev-parse --is-inside-work-tree &>/dev/null; then
  log "Committing updated workflow files..."

  # Convert absolute paths to relative for git
  relative_files=()
  for f in "${MODIFIED_FILES[@]}"; do
    relative_files+=("${f#"$TARGET"/}")
  done

  log "Staging ${#relative_files[@]} files..."
  if ! git -C "$TARGET" add "${relative_files[@]}" 2>&1; then
    warn "git add failed — you may need to commit manually."
  fi

  # Only commit if there are staged changes
  if ! git -C "$TARGET" diff --cached --quiet 2>/dev/null; then
    if git -C "$TARGET" commit -m "chore: update hermetic workflow to v${VERSION}" 2>&1; then
      ok "Committed workflow update (v${VERSION})."
      if git -C "$TARGET" push 2>&1; then
        ok "Pushed to remote."
      else
        warn "Push failed — commit is local. Run 'git push' manually."
      fi
    else
      warn "Commit failed — you may need to commit manually."
    fi
  else
    log "No changes to commit."
  fi
elif [[ ${#MODIFIED_FILES[@]} -eq 0 ]]; then
  log "All files already up to date — nothing to commit."
fi

# ── Summary ──
echo ""
ok "══════════════════════════════════════════════"
ok "  Hermetic workflow v${VERSION} bootstrapped!"
ok "══════════════════════════════════════════════"
echo ""
log "Next steps:"
echo "  cd $TARGET"
echo "  ./orchestrator.sh          # Run setup + task loop"
echo ""
