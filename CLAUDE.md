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

### Hermetic Isolation (All Agents)

Every agent is mechanically restricted to its role. This is enforced by `.claude/hooks/guard-files.sh`, not by prompt instructions.

| Agent | Can READ | Can WRITE | Bash Allowlist |
|-------|----------|-----------|----------------|
| **Orchestrator** | Everything | Everything | Unrestricted |
| **Architect** | Everything | Everything | Unrestricted |
| **Planner** | Tasks, state, source, tests, git log | `workflow/tasks.md`, `workflow/state/planner-context.md` only | `git log/diff/status/show`, read-only utils (`ls`, `cat`, `head`, `tail`, `wc`) |
| **Test Maker** | Source code, tests, principles | Test files (`*.test.*`, `*.spec.*`) and `package.json` only | `npm install/test`, `npx jest/vitest`, `node`, git read-only, read-only utils |
| **Coder** | Source code, CLAUDE.md (principles) | Source code only (no tests, rules, state, config) | `npm install/run/test`, `npx`, `node`, `tsc`, `mkdir`, git read-only, read-only utils |
| **Reviewer** | Everything | `workflow/state/review-status.txt`, `workflow/state/review-feedback.md` only | `npm test`, `npx jest/vitest`, `node nexum-lint`, `npm run`, `git add/commit` + git read-only, read-only utils |

No agent (except architect/orchestrator) can read `.claude/agents/` or lint rule source code. The coder additionally cannot read tests or review feedback.

Bash commands are **allowlisted per agent** — each agent can only run commands matching its allowed patterns. Shell-based file writes (`>`, `>>`, `tee`, `sed -i`, `cp`, `mv`, `rm`), subshells (`$()`, backticks), and `eval`/`bash -c` are blocked for all restricted agents. Compound commands (`&&`, `||`, `;`, `|`) are split and each segment is checked independently.

The coder gets lint errors and test results automatically after every file write (via `enforce-lint.sh`) but never sees the rules or test source code.

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
- `workflow/tasks.md` — Task list (markdown checkboxes)
- `workflow/state/` — Inter-agent communication files
- `workflow/state/current-agent.txt` — Current agent identifier (read by hooks)
- `workflow/state/guard-blocks.log` — Persistent log of blocked hook attempts (read by orchestrator during escalation)
- `example-ui-rules/` — ESLint/Stylelint rules + nexum-lint standalone linter

## Adding Tasks

Edit `workflow/tasks.md` and add tasks as:
```markdown
- [ ] Implement user authentication module
- [ ] Add error handling to API client
```

Or let the Architect agent create them during setup.

## Principles

> This section is written by the Architect agent during setup.
> It is auto-loaded into every agent's context via CLAUDE.md.

<!-- The Architect will replace this with project-specific principles. -->
<!-- Each principle should be specific, enforceable, and testable. -->
<!-- Examples: "NEVER use inline styles", "All API responses must include error codes" -->
