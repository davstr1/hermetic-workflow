# Project

A tiny Node.js string-utility library (`string-utils-example`).
Source files live in `src/`. Each module exports a single named function.
No runtime dependencies — only `vitest` for testing.

## Principles

- **Pure functions only**: Every exported function must be a pure function — no side effects, no mutations, deterministic output for the same input.
- **No runtime dependencies**: The library must have zero production dependencies. Only devDependencies (vitest) are allowed.
- **JSDoc on every export**: Every exported function must have a JSDoc comment with `@param`, `@returns`, and a usage `@example`.
- **Handle edge cases explicitly**: Empty strings, null/undefined inputs, and boundary values must be handled gracefully — never throw on bad input, return sensible defaults instead.
- **ES modules everywhere**: Use `import`/`export` syntax. No CommonJS (`require`/`module.exports`).
