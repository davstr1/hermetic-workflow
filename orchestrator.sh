#!/usr/bin/env bash
# orchestrator.sh — The Ralph Wiggum Loop
#
# Runs the hermetic TDD workflow:
#   1. Architect (interactive setup, runs once)
#   2. Per-task loop: Planner → Test Maker → Coder → Reviewer
#   3. Escalation to Architect on repeated failures
#
# Usage:
#   ./orchestrator.sh              # Full run (setup + loop)
#   ./orchestrator.sh --skip-setup # Skip architect setup, go straight to loop

set -euo pipefail

# ═══════════════════════════════════════════════════════════════════════════
# CONFIG
# ═══════════════════════════════════════════════════════════════════════════

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
TASKS_FILE="$PROJECT_DIR/workflow/tasks.md"
STATE_DIR="$PROJECT_DIR/workflow/state"
PROMPTS_DIR="$PROJECT_DIR/prompts"
MAX_RETRIES=3
MAX_TURNS=50

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

log()   { echo -e "${BLUE}[orchestrator]${NC} $*"; }
ok()    { echo -e "${GREEN}[orchestrator]${NC} $*"; }
warn()  { echo -e "${YELLOW}[orchestrator]${NC} $*"; }
err()   { echo -e "${RED}[orchestrator]${NC} $*"; }
agent() { echo -e "${MAGENTA}[$1]${NC} Running..."; }

# ═══════════════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════════════

# Ensure state directory exists
mkdir -p "$STATE_DIR"

# Clean state files for a fresh run
clean_state() {
  rm -f "$STATE_DIR/review-status.txt"
  rm -f "$STATE_DIR/review-feedback.md"
  rm -f "$STATE_DIR/escalation-context.md"
  rm -f "$STATE_DIR/escalation-status.txt"
}

# Read the next unchecked task from tasks.md
# Returns the task text (without the checkbox prefix)
get_next_task() {
  if [[ ! -f "$TASKS_FILE" ]]; then
    echo ""
    return
  fi
  # Find first line matching "- [ ]" (unchecked task)
  local task_line
  task_line=$(grep -m1 '^\- \[ \]' "$TASKS_FILE" 2>/dev/null || true)
  if [[ -z "$task_line" ]]; then
    echo ""
    return
  fi
  # Strip the checkbox prefix "- [ ] "
  echo "${task_line#- \[ \] }"
}

# Mark a task as done in tasks.md
mark_task_done() {
  local task_text="$1"
  # Escape special regex characters in task text
  local escaped
  escaped=$(printf '%s\n' "$task_text" | sed 's/[[\.*^$()+?{|]/\\&/g')
  sed -i '' "s/^- \[ \] ${escaped}/- [x] ${escaped}/" "$TASKS_FILE"
}

# Get the line number of the current task (for marking)
get_task_line_number() {
  local task_text="$1"
  grep -n "^\- \[ \] ${task_text}" "$TASKS_FILE" | head -1 | cut -d: -f1
}

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 1: SETUP (Interactive — runs once)
# ═══════════════════════════════════════════════════════════════════════════

run_setup() {
  log "═══════════════════════════════════════════════════"
  log "  SETUP PHASE — Architect Agent (Interactive)"
  log "═══════════════════════════════════════════════════"
  echo ""
  log "The Architect will help you set up project principles,"
  log "configure lint rules, and create the task list."
  echo ""

  export HERMETIC_AGENT=architect
  claude \
    --print \
    --prompt-file "$PROMPTS_DIR/architect.md" \
    --max-turns "$MAX_TURNS" \
    --allowedTools "Read,Write,Edit,Glob,Grep,Bash" \
    <<< "You are in SETUP mode. Help the user establish project principles, review/update ESLint rules, and create the task list in workflow/tasks.md. Start by asking what they're building."

  ok "Setup complete. Principles and tasks are ready."
  echo ""
}

# ═══════════════════════════════════════════════════════════════════════════
# PHASE 2: THE LOOP (Headless — per task)
# ═══════════════════════════════════════════════════════════════════════════

run_planner() {
  local task="$1"
  agent "planner"
  log "Planning: $task"

  export HERMETIC_AGENT=planner
  local prompt
  prompt=$(cat <<EOF
You are the Planner agent. Read your instructions from prompts/planner.md.

CURRENT TASK: $task

1. Check what was done recently (git log --oneline -10)
2. Read workflow/state/planner-context.md if it exists (your notes from last iteration)
3. Evaluate whether this task is atomic and clear enough for one test→code→review cycle
4. If NOT atomic: decompose it into subtasks in workflow/tasks.md (replace the current task line with subtasks)
5. If atomic: just update workflow/state/planner-context.md with current status
EOF
)

  echo "$prompt" | claude \
    -p \
    --max-turns "$MAX_TURNS" \
    --allowedTools "Read,Write,Edit,Glob,Grep,Bash"

  ok "Planner finished."

  # Re-read the task — planner may have decomposed it
  local new_task
  new_task=$(get_next_task)
  echo "$new_task"
}

