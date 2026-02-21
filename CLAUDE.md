# Hermetic Workflow

This project uses a **hermetic TDD workflow** with five Claude Code agents orchestrated by a bash loop.

## Quick Start

```bash
./orchestrator.sh              # Full run (setup + task loop)
./orchestrator.sh --skip-setup # Skip setup, process tasks directly
```

## Architecture

### Agents

| Agent | Role | Access |
|-------|------|--------|
| **Architect** | Sets up principles, lint rules, handles escalations | Everything |
| **Planner** | Ensures tasks are atomic, decomposes if needed, tracks progress | Tasks, git log, state |
| **Test Maker** | Writes test files from task descriptions | Task, principles, existing code |
| **Coder** | Writes implementation code | Task, principles, source code (hermetically sealed from rules/tests) |
| **Reviewer** | Reviews code, commits on PASS, feedback on FAIL | Everything |

### Hermetic Isolation

The **Coder agent is hermetically sealed** — it cannot read:
- Test files (`*.test.*`, `*.spec.*`)
- Lint rules (`example-ui-rules/eslint-rules/`, etc.)
- Agent prompts (`prompts/`)
- Review feedback files

It CAN read `principles.md` (high-level direction) but never the enforcement mechanism.

This is enforced by Claude Code hooks in `.claude/hooks/guard-files.sh`, not by prompt instructions. The coder gets lint errors and test results automatically after every file write (via `enforce-lint.sh`) but never sees the rules or test source code.

### Workflow Loop

```
Architect (setup) → for each task:
  Planner → Test Maker → Coder → Reviewer
                          ↑         ↓
                          └── FAIL ──┘  (max 3 retries)
                                   ↓
                             STUCK → Architect (escalation)
                                       ↓
                             Planner (re-evaluate) → resume loop
```

## Key Files

- `orchestrator.sh` — Main entry point, the Ralph Wiggum loop
- `.claude/settings.json` — Hooks configuration
- `.claude/hooks/guard-files.sh` — PreToolUse: hermetic file access control
- `.claude/hooks/enforce-lint.sh` — PostToolUse: lint enforcement after writes
- `prompts/` — Agent system prompts
- `principles.md` — Project quality principles (written by Architect)
- `workflow/tasks.md` — Task list (markdown checkboxes)
- `workflow/state/` — Inter-agent communication files
- `example-ui-rules/` — ESLint/Stylelint rules + nexum-lint standalone linter

## Adding Tasks

Edit `workflow/tasks.md` and add tasks as:
```markdown
- [ ] Implement user authentication module
- [ ] Add error handling to API client
```

Or let the Architect agent create them during setup.
