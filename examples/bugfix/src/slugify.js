/**
 * Converts a string into a URL-friendly slug.
 * @param {string} str - The string to slugify.
 * @returns {string} The slugified string.
 * @example
 * slugify("Hello World") // "hello-world"
 */
export function slugify(str) {
  if (!str) return '';

  return str
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, '')
    .replace(/\s+/g, '-');
  // BUG: does not collapse consecutive hyphens
  // e.g. "hello   ---   world" → "hello-------world" instead of "hello-world"
}
