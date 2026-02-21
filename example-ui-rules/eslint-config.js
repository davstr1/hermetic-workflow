/**
 * @nexum/ui shared ESLint config.
 *
 * Usage:
 *   // .eslintrc.js
 *   module.exports = { extends: [require.resolve('@nexum/ui/eslint-config')] }
 *
 * Includes all @nexum rules + sensible defaults.
 * One line in your project = fully enforced.
 */
const plugin = require('./eslint-rules/index.js');

module.exports = {
  plugins: ['@typescript-eslint'],
  rules: {
    // General
    'prefer-const': 'error',
    'no-var': 'error',
    'no-console': ['warn', { allow: ['warn', 'error'] }],
    eqeqeq: ['error', 'always', { null: 'ignore' }],

    // @nexum rules
    ...plugin.configs.recommended.rules,

    // Forbidden patterns via no-restricted-syntax
    'no-restricted-syntax': [
      'error',
      {
        selector: "Literal[value=/hover:[+-]?translate-y/]",
        message: 'hover:translate-y causes jittery chase effect. Use hover:shadow-* or hover:border-* instead.',
      },
      {
        selector: "TemplateLiteral[quasis.0.value.raw=/hover:[+-]?translate-y/]",
        message: 'hover:translate-y causes jittery chase effect. Use hover:shadow-* or hover:border-* instead.',
      },
    ],
  },
  env: {
    browser: true,
    es2020: true,
    node: true,
  },
};
