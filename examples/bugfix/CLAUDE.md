# Project

A tiny Node.js string-utility library (`bugfix-example`) with known bugs.
Tests already exist and some are failing — the goal is to fix the bugs, not rewrite.
No runtime dependencies — only `vitest` for testing.

## Tech Stack

**Language**: JavaScript (ES modules, `.js` files)
**Test framework**: vitest (already in package.json)
**Build**: none — plain JS, no compile step

## Structure

```
src/
  slugify.js        String slugify function (has bug)
  slugify.test.js   Tests for slugify (pre-written, some failing)
  wrap.js           Word wrap function (has bug)
  wrap.test.js      Tests for wrap (pre-written, some failing)
package.json        Project config
```

- Source files: `src/<module>.js`, one named export per file.
- Test files: already exist as `src/<module>.test.js` — pre-written and intentionally failing.
- Tasks are about fixing bugs, NOT creating new files.
- Fix the bug with the minimal change. Do NOT rewrite from scratch.
- For the test commit: verify existing tests capture the bug. If they do, make a no-op test commit.
- Keep existing JSDoc intact. Update only if the fix changes behavior.
- Run tests: `npm test` (runs `vitest run`).
- No lint configured — skip lint.

## Principles

- **Fix, don't rewrite**: The existing code structure is intentional. Fix the specific bug without rewriting.
- **No runtime dependencies**: Zero production dependencies. Only devDependencies (vitest).
- **JSDoc on every export**: Every exported function must have `@param`, `@returns`, and `@example`.
- **Handle edge cases explicitly**: Empty strings, null/undefined, and boundary values must not throw — return sensible defaults.
- **ES modules everywhere**: Use `import`/`export`. No CommonJS.
