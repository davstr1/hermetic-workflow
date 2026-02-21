/**
 * @nexum/ui Stylelint plugin — aggregates all custom rules.
 * 
 * Usage in .stylelintrc.json:
 * {
 *   "plugins": ["@nexum/ui/stylelint-rules"],
 *   "rules": {
 *     "nexum/no-raw-colors": true,
 *     "nexum/spacing-scale": true
 *   }
 * }
 */
module.exports = [
  require('./no-raw-colors.cjs'),
  require('./spacing-scale.cjs'),
];
