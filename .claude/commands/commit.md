# /commit

Commit your work before exiting. Every agent that creates or modifies files must do this.

## Format

```
[agent-name] short summary

What: 1-3 sentences describing what changed and which files.
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
[coder] implement user login

What: Created src/auth/login.ts with login() function that calls
POST /api/auth/login, validates input, and returns a session token.
Why: First auth endpoint needed before building protected routes.
```

```
[rules-guide] scaffold project structure and lint config

What: Created src/, tests/, public/ directories. Added tsconfig.json,
.eslintrc with strict rules, and vitest.config.ts.
Why: Establishes folder layout and lint enforcement before any code.
```

```
[reviewer] approve task: user login

What: All 6 tests pass. Git history clean — code commit did not
weaken test commit. Principles followed. Login works in manual test.
Why: Task meets requirements and passes all checks.
```

## Steps

1. `git add -A`
2. Write the message following the format above
3. `git commit` with that message
4. Append a history entry to `workflow/history.md`:
   - Get the short hash: `git log -1 --format="%h"`
   - Get the timestamp: `date "+%Y-%m-%d %H:%M"`
   - Append an entry in this exact format (example with real values):
     ```
     >>>
     [coder] implement user login
     Commit: abc1234
     Date: 2026-02-23 14:30

     What: Created src/auth/login.ts with login() function that calls
     POST /api/auth/login, validates input, and returns a session token.
     Why: First auth endpoint needed before building protected routes.
     ```
   - All values come from the commit you just made: agent name and summary from the first line, What/Why from the body, hash from `git log`, timestamp from `date`.

## Rules

- Every commit must have What and Why — no one-liners.
- Short summary under 60 characters.
- Do not skip the commit. Uncommitted work gets lost between sessions.
