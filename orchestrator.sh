#!/usr/bin/env bash
# orchestrator.sh — Launches the TDD workflow.
#
# Bash handles routing and looping. The orchestrator agent is invoked once
# per task with fresh context, preventing stale accumulation.
#
# Flow:
#   1. Git pre-flight (init repo + remote if needed)
#   2. If no tasks exist → run architect for interactive setup
#   3. While unchecked tasks remain → run orchestrator (one task per session)
#
# Usage:
#   ./orchestrator.sh                                # Full run
#   ./orchestrator.sh --dangerously-skip-permissions  # Skip permission prompts
#   ./orchestrator.sh --example                       # List available examples
#   ./orchestrator.sh --example string-utils          # Run a specific example in /tmp
#   ./orchestrator.sh --reset                         # Clean state from interrupted run, then start

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

# Parse args
skip_permissions=""
run_example=""
run_reset=""
args=("$@")
for ((i=0; i<${#args[@]}; i++)); do
  case "${args[$i]}" in
    --dangerously-skip-permissions) skip_permissions="--dangerously-skip-permissions" ;;
    --example)
      # If next arg exists and doesn't start with --, treat it as the example name
      if [[ $((i+1)) -lt ${#args[@]} && "${args[$((i+1))]}" != --* ]]; then
        run_example="${args[$((i+1))]}"
        ((i++))
      else
        run_example="1"
      fi
      ;;
    --reset) run_reset="1" ;;
  esac
done

# ── Example mode: pre-baked smoke-test project ──
if [[ -n "$run_example" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  EXAMPLES_DIR="$SCRIPT_DIR/examples"

  if [[ ! -d "$EXAMPLES_DIR" ]]; then
    echo -e "${RED}[orchestrator]${NC} examples/ directory not found in $SCRIPT_DIR" >&2
    exit 1
  fi

  # If no name given, list available examples and exit
  if [[ "$run_example" == "1" ]]; then
    echo "Available examples:"
    for d in "$EXAMPLES_DIR"/*/; do
      [[ -d "$d" ]] || continue
      name=$(basename "$d")
      echo "  --example $name"
    done
    exit 0
  fi

  EXAMPLE_DIR="$EXAMPLES_DIR/$run_example"
  if [[ ! -d "$EXAMPLE_DIR" ]]; then
    echo -e "${RED}[orchestrator]${NC} Example not found: $run_example" >&2
    echo "Available examples:" >&2
    for d in "$EXAMPLES_DIR"/*/; do
      [[ -d "$d" ]] || continue
      echo "  --example $(basename "$d")" >&2
    done
    exit 1
  fi

  TEMP_DIR="/tmp/hw-example-$$"
  log "Example mode ($run_example): setting up in $TEMP_DIR"

  mkdir -p "$TEMP_DIR/workflow"
  cp "$EXAMPLE_DIR/CLAUDE.md"         "$TEMP_DIR/CLAUDE.md"
  cp "$EXAMPLE_DIR/package.json"      "$TEMP_DIR/package.json"
  cp -r "$EXAMPLE_DIR/workflow/"      "$TEMP_DIR/workflow/"

  # Copy src/ if it exists (e.g., bugfix example with pre-existing code)
  if [[ -d "$EXAMPLE_DIR/src" ]]; then
    cp -r "$EXAMPLE_DIR/src/" "$TEMP_DIR/src/"
  fi

  # Copy tsconfig.json if it exists (e.g., TypeScript projects)
  if [[ -f "$EXAMPLE_DIR/tsconfig.json" ]]; then
    cp "$EXAMPLE_DIR/tsconfig.json" "$TEMP_DIR/tsconfig.json"
  fi

  git -C "$TEMP_DIR" init -q
  git -C "$TEMP_DIR" add -A
  git -C "$TEMP_DIR" commit -q -m "Initial example project"

  log "Running init.sh..."
  "$SCRIPT_DIR/init.sh" "$TEMP_DIR"

  log "Patching agent context..."
  "$EXAMPLE_DIR/agent-context.sh" "$TEMP_DIR"

  log "Installing project dependencies..."
  (cd "$TEMP_DIR" && npm install --silent 2>&1)
  ok "Dependencies installed."

  git -C "$TEMP_DIR" add -A
  git -C "$TEMP_DIR" commit -q -m "chore: apply example agent context"

  PROJECT_DIR="$TEMP_DIR"
  STATE_DIR="$TEMP_DIR/workflow/state"
  mkdir -p "$STATE_DIR"

  ok "Example project ready at $TEMP_DIR"
  echo ""
fi

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# ── Reset mode: clean state from interrupted run ──
if [[ -n "$run_reset" ]]; then
  log "Resetting workflow state from interrupted run..."

  for f in "$STATE_DIR"/*; do
    [[ ! -f "$f" ]] && continue
    case "$(basename "$f")" in
      usage-log.md|guard-trace.log) ;; # keep logs
      *) rm -f "$f"; ok "Removed: $(basename "$f")" ;;
    esac
  done

  ok "Workflow state cleaned. Unchecked tasks will restart from Planner."
  echo ""
fi

# ── Git repo pre-flight ──
if [[ -z "$run_example" ]]; then
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
fi

# ── Setup check ──
if ! grep -q '^\- \[' "$PROJECT_DIR/workflow/tasks.md" 2>/dev/null; then
  log "No tasks found — running Architect for setup..."
  echo ""
  (cd "$PROJECT_DIR" && claude --agent architect $skip_permissions) || true
fi

# ── Task loop: one task per session, fresh context ──
log "Starting task loop..."
echo ""

SENTINEL="$STATE_DIR/task-complete"
TOTAL_ACTIVE_TIME=0

while grep -q '^\- \[ \]' "$PROJECT_DIR/workflow/tasks.md" 2>/dev/null; do
  remaining=$(grep -c '^\- \[ \]' "$PROJECT_DIR/workflow/tasks.md" 2>/dev/null || echo "0")
  log "Tasks remaining: $remaining"

  # Clear sentinel and record start time
  rm -f "$SENTINEL"
  date +%s > "$STATE_DIR/task-start-time.txt"

  # Launch orchestrator in background (fresh context per task)
  echo "Process the next unchecked task from workflow/tasks.md. Pipeline: Planner → Test Maker (commit) → Coder (commit) → Reviewer (verify + commit). On PASS, spawn Closer." \
    | (cd "$PROJECT_DIR" && claude --agent orchestrator $skip_permissions) &
  CLAUDE_PID=$!

  # Watch for sentinel — kill session when task is done (fresh context for next task)
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
  echo ""
done

# Final summary
total_min=$((TOTAL_ACTIVE_TIME / 60))
total_sec=$((TOTAL_ACTIVE_TIME % 60))
ok "All tasks complete. Workflow finished."
ok "Total active time: ${total_min}m ${total_sec}s"
if [[ -f "$STATE_DIR/usage-log.md" ]]; then
  ok "Usage log: $STATE_DIR/usage-log.md"
fi
