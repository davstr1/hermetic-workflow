# How the Workflow Works

A multi-agent system where **bash controls the loop** and **Claude agents do the work**. Each agent handles one responsibility, commits its output, and exits. Fresh context is enforced per task to prevent token bloat.

**Single source of truth: `CLAUDE.md`** — every agent reads it, setup agents each write their own section.

## The Big Picture

```
orchestrator.sh
  │
  ├─ 1. Git pre-flight (init repo + remote)
  ├─ 2. Setup pipeline (if no tasks exist)
  │     ├─ Product Vision  → CLAUDE.md ## Screens (human validated)
  │     ├─ Tech Stack      → CLAUDE.md ## Tech Stack (human validated)
  │     ├─ Data Scout ↔ Data Verifier → CLAUDE.md ## Data Contract (if external APIs, max 2 rounds)
  │     ├─ Rules Guide     → CLAUDE.md ## Project + ## Principles
  │     └─ Feature Composer → workflow/tasks.md (first plan)
  ├─ 3. Task loop (one agent pipeline per task)
  └─ 4. Summary (total time + token usage)
```

## Setup Pipeline (5 Steps)

Runs once when `workflow/tasks.md` has no tasks. Each step writes a section of `CLAUDE.md`.

### Step 1: Product Vision

Interviews the user about what they want to build. Writes ASCII screen doodles and user flows to the `## Screens` section of `CLAUDE.md`. The user must confirm before proceeding.

### Step 2: Tech Stack

Reads `CLAUDE.md` (Screens section), researches technology options, and helps the user pick a stack. Writes decisions to the `## Tech Stack` section. The user picks — the agent presents trade-offs.

### Step 3: Data Scout + Data Verifier (Conditional)

Only runs if `CLAUDE.md` mentions APIs, databases, or external SDKs.

- **Data Scout** reads API docs and proposes schemas to `## Data Contract` in `CLAUDE.md`
- **Data Verifier** hits real endpoints and checks if the proposed shapes are correct
- If mismatches found, Scout fixes and Verifier re-checks (max 2 rounds)

If no external data is detected, this step is skipped.

### Step 4: Rules Guide

Reads `CLAUDE.md` (all sections written so far). Writes the `## Project` section (summary + file locations) and `## Principles` section (5-10 coding rules).

### Step 5: Feature Composer

Reads `CLAUDE.md` (now complete) and breaks the project into small, testable tasks in `workflow/tasks.md`.

## The Task Loop

`orchestrator.sh` loops while unchecked tasks (`- [ ]`) exist in `workflow/tasks.md`. Each iteration spawns a fresh orchestrator agent session that processes one task:

```
Feature Composer → Coder (test commit + code commit) → Reviewer (verdict)
       ↑                                                    ↓
       └──────────── retry (max 3) ────────────────────────┘
```

### Agents in the Pipeline

| Agent | Job | Key Rule |
|-------|-----|----------|
| **Feature Composer** | Adapts the task to current reality, splits if too large | Always runs first |
| **Coder** | Writes tests (commits), then writes code (commits) | Two commits: test then code |
| **Reviewer** | Runs tests, audits git history, checks principles | Diffs between Coder's two commits |
| **Closer** | Logs token usage and task duration | Runs on haiku, fast |

### The Two-Commit Pattern

The Coder makes two commits per task:
1. `test: <task>` — tests only
2. `feat: <task>` — implementation code

The Reviewer diffs between these two commits. If the code commit weakened or deleted tests, that is cheating and the review fails.

### The Sentinel Pattern

The orchestrator agent runs in background. When a task passes, it writes `DONE` to `workflow/state/task-complete`. The bash loop polls for this file, kills the agent session, and spawns a fresh one for the next task.

### Retry Logic

On FAIL, the orchestrator sends the Coder back with the Reviewer's feedback. The Coder decides whether to fix tests, code, or both. Max 3 attempts before escalating to the user.

## Hooks

Three hooks run automatically via `.claude/settings.json`:

| Hook | Trigger | What It Does |
|------|---------|--------------|
| **session-start.sh** | Session starts | Captures session ID for transcript lookup |
| **guard-files.sh** | Before Read/Write/Edit/Bash | Blocks `node_modules/`, destructive git commands; logs all tool use |
| **enforce-lint.sh** | After Write/Edit | Runs linter + tests as feedback to the coder (never blocks) |

## State Files

All ephemeral state lives in `workflow/state/` (git-ignored). Agents communicate through files:

- `task-complete` — sentinel for bash to detect task completion
- `review-status.txt` / `review-feedback.md` — Reviewer's verdict and feedback
- `verifier-status.txt` / `verifier-feedback.md` — Data Verifier results
- `usage-log.md` — cumulative token usage across all tasks
- `guard-trace.log` — audit trail of all tool invocations

## Bootstrapping a New Project

```bash
./init.sh /path/to/my-project
```

Copies all agent definitions, hooks, settings, and the orchestrator into the target project. Templates (`CLAUDE.md`, `workflow/tasks.md`) are only copied if they don't already exist. Then:

```bash
cd /path/to/my-project
./orchestrator.sh
```

## Example Mode

```bash
./orchestrator.sh --example string-utils
```

Sets up a pre-baked project in `/tmp/`, runs `init.sh`, patches agent context, installs dependencies, and runs the full pipeline.
