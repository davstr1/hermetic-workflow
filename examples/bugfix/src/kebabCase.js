/**
 * Converts a string to kebab-case.
 * @param {string} str - The string to convert.
 * @returns {string} The kebab-cased string.
 * @example
 * kebabCase("helloWorld") // "hello-world"
 */
export function kebabCase(str) {
  if (!str) return '';

  return str
    .replace(/([a-z])([A-Z])/g, '$1-$2')
    .replace(/\s+/g, '-')
    .toLowerCase();
  // BUG: does not handle transitions between letters and numbers
  // e.g. "version2Release" → "version2-release" instead of "version-2-release"
  // e.g. "abc123def" → "abc123def" instead of "abc-123-def"
}
