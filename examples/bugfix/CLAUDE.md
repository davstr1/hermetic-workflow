# Project

A tiny Node.js string-utility library (`bugfix-example`) with known bugs.
Source files live in `src/`. Each module exports a single named function.
Tests already exist and some are failing — the goal is to fix the bugs, not rewrite.
No runtime dependencies — only `vitest` for testing.

## Principles

- **Fix, don't rewrite**: The existing code structure is intentional. Fix the specific bug without rewriting the function from scratch.
- **No runtime dependencies**: The library must have zero production dependencies. Only devDependencies (vitest) are allowed.
- **JSDoc on every export**: Every exported function must have a JSDoc comment with `@param`, `@returns`, and a usage `@example`.
- **Handle edge cases explicitly**: Empty strings, null/undefined inputs, and boundary values must be handled gracefully — never throw on bad input, return sensible defaults instead.
- **ES modules everywhere**: Use `import`/`export` syntax. No CommonJS (`require`/`module.exports`).