run_test_maker() {
  local task="$1"
  agent "test-maker"
  log "Writing tests for: $task"

  export HERMETIC_AGENT=test-maker
  local prompt
  prompt=$(cat <<EOF
You are the Test Maker agent. Read your instructions from prompts/test-maker.md.

TASK: $task

Read principles.md for project quality standards.
Look at the existing codebase to understand structure and patterns.
Write test files for this task. Only write test files.
EOF
)

  echo "$prompt" | claude \
    -p \
    --max-turns "$MAX_TURNS" \
    --allowedTools "Read,Write,Edit,Glob,Grep,Bash"

  ok "Test Maker finished."
}

run_coder() {
  local task="$1"
  local attempt="$2"
  local feedback=""

  agent "coder"
  log "Implementing (attempt $attempt/$MAX_RETRIES): $task"

  # On retries, inject reviewer feedback into the prompt
  if [[ $attempt -gt 1 && -f "$STATE_DIR/review-feedback.md" ]]; then
    feedback=$(cat "$STATE_DIR/review-feedback.md")
  fi

  export HERMETIC_AGENT=coder
  local prompt
  if [[ -n "$feedback" ]]; then
    prompt=$(cat <<EOF
TASK: $task

IMPORTANT — PREVIOUS ATTEMPT FAILED. Reviewer feedback:
---
$feedback
---

Address every point in the feedback above. Run tests to verify your fixes.
EOF
)
  else
    prompt=$(cat <<EOF
TASK: $task

Implement the code to fulfill this task. Run tests to check your work.
If you get lint errors after writing files, fix them.
EOF
)
  fi

  echo "$prompt" | claude \
    -p \
    --max-turns "$MAX_TURNS" \
    --allowedTools "Read,Write,Edit,Glob,Grep,Bash"

  ok "Coder finished (attempt $attempt)."
}

run_reviewer() {
  local task="$1"
  agent "reviewer"
  log "Reviewing implementation..."

  # Clean previous review state
  rm -f "$STATE_DIR/review-status.txt"
  rm -f "$STATE_DIR/review-feedback.md"

  export HERMETIC_AGENT=reviewer
  local prompt
  prompt=$(cat <<EOF
You are the Reviewer agent. Read your instructions from prompts/reviewer.md.

TASK: $task

Review the coder's implementation:
1. Run tests
2. Run lint: node example-ui-rules/bin/nexum-lint.cjs
3. Check against principles.md
4. Check task completion

Write your verdict (PASS or FAIL) to workflow/state/review-status.txt
If FAIL, write detailed feedback to workflow/state/review-feedback.md
If PASS, commit the changes.
EOF
)

  echo "$prompt" | claude \
    -p \
    --max-turns "$MAX_TURNS" \
    --allowedTools "Read,Write,Edit,Glob,Grep,Bash"

  ok "Reviewer finished."

  # Read the verdict
  if [[ -f "$STATE_DIR/review-status.txt" ]]; then
    local status
    status=$(cat "$STATE_DIR/review-status.txt" | tr -d '[:space:]')
    echo "$status"
  else
    warn "Reviewer did not write a status file. Treating as FAIL."
    echo "FAIL"
  fi
}

run_escalation() {
  local task="$1"
  log "═══════════════════════════════════════════════════"
  warn "  ESCALATION — Architect Agent (Interactive)"
  log "═══════════════════════════════════════════════════"
  echo ""
  warn "The coder failed $MAX_RETRIES times on this task."
  warn "The Architect will diagnose the issue with your help."
  echo ""

  # Build the diagnostic bundle
  local escalation_file="$STATE_DIR/escalation-context.md"
  {
    echo "# Escalation Context"
    echo ""
    echo "## Task"
    echo "$task"
    echo ""
    echo "## Review Feedback (last attempt)"
    if [[ -f "$STATE_DIR/review-feedback.md" ]]; then
      cat "$STATE_DIR/review-feedback.md"
    else
      echo "(no feedback file found)"
    fi
    echo ""
    echo "## Review Status History"
    echo "Failed $MAX_RETRIES consecutive attempts."
    echo ""
  } > "$escalation_file"

  rm -f "$STATE_DIR/escalation-status.txt"

  export HERMETIC_AGENT=architect
  claude \
    --print \
    --prompt-file "$PROMPTS_DIR/architect.md" \
    --max-turns "$MAX_TURNS" \
    --allowedTools "Read,Write,Edit,Glob,Grep,Bash" \
    <<< "You are in ESCALATION mode. Read the diagnostic context at workflow/state/escalation-context.md. Diagnose the root cause and propose fixes to the user. After applying approved changes, write RESOLVED to workflow/state/escalation-status.txt."

  # Check if resolved
  if [[ -f "$STATE_DIR/escalation-status.txt" ]]; then
    local status
    status=$(cat "$STATE_DIR/escalation-status.txt" | tr -d '[:space:]')
    if [[ "$status" == "RESOLVED" ]]; then
      ok "Escalation resolved. Resuming loop."
      return 0
    fi
  fi

  warn "Escalation did not resolve cleanly. The task will be retried."
  return 0
}

