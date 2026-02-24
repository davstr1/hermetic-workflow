# /log

Log your work before exiting. **Every agent must do this, whether or not files were committed.**

## Format

```
[agent-name] short summary

What: 1-3 sentences describing what you did.
Why: 1-2 sentences explaining the reasoning or intent.
```

The agent name is your name from the frontmatter of your agent file (e.g., `product-vision`, `coder`, `reviewer`).

## Examples

```
[coder] add tests for user login

What: Created src/auth/login.test.ts with 6 tests covering success,
invalid credentials, missing fields, rate limiting, and token format.
Why: Tests define the expected behavior before implementation.
```

```
[reviewer] approve task: user login

What: All 6 tests pass. Git history clean — code commit did not
weaken test commit. Principles followed.
Why: Task meets requirements and passes all checks.
```

```
[orchestrator] dispatch coder for task 3/8

What: Read CLAUDE.md and tasks.md. Task 3 is unchecked. Dispatched
Feature Composer to adapt, then Coder to implement.
Why: Next task in sequence, no blockers.
```

## Steps

1. **If you created or modified tracked files**: `git add -A` then `git commit` with the format above.
2. **Append a history entry to `workflow/history.md`**:
   - If you committed: get the short hash with `git log -1 --format="%h"`
   - Get the timestamp: `date -u "+%Y-%m-%dT%H:%M:%SZ"`
   - Append an entry in this exact format:
     ```
     >>>
     [coder] implement user login
     Commit: abc1234
     Date: 2026-02-23T14:30:00Z

     What: Created src/auth/login.ts with login() function.
     Why: First auth endpoint needed before building protected routes.
     ```
   - **Commit field**: the short hash if you committed, `-` if you did not.
   - **Date field**: always UTC ISO-8601 from `date -u "+%Y-%m-%dT%H:%M:%SZ"`.

## Rules

- Every agent must `/log` before exiting — even if nothing was committed.
- Every entry must have What and Why — no one-liners.
- Short summary under 60 characters.
- Commit field is the git short hash or `-`. Nothing else.
- Date field is always `date -u "+%Y-%m-%dT%H:%M:%SZ"`. No other format.
