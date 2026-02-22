# Hermetic Workflow

A TDD workflow for [Claude Code](https://docs.anthropic.com/en/docs/claude-code) where **every agent is mechanically restricted to its role**. No agent can cheat — enforcement is by hooks, not prompts.

## Why

LLM coding agents cheat. Give them test files and lint rules, and they'll pattern-match to satisfy them rather than write code that genuinely fulfills the requirements. But it's not just the coder — a reviewer that can edit source code isn't really reviewing, and a test-maker that can modify implementation isn't really doing TDD.

Hermetic isolation fixes this for every agent:

- The **coder** sees task descriptions and principles, but never the tests or rules
- The **test-maker** can only write test files — it can't touch source code
- The **reviewer** runs tests and lint but can't read test source — it judges from output only
- The **planner** can only write task files — it can't write code or tests
- All of this is enforced by [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks), not by instructions agents can ignore

The result: agents that do their actual job because they literally can't do anything else.

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

| Agent | What it does | Can read | Can write | Bash allowlist |
|-------|-------------|----------|-----------|----------------|
| **Architect** | Sets up principles, lint rules, task list | Everything | `CLAUDE.md`, agent defs, lint rules, `workflow/tasks.md` | Unrestricted |
| **Orchestrator** | Spawns agents, manages the loop | Everything | `workflow/tasks.md` + `workflow/state/*` only | Read-only (git log, cat, ls) |
| **Planner** | Checks task atomicity, decomposes if needed | Tasks, source, git log (no tests, no lint rules) | `workflow/tasks.md` + its context file only | git read-only, read utils |
| **Test Maker** | Writes tests before implementation | Source code, tests, principles | Test files only | npm install/test, node, git read-only |
| **Coder** | Writes implementation code | Source code, principles | Source code only | npm, npx, node, tsc, mkdir, git read-only |
| **Reviewer** | Runs tests + lint, commits on PASS | Source code, principles (no tests, no lint rules) | `review-status.txt` + `review-feedback.md` only | npm test, nexum-lint, git add/commit |

Every restriction is enforced by a `PreToolUse` hook that intercepts every file read/write/glob/grep/bash call and blocks forbidden paths. Bash commands are **allowlisted per agent** — shell-based file writes, subshells, and eval are blocked for all restricted agents, and compound commands are split and validated individually. A `PostToolUse` hook runs lint and tests after every file the coder writes, showing error output without revealing the rule or test source code.

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

# Skip setup if you already have tasks defined
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

## Updating an Existing Project

Re-run the same install command from your project directory:

```bash
curl -fsSL https://raw.githubusercontent.com/davstr1/hermetic-workflow/main/setup-remote.sh | bash
```

Or from a local clone:

```bash
/path/to/hermetic-workflow/init.sh /path/to/your-project
```

This overwrites the workflow engine (hooks, agents, settings, orchestrator.sh) but preserves your project-specific files (`CLAUDE.md`, `workflow/tasks.md`, `example-ui-rules/`). Your Architect-written principles, task list, and lint rules stay intact.

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
│   │   ├── guard-files.sh    # PreToolUse: hermetic access control + block logging
│   │   ├── enforce-lint.sh   # PostToolUse: runs lint + tests after coder writes
│   │   └── stop-loop.sh      # Stop hook: keeps orchestrator looping until all tasks done
│   └── settings.json         # Hook configuration
├── example-ui-rules/         # ESLint/Stylelint rules + nexum-lint
├── workflow/
│   ├── tasks.md              # Task list (markdown checkboxes)
│   └── state/                # Inter-agent communication (gitignored)
├── orchestrator.sh           # Entry point (thin wrapper)
└── CLAUDE.md                 # Project description + principles (auto-loaded into all agents)
```

## Customization

### CLAUDE.md and Per-Agent Context

`CLAUDE.md` contains only universal project knowledge (description, tech stack, principles) — it's auto-loaded into every agent's context. The Architect writes this during setup.

Each agent `.md` file has a `## Project Context` section at the bottom. The Architect populates these with agent-specific guidance: the coder gets source file conventions and libraries, the test-maker gets test framework patterns, the reviewer gets review priorities, and the planner gets decomposition hints. This keeps each agent's context focused on what it needs.

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
