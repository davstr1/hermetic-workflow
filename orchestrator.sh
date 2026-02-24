#!/usr/bin/env bash
# orchestrator.sh — Launches the workflow.
#
# Bash handles mode detection and looping. The orchestrator agent does the work.
#
# Flow:
#   1. Git pre-flight (init repo + remote if needed)
#   2. If no tasks exist → run orchestrator in setup mode
#   3. While unchecked tasks remain → run orchestrator in task mode (one per session)
#
# Usage:
#   ./orchestrator.sh                                # Full run
#   ./orchestrator.sh --dangerously-skip-permissions  # Skip permission prompts
#   ./orchestrator.sh --example                       # List available examples
#   ./orchestrator.sh --example string-utils          # Run a specific example in /tmp
#   ./orchestrator.sh --build-example my-app            # Run setup, save artifacts as reusable example
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
build_example=""
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
    --build-example)
      if [[ $((i+1)) -lt ${#args[@]} && "${args[$((i+1))]}" != --* ]]; then
        build_example="${args[$((i+1))]}"
        ((i++))
      else
        echo -e "${RED}[orchestrator]${NC} --build-example requires a name argument" >&2
        echo "Usage: ./orchestrator.sh --build-example <name>" >&2
        exit 1
      fi
      ;;
    --reset) run_reset="1" ;;
  esac
done

# ── Sentinel-based agent runner ──
# Launches the orchestrator agent, waits for DONE sentinel, kills session.
run_with_sentinel() {
  local prompt="$1"
  local SENTINEL="$STATE_DIR/task-complete"

  rm -f "$SENTINEL"
  date +%s > "$STATE_DIR/task-start-time.txt"

  echo "$prompt" \
    | (cd "$PROJECT_DIR" && claude --agent orchestrator $skip_permissions) &
  CLAUDE_PID=$!

  while kill -0 "$CLAUDE_PID" 2>/dev/null; do
    if [[ -f "$SENTINEL" ]]; then
      log "Session complete. Killing for fresh context..."
      kill "$CLAUDE_PID" 2>/dev/null
      wait "$CLAUDE_PID" 2>/dev/null || true
      break
    fi
    sleep 2
  done

  wait "$CLAUDE_PID" 2>/dev/null || true
  rm -f "$SENTINEL"

  # Track duration
  local start end duration
  start=$(cat "$STATE_DIR/task-start-time.txt" 2>/dev/null || echo "0")
  end=$(date +%s)
  duration=$((end - start))
  TOTAL_ACTIVE_TIME=$((TOTAL_ACTIVE_TIME + duration))
  log "Duration: $((duration / 60))m $((duration % 60))s"
  echo ""
}

# ── Build-example mode: run setup, save artifacts as reusable example ──
if [[ -n "$build_example" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
  EXAMPLES_DIR="$SCRIPT_DIR/examples"

  # Validate name doesn't already exist
  if [[ -d "$EXAMPLES_DIR/$build_example" ]]; then
    echo -e "${RED}[orchestrator]${NC} Example '$build_example' already exists in examples/" >&2
    echo "Choose a different name or remove examples/$build_example/ first." >&2
    exit 1
  fi

  TEMP_DIR="/tmp/hw-build-example-$$"
  log "Build-example mode: setting up temp project in $TEMP_DIR"

  # Create temp project with blank templates
  mkdir -p "$TEMP_DIR/workflow"
  cp "$SCRIPT_DIR/CLAUDE.md"         "$TEMP_DIR/CLAUDE.md"
  cp "$SCRIPT_DIR/workflow/tasks.md" "$TEMP_DIR/workflow/tasks.md"

  # Init git repo with initial commit
  git -C "$TEMP_DIR" init -q
  git -C "$TEMP_DIR" add -A
  git -C "$TEMP_DIR" commit -q -m "Initial blank project"

  # Run init.sh to install workflow infrastructure
  log "Running init.sh..."
  "$SCRIPT_DIR/init.sh" "$TEMP_DIR"

  # Point PROJECT_DIR at temp dir so run_with_sentinel operates there
  PROJECT_DIR="$TEMP_DIR"
  STATE_DIR="$TEMP_DIR/workflow/state"
  mkdir -p "$STATE_DIR"
  TOTAL_ACTIVE_TIME=0

  log "Launching orchestrator for interactive setup..."
  echo ""
  run_with_sentinel "Read CLAUDE.md and workflow/tasks.md. Decide what the project needs and act."

  # Save artifacts into examples/<name>/
  log "Saving artifacts to examples/$build_example/..."
  mkdir -p "$EXAMPLES_DIR/$build_example"

  # CLAUDE.md — always present
  cp "$TEMP_DIR/CLAUDE.md" "$EXAMPLES_DIR/$build_example/CLAUDE.md"

  # workflow/tasks.md
  if [[ -f "$TEMP_DIR/workflow/tasks.md" ]]; then
    mkdir -p "$EXAMPLES_DIR/$build_example/workflow"
    cp "$TEMP_DIR/workflow/tasks.md" "$EXAMPLES_DIR/$build_example/workflow/tasks.md"
  fi

  # package.json — if created
  if [[ -f "$TEMP_DIR/package.json" ]]; then
    cp "$TEMP_DIR/package.json" "$EXAMPLES_DIR/$build_example/package.json"
  fi

  # tsconfig.json — if created
  if [[ -f "$TEMP_DIR/tsconfig.json" ]]; then
    cp "$TEMP_DIR/tsconfig.json" "$EXAMPLES_DIR/$build_example/tsconfig.json"
  fi

  # src/ — if scaffolded
  if [[ -d "$TEMP_DIR/src" ]]; then
    cp -r "$TEMP_DIR/src/" "$EXAMPLES_DIR/$build_example/src/"
  fi

  # Generate no-op agent-context.sh for compatibility with --example mode
  cat > "$EXAMPLES_DIR/$build_example/agent-context.sh" << 'AGENT_CTX'
#!/usr/bin/env bash
# agent-context.sh — No-op. All context is in CLAUDE.md now.
#
# Kept for backwards compatibility with orchestrator.sh example mode,
# which calls this script after init.sh.

echo "Agent context: everything is in CLAUDE.md. Nothing to patch."
AGENT_CTX
  chmod +x "$EXAMPLES_DIR/$build_example/agent-context.sh"

  # Clean up temp dir
  rm -rf "$TEMP_DIR"

  ok "Example '$build_example' saved to examples/$build_example/"
  ok "Run it with: ./orchestrator.sh --example $build_example"
  exit 0
fi

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
  cp -r "$EXAMPLE_DIR/workflow/"      "$TEMP_DIR/workflow/"

  # Copy optional project files if they exist
  [[ -f "$EXAMPLE_DIR/package.json" ]]  && cp "$EXAMPLE_DIR/package.json"  "$TEMP_DIR/package.json"
  [[ -f "$EXAMPLE_DIR/tsconfig.json" ]] && cp "$EXAMPLE_DIR/tsconfig.json" "$TEMP_DIR/tsconfig.json"
  [[ -d "$EXAMPLE_DIR/src" ]]           && cp -r "$EXAMPLE_DIR/src/"       "$TEMP_DIR/src/"

  git -C "$TEMP_DIR" init -q
  git -C "$TEMP_DIR" add -A
  git -C "$TEMP_DIR" commit -q -m "Initial example project"

  log "Running init.sh..."
  "$SCRIPT_DIR/init.sh" "$TEMP_DIR"

  log "Patching agent context..."
  "$EXAMPLE_DIR/agent-context.sh" "$TEMP_DIR"

  if [[ -f "$TEMP_DIR/package.json" ]]; then
    log "Installing project dependencies..."
    (cd "$TEMP_DIR" && npm install --silent 2>&1)
    ok "Dependencies installed."
  fi

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

  ok "Workflow state cleaned."
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

TOTAL_ACTIVE_TIME=0

# ── Main loop: orchestrator decides what to do ──
# Each session: orchestrator reads CLAUDE.md + tasks.md, decides setup vs task,
# dispatches agents, then writes DONE sentinel. Bash kills and re-launches.

while true; do
  # Check if there's anything left to do
  has_tasks=0 unchecked=0
  if [[ -f "$PROJECT_DIR/workflow/tasks.md" ]]; then
    has_tasks=$(grep -c '^\- \[' "$PROJECT_DIR/workflow/tasks.md" || true)
    unchecked=$(grep -c '^\- \[ \]' "$PROJECT_DIR/workflow/tasks.md" || true)
  fi

  if [[ "$has_tasks" -gt 0 && "$unchecked" -eq 0 ]]; then
    break  # All tasks done
  fi

  if [[ "$unchecked" -gt 0 ]]; then
    current=$(( has_tasks - unchecked + 1 ))
    log "Task ${current}/${has_tasks}"
  else
    log "No tasks yet — orchestrator will decide what to do."
  fi

  run_with_sentinel "Read CLAUDE.md and workflow/tasks.md. Decide what the project needs and act."
done

# Final summary
total_min=$((TOTAL_ACTIVE_TIME / 60))
total_sec=$((TOTAL_ACTIVE_TIME % 60))
ok "All ${has_tasks} tasks complete. Workflow finished."
ok "Total active time: ${total_min}m ${total_sec}s"
if [[ -f "$STATE_DIR/usage-log.md" ]]; then
  ok "Usage log: $STATE_DIR/usage-log.md"
fi
