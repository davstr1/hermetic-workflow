// @nexum/ui shared Stylelint config
// Projects extend: { "extends": "@nexum/ui/stylelint.config" }
module.exports = {
  plugins: [
    './stylelint-rules/index.cjs',
  ],
  rules: {
    'nexum/no-raw-colors': true,
    'nexum/spacing-scale': true,
    'declaration-no-important': true,
    'font-family-no-missing-generic-family-keyword': true,
    'no-descending-specificity': null,
  },
};
