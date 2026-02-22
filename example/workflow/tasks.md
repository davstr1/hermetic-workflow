# Tasks

> Pre-built tasks for the example smoke-test project.

- [ ] Create `src/capitalize.js` — a function `capitalize(str)` that uppercases the first letter of each word in a string. Requirements: returns empty string for empty/nullish input; capitalizes a single word ("hello" → "Hello"); capitalizes multiple words ("hello world" → "Hello World"); collapses extra whitespace between words to a single space; trims leading/trailing whitespace.
- [ ] Create `src/truncate.js` — a function `truncate(str, maxLen)` that shortens a string to `maxLen` characters, appending "..." if truncated. Requirements: returns the original string unchanged if `str.length <= maxLen`; truncates and appends "..." when `str.length > maxLen` (so the result is exactly `maxLen` characters); returns empty string for empty/nullish input; when `maxLen < 4`, returns the first `maxLen` characters without "..." (since "..." alone is 3 chars); when `maxLen` is 0, returns empty string.
