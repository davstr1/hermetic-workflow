# How the Hermetic Workflow Works

A TDD-driven multi-agent system where **bash controls the loop** and **Claude agents do the work**. Each agent handles one responsibility, commits its output, and exits. Fresh context is enforced per task to prevent token bloat.

## The Big Picture

```
orchestrator.sh
  │
  ├─ 1. Git pre-flight (init repo + remote)
  ├─ 2. Architect (interactive setup, if no tasks exist)
  ├─ 3. Task loop (one agent pipeline per task)
  ├─ 4. Frontend validation loop (if dev server detected)
  └─ 5. Summary (total time + token usage)
```

## Setup: The Architect

Runs once at project start when `workflow/tasks.md` has no tasks. The Architect:

- Interviews the user about the project and quality standards
- Writes `CLAUDE.md` (project description + principles, loaded by every agent)
- Populates `## Project Context` sections in each agent's `.md` file
- Configures lint rules in `example-ui-rules/`
- Scaffolds the task list in `workflow/tasks.md`

The Architect never writes code. It writes governance.

## The Task Loop

`orchestrator.sh` loops while unchecked tasks (`- [ ]`) exist in `workflow/tasks.md`. Each iteration spawns a fresh orchestrator agent session that processes exactly one task through the pipeline:

```
Planner → Test Maker (commit) → Coder (commit) → Reviewer (verdict)
               ↑                      ↑                  ↓
               └── test problem ──────┴── code problem ──┘  (max 3 retries)
```

### Agents in the Pipeline

| Agent | Job | Key Rule |
|-------|-----|----------|
| **Planner** | Adapts the task to current reality, decomposes if too large | Always runs first |
| **Test Maker** | Writes tests from the task description, commits them | Runs before Coder (TDD) |
| **Coder** | Implements code to pass the tests, builds, commits | Never touches test files |
| **Reviewer** | Runs tests, audits git history, checks principles | Writes PASS or FAIL |
| **Closer** | Logs token usage and task duration | Runs on haiku, fast |

### The Sentinel Pattern

The orchestrator agent runs in background. When a task passes, it writes `DONE` to `workflow/state/task-complete`. The bash loop polls for this file, kills the agent session, and spawns a fresh one for the next task. This prevents context from accumulating across tasks.

### Retry Logic

On FAIL, the orchestrator reads `workflow/state/review-feedback.md` and routes:
- Test problem (stale mocks, wrong assertions) → back to Test Maker
- Code problem (wrong logic, build errors) → back to Coder
- Both or unclear → both agents re-run

Max 3 attempts. After that, the task is marked STUCK and escalated to the user.

## Frontend Validation (Post-Pipeline)

After all tasks complete, `orchestrator.sh` checks `package.json` for a dev server script (`dev`, `start`, or `preview`). If found, it enters a validation loop (max 2 rounds):

1. **Frontend Validator** starts the dev server, opens pages in the browser, checks console for errors, screenshots broken pages
2. If `PASS` → done
3. If `NEEDS_FIX` → Architect reads the report, creates fix tasks → task loop re-runs → re-validates

Non-frontend projects skip this entirely.

## Hooks

Three hooks run automatically via `.claude/settings.json`:

| Hook | Trigger | What It Does |
|------|---------|--------------|
| **session-start.sh** | Session starts | Captures session ID for transcript lookup |
| **guard-files.sh** | Before Read/Write/Edit/Bash | Blocks `node_modules/`, destructive git commands; logs all tool use |
| **enforce-lint.sh** | After Write/Edit | Runs linter + tests as feedback to the coder (never blocks) |

## State Files

All ephemeral state lives in `workflow/state/` (git-ignored). Agents communicate through files, not direct calls:

- `task-complete` — sentinel for bash to detect task completion
- `review-status.txt` / `review-feedback.md` — reviewer's verdict and feedback
- `validation-status.txt` / `validation-report.md` — frontend validator results
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

Sets up a pre-baked project in `/tmp/`, runs `init.sh`, patches agent context, installs dependencies, and runs the full pipeline. Useful for demos and testing the workflow itself.
