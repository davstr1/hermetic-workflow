# Hermetic Workflow

This project uses a **hermetic TDD workflow** with native Claude Code agents (`.claude/agents/`) orchestrated by an orchestrator agent.

## Quick Start

```bash
./orchestrator.sh              # Full run (setup + task loop)
./orchestrator.sh --skip-setup # Skip setup, process tasks directly

# Or run agents directly:
claude --agent architect       # Interactive setup only
claude --agent orchestrator    # Task loop only
```

## Architecture

### Agents (`.claude/agents/`)

| Agent | Role | Access |
|-------|------|--------|
| **Orchestrator** | Spawns subagents, manages task loop, handles escalation | Everything (Task tool) |
| **Architect** | Sets up principles, lint rules, task list | Everything |
| **Planner** | Ensures tasks are atomic, decomposes if needed | Tasks, git log, state |
| **Test Maker** | Writes test files from task descriptions | Task, principles, existing code |
| **Coder** | Writes implementation code | Task, principles, source code (hermetically sealed from rules/tests) |
| **Reviewer** | Reviews code, commits on PASS, feedback on FAIL | Everything |

### Hermetic Isolation

The **Coder agent is hermetically sealed** — it cannot read:
- Test files (`*.test.*`, `*.spec.*`)
- Lint rules (`example-ui-rules/eslint-rules/`, etc.)
- Agent definitions (`.claude/agents/`)
- Review feedback files

It CAN read `principles.md` (high-level direction) but never the enforcement mechanism.

This is enforced by Claude Code hooks in `.claude/hooks/guard-files.sh`, not by prompt instructions. The coder gets lint errors and test results automatically after every file write (via `enforce-lint.sh`) but never sees the rules or test source code.

### Agent Identification

Hooks identify the current agent via two mechanisms (with fallback):
1. **State file**: `workflow/state/current-agent.txt` — written by the orchestrator agent before spawning each subagent
2. **Env var**: `HERMETIC_AGENT` — legacy support for direct CLI invocation

### Workflow Loop

```
Architect (setup) → Orchestrator spawns for each task:
  Planner → Test Maker → Coder → Reviewer
                          ↑         ↓
                          └── FAIL ──┘  (max 3 retries)
                                   ↓
                             STUCK → Orchestrator handles escalation
                                       ↓
                             Planner (re-evaluate) → resume loop
```

## Key Files

- `orchestrator.sh` — Thin wrapper that runs architect + orchestrator agents
- `.claude/agents/` — Native Claude Code agent definitions (YAML frontmatter + markdown)
- `.claude/settings.json` — Hooks configuration
- `.claude/hooks/guard-files.sh` — PreToolUse: hermetic file access control
- `.claude/hooks/enforce-lint.sh` — PostToolUse: lint enforcement after writes
- `principles.md` — Project quality principles (written by Architect)
- `workflow/tasks.md` — Task list (markdown checkboxes)
- `workflow/state/` — Inter-agent communication files
- `workflow/state/current-agent.txt` — Current agent identifier (read by hooks)
- `example-ui-rules/` — ESLint/Stylelint rules + nexum-lint standalone linter

## Adding Tasks

Edit `workflow/tasks.md` and add tasks as:
```markdown
- [ ] Implement user authentication module
- [ ] Add error handling to API client
```

Or let the Architect agent create them during setup.
