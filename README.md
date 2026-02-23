# Hermetic Workflow

An agent workflow for [Claude Code](https://docs.anthropic.com/en/docs/claude-code). Agents build your project in phases: product vision, tech stack, data contracts, coding rules, task decomposition, then test-first coding with review.

## Quick Start

```bash
# Clone + install into your project
git clone git@github.com:davstr1/hermetic-workflow.git /tmp/hw
/tmp/hw/init.sh /path/to/my-project

# Run
cd /path/to/my-project
./orchestrator.sh
```

## How It Works

A bash script handles looping. The orchestrator agent reads state and dispatches workers.

```
orchestrator.sh (bash loop):
  if no tasks → orchestrator runs Setup
  while unchecked tasks remain → orchestrator runs one Task per session

Setup:
  Product Vision → Tech Stack → Data Scout/Verifier → Rules Guide → Feature Composer

Task (per block):
  Feature Composer → Coder → Reviewer
                      ↑         ↓
                      └── FAIL ──┘  (max 3 retries)
                               ↓
                         STUCK → Escalation
```

| Agent | Role | Writes to |
|-------|------|-----------|
| **Product Vision** | Defines screens and user flows | `CLAUDE.md` `## Screens` |
| **Tech Stack** | Picks technologies | `CLAUDE.md` `## Tech Stack` |
| **Data Scout** | Proposes API/DB schemas from docs | `CLAUDE.md` `## Data Contract` |
| **Data Verifier** | Tests schemas against real endpoints | `workflow/state/verifier-*` |
| **Rules Guide** | Scaffolds folders, lint, coding rules | `CLAUDE.md` `## Project/Structure/Principles` |
| **Feature Composer** | Decomposes project into independent blocks | `workflow/tasks.md` |
| **Coder** | Tests first (commit), then code (commit) | Source code and tests |
| **Reviewer** | Runs tests, checks quality, catches cheating | `workflow/state/review-*` |
| **Closer** | Logs token usage and timing | `workflow/state/usage-log.md` |

## Updating an Existing Project

Re-run `init.sh` from the latest source:

```bash
# Pull the latest workflow
cd /path/to/hermetic-workflow
git pull

# Re-init your project
./init.sh /path/to/my-project
```

**Updated** (overwritten every time):
- Agent definitions (`.claude/agents/*.md`)
- Hooks (`.claude/hooks/*.sh`)
- Settings (`.claude/settings.json`)
- Orchestrator, commit skill, VERSION
- `workflow/history.md` — header refreshed, existing entries preserved, update notice prepended

**Preserved** (never overwritten):
- `CLAUDE.md` — your project spec
- `workflow/tasks.md` — your task list
- `example-ui-rules/` — delete it first to get a fresh copy

## Examples

```bash
./orchestrator.sh --example               # List available examples
./orchestrator.sh --example string-utils   # Run one in /tmp
```

## Options

```bash
./orchestrator.sh                                 # Normal run
./orchestrator.sh --dangerously-skip-permissions   # Skip permission prompts
./orchestrator.sh --reset                          # Clean state from interrupted run
```

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI
- Node.js (for lint rules and test runners)

## License

MIT
