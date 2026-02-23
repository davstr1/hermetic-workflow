# Project

A tiny Node.js string-utility library (`string-utils-example`).
No runtime dependencies — only `vitest` for testing.

## Tech Stack

**Language**: JavaScript (ES modules, `.js` files)
**Test framework**: vitest (already in package.json)
**Build**: none — plain JS, no compile step

## Structure

```
src/
  capitalize.js       String capitalize function
  capitalize.test.js  Tests for capitalize
  truncate.js         String truncate function
  truncate.test.js    Tests for truncate
package.json          Project config
```

- Source files: `src/<module>.js`, one named export per file.
- Test files: colocated as `src/<module>.test.js`.
- Naming: kebab-case file names, camelCase function names.
- Modules are independent — no shared dependencies between them.
- Tasks are already atomic. Each task = one function = one file.
- Run tests: `npm test` (runs `vitest run`).
- No lint configured — skip the lint step.

## Principles

- **Pure functions only**: Every exported function must be a pure function — no side effects, no mutations, deterministic output for the same input.
- **No runtime dependencies**: Zero production dependencies. Only devDependencies (vitest).
- **JSDoc on every export**: Every exported function must have `@param`, `@returns`, and `@example`.
- **Handle edge cases explicitly**: Empty strings, null/undefined inputs, and boundary values must not throw — return sensible defaults.
- **ES modules everywhere**: Use `import`/`export`. No CommonJS.
