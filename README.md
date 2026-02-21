# Hermetic Workflow

A TDD workflow for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) where the coding agent **cannot see the tests or lint rules it must satisfy**. Enforcement is mechanical, not prompt-based.

## Why

LLM coding agents cheat. Give them test files and lint rules, and they'll pattern-match to satisfy them rather than write code that genuinely fulfills the requirements. Hermetic isolation fixes this:

- The **coder agent** sees the task description and project principles, but never the tests or rules
- Tests and lint run automatically after every file write — the coder gets error messages, not source code
- This is enforced by [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks), not by instructions the agent can ignore

The result: code that satisfies requirements because it understands them, not because it read the answer key.

## How It Works

Six agents, orchestrated in a loop:

```
Architect (setup) → Orchestrator runs for each task:
  Planner → Test Maker → Coder → Reviewer
                          ↑         ↓
                          └── FAIL ──┘  (max 3 retries)
                                   ↓
                             STUCK → Escalation (interactive)
```

| Agent | What it does | What it can see |
|-------|-------------|-----------------|
| **Architect** | Sets up principles, lint rules, task list | Everything |
| **Orchestrator** | Spawns agents, manages the loop, handles escalation | Everything |
| **Planner** | Checks task atomicity, decomposes if needed | Tasks, git log, state |
| **Test Maker** | Writes tests before implementation | Task, principles, existing code/tests |
| **Coder** | Writes implementation code | Task, principles, source code only |
| **Reviewer** | Runs tests + lint, commits on PASS, feedback on FAIL | Everything |

The **Coder** is hermetically sealed. It cannot read test files, lint rules, agent definitions, or review feedback files. This is enforced by a `PreToolUse` hook that intercepts every file read/write/glob/grep/bash call and blocks forbidden paths.

A `PostToolUse` hook runs lint and tests after every file the coder writes, showing error output without revealing the rule or test source code.

## Quick Start

### Install into your project

```bash
# One-liner (from your project directory):
curl -fsSL https://raw.githubusercontent.com/davstr1/hermetic-workflow/main/setup-remote.sh | bash

# Or clone + init:
git clone git@github.com:davstr1/hermetic-workflow.git /tmp/hw
/tmp/hw/init.sh /path/to/your-project
```

This copies the workflow files into your project. No git remote is added.

### Run

```bash
# Full run: interactive setup, then process all tasks
./orchestrator.sh

# Skip setup if you already have principles + tasks
./orchestrator.sh --skip-setup
```

Or run agents directly:

```bash
# Interactive setup only (define principles, rules, tasks)
claude --agent architect

# Process all tasks (the main loop)
claude --agent orchestrator
```

### Add tasks

Edit `workflow/tasks.md`:

```markdown
- [ ] Implement user authentication module
- [ ] Add input validation to API endpoints
- [ ] Create error boundary component
```

Or let the Architect create them during setup.

## What Gets Installed

```
your-project/
├── .claude/
│   ├── agents/          # Agent definitions (YAML + markdown)
│   │   ├── orchestrator.md
│   │   ├── architect.md
│   │   ├── planner.md
│   │   ├── test-maker.md
│   │   ├── coder.md
│   │   └── reviewer.md
│   ├── hooks/
│   │   ├── guard-files.sh    # PreToolUse: blocks coder from forbidden paths
│   │   └── enforce-lint.sh   # PostToolUse: runs lint + tests after coder writes
│   └── settings.json         # Hook configuration
├── example-ui-rules/         # ESLint/Stylelint rules + nexum-lint
├── workflow/
│   ├── tasks.md              # Task list (markdown checkboxes)
│   └── state/                # Inter-agent communication (gitignored)
├── orchestrator.sh           # Entry point (thin wrapper)
├── principles.md             # Project quality principles (written by Architect)
└── CLAUDE.md                 # Project instructions for Claude Code
```

## Customization

### Principles

`principles.md` is written by the Architect during setup. These are the rules your code must follow — specific, enforceable statements like "NEVER use inline styles" or "All API responses must include error codes". The coder can read this file.

### Lint Rules

`example-ui-rules/` contains ESLint and Stylelint rules plus `nexum-lint`, a standalone linter that checks all file types. The Architect can create or modify rules during setup. The coder cannot see these rules — it only sees the error messages.

### Hooks

The hooks in `.claude/hooks/` are the enforcement mechanism. They identify the current agent via `workflow/state/current-agent.txt` (written by the orchestrator) or the `HERMETIC_AGENT` env var (for direct CLI use).

To change what the coder can and cannot access, edit `guard-files.sh`.

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Node.js (for lint rules and test runners)
- A project with a test framework (Jest, Vitest, etc.)

## License

MIT
