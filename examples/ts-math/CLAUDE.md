# Project

A tiny TypeScript math-utility library (`ts-math-example`).
Source files live in `src/`. Each module exports a single named function.
TypeScript must be compiled with `tsc` before tests can run.
No runtime dependencies — only `vitest` and `typescript` for dev.

## Principles

- **Pure functions only**: Every exported function must be a pure function — no side effects, no mutations, deterministic output for the same input.
- **No runtime dependencies**: The library must have zero production dependencies. Only devDependencies (vitest, typescript) are allowed.
- **Strict TypeScript**: All code must pass `tsc --strict` with no errors. Use explicit parameter and return types on every export.
- **JSDoc on every export**: Every exported function must have a JSDoc comment with `@param`, `@returns`, and a usage `@example`.
- **Handle edge cases explicitly**: NaN, Infinity, negative values, and boundary conditions must be handled gracefully — never throw on bad input, return sensible defaults instead.
- **ES modules everywhere**: Use `import`/`export` syntax. No CommonJS (`require`/`module.exports`).
