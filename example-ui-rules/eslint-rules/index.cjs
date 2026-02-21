/**
 * @nexum/eslint-plugin — All frontend-specs rules in one plugin.
 *
 * Usage (simplest):
 *   // .eslintrc.js
 *   module.exports = { extends: [require.resolve('@nexum/ui/eslint-config')] }
 *
 * Usage (manual):
 *   plugins: ['@nexum'],
 *   rules: { '@nexum/no-ai-slop': 'error', ... }
 */
module.exports = {
  rules: {
    'no-ai-slop': require('./no-ai-slop.cjs'),
    'prefer-semantic-tokens': require('./prefer-semantic-tokens.cjs'),
    'no-placeholder-content': require('./no-placeholder-content.cjs'),
    'no-ai-comments': require('./no-ai-comments.cjs'),
    'accessible-interactive': require('./accessible-interactive.cjs'),
    'image-dimensions': require('./image-dimensions.cjs'),
    'consistent-spacing': require('./consistent-spacing.cjs'),
    'no-emoji-in-ui': require('./no-emoji-in-ui.cjs'),
  },
  configs: {
    recommended: {
      plugins: ['@nexum'],
      rules: {
        '@nexum/no-ai-slop': 'error',
        '@nexum/prefer-semantic-tokens': 'error',
        '@nexum/no-placeholder-content': 'error',
        '@nexum/no-ai-comments': 'warn',
        '@nexum/accessible-interactive': 'error',
        '@nexum/image-dimensions': 'error',
        '@nexum/consistent-spacing': 'error',
        '@nexum/no-emoji-in-ui': 'error',
      },
    },
  },
};
