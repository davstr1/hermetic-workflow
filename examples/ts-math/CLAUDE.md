# Project

A tiny TypeScript math-utility library (`ts-math-example`).
TypeScript must be compiled with `tsc` before tests can run.
No runtime dependencies — only `vitest` and `typescript` for dev.

## Tech Stack

**Language**: TypeScript (strict mode, `.ts` files)
**Test framework**: vitest (already in package.json)
**Build**: `npm run build` (runs `tsc`) — must build before testing

## Structure

```
src/
  clamp.ts          Clamp a number to a range
  clamp.test.ts     Tests for clamp
  lerp.ts           Linear interpolation
  lerp.test.ts      Tests for lerp
tsconfig.json       TypeScript config (strict mode)
package.json        Project config
```

- Source files: `src/<module>.ts`, one named export per file with explicit types.
- Test files: colocated as `src/<module>.test.ts`.
- Imports: use `.js` extension (`import { clamp } from './clamp.js'` — TS ES module resolution).
- Naming: kebab-case file names, camelCase function names.
- Modules are independent — no shared dependencies.
- Tasks are already atomic. Each task = one function = one file.
- Build: `npm run build` — must pass before running tests.
- Run tests: `npm test` (runs `vitest run`).
- No lint configured — skip lint. Only build + test.
- Code must pass `tsc --strict` — explicit types, no `any`.

## Principles

- **Pure functions only**: Every exported function must be a pure function — no side effects, no mutations, deterministic output for the same input.
- **No runtime dependencies**: Zero production dependencies. Only devDependencies (vitest, typescript).
- **Strict TypeScript**: All code must pass `tsc --strict`. Explicit parameter and return types on every export.
- **JSDoc on every export**: Every exported function must have `@param`, `@returns`, and `@example`.
- **Handle edge cases explicitly**: NaN, Infinity, negative values, and boundary conditions must not throw — return sensible defaults.
- **ES modules everywhere**: Use `import`/`export`. No CommonJS.
