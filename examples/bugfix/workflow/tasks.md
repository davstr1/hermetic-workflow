# Tasks

> Pre-built tasks for the bugfix example project.

- [ ] Fix the bug in `src/slugify.js` — the `slugify` function does not collapse consecutive hyphens. For example, `slugify("hello   ---   world")` currently returns `"hello-------world"` instead of `"hello-world"`. Also, leading/trailing hyphens should be stripped. Existing tests in `src/slugify.test.js` expose the failures. Fix the implementation to make all tests pass.
- [ ] Fix the bug in `src/kebabCase.js` — the `kebabCase` function does not handle transitions between letters and numbers. For example, `kebabCase("version2Release")` returns `"version2-release"` instead of `"version-2-release"`. Existing tests in `src/kebabCase.test.js` expose the failures. Fix the implementation to make all tests pass.