# ═══════════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════════

main() {
  log "Hermetic Workflow — Starting"
  log "Project: $PROJECT_DIR"
  echo ""

  # Parse args
  local skip_setup=false
  for arg in "$@"; do
    case "$arg" in
      --skip-setup) skip_setup=true ;;
    esac
  done

  # Phase 1: Setup
  if [[ "$skip_setup" == false ]]; then
    run_setup
  else
    log "Skipping setup (--skip-setup)."
  fi

  # Phase 2: The Loop
  log "═══════════════════════════════════════════════════"
  log "  LOOP PHASE — Processing Tasks"
  log "═══════════════════════════════════════════════════"
  echo ""

  while true; do
    local task
    task=$(get_next_task)

    if [[ -z "$task" ]]; then
      ok "All tasks complete!"
      break
    fi

    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "TASK: $task"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    clean_state

    # Step 0: Planner — check if task is atomic, decompose if needed
    task=$(run_planner "$task")

    if [[ -z "$task" ]]; then
      warn "Planner removed or decomposed all tasks. Re-reading task list..."
      continue
    fi

    log "Proceeding with: $task"

    # Step 1: Test Maker
    run_test_maker "$task"

    # Step 2-3: Coder + Reviewer loop
    local attempt=1
    local passed=false

    while [[ $attempt -le $MAX_RETRIES ]]; do
      # Step 2: Coder
      run_coder "$task" "$attempt"

      # Step 3: Reviewer
      local verdict
      verdict=$(run_reviewer "$task")

      if [[ "$verdict" == "PASS" ]]; then
        ok "PASS — Task complete: $task"
        passed=true
        break
      else
        warn "FAIL (attempt $attempt/$MAX_RETRIES)"
        if [[ -f "$STATE_DIR/review-feedback.md" ]]; then
          warn "Feedback written to workflow/state/review-feedback.md"
        fi
        ((attempt++))
      fi
    done

    if [[ "$passed" == true ]]; then
      mark_task_done "$task"
      ok "Task marked done."
      echo ""
      continue
    fi

    # Step 4: Escalation
    err "Max retries ($MAX_RETRIES) exhausted. Escalating to Architect."
    run_escalation "$task"

    # After escalation, re-run from planner (task/tests may have changed)
    log "Re-running task from planner after escalation..."
    clean_state

    task=$(run_planner "$task")
    if [[ -z "$task" ]]; then
      warn "Task was decomposed after escalation. Re-reading task list..."
      continue
    fi

    run_test_maker "$task"

    # One more try after escalation
    local post_escalation_attempt=1
    local post_passed=false

    while [[ $post_escalation_attempt -le $MAX_RETRIES ]]; do
      run_coder "$task" "$post_escalation_attempt"
      local verdict
      verdict=$(run_reviewer "$task")

      if [[ "$verdict" == "PASS" ]]; then
        ok "PASS — Task complete after escalation: $task"
        post_passed=true
        break
      else
        warn "FAIL (post-escalation attempt $post_escalation_attempt/$MAX_RETRIES)"
        ((post_escalation_attempt++))
      fi
    done

    if [[ "$post_passed" == true ]]; then
      mark_task_done "$task"
      ok "Task marked done."
    else
      err "Task still failing after escalation. Skipping: $task"
      warn "Manual intervention required for: $task"
      # Mark with a different symbol to indicate failure
      sed -i '' "s/^- \[ \] $(printf '%s' "$task" | sed 's/[[\.*^$()+?{|]/\\&/g')/- [!] ${task} (STUCK)/" "$TASKS_FILE"
    fi

    echo ""
  done

  log "═══════════════════════════════════════════════════"
  ok "  Workflow Complete"
  log "═══════════════════════════════════════════════════"
}

main "$@"
