/**
 * @nexum/ui stylelint: spacing-scale
 * Enforce spacing scale in CSS: 0, 4, 8, 16, 24, 32, 48, 64, 80, 96, 128px
 * (matches token scale: 0,1,2,4,6,8,10,12,16,20,24,32 × 4px base)
 * 
 * Bans arbitrary pixel values on spacing properties.
 * Allowed: 0, multiples from our scale, auto, 100%, var(--)
 */
const stylelint = require('stylelint');

const ruleName = 'nexum/spacing-scale';
const messages = stylelint.utils.ruleMessages(ruleName, {
  rejected: (prop, value) =>
    `Off-scale spacing: "${prop}: ${value}". Use design tokens: var(--space-*) or allowed values: 0, 4, 8, 16, 24, 32, 48, 64, 80, 96, 128px. Odd spacing breaks visual rhythm.`,
});

// Allowed px values (scale × 4px)
const ALLOWED_PX = new Set([0, 4, 8, 16, 24, 32, 48, 64, 80, 96, 128]);

const SPACING_PROPS = new Set([
  'margin', 'margin-top', 'margin-right', 'margin-bottom', 'margin-left',
  'margin-inline', 'margin-block', 'margin-inline-start', 'margin-inline-end',
  'padding', 'padding-top', 'padding-right', 'padding-bottom', 'padding-left',
  'padding-inline', 'padding-block', 'padding-inline-start', 'padding-inline-end',
  'gap', 'row-gap', 'column-gap',
  'top', 'right', 'bottom', 'left',
  'inset', 'inset-inline', 'inset-block',
]);

/** @type {import('stylelint').Rule} */
const ruleFunction = (primary) => {
  return (root, result) => {
    if (!primary) return;

    root.walkDecls((decl) => {
      const prop = decl.prop.toLowerCase();
      if (!SPACING_PROPS.has(prop)) return;

      const value = decl.value.trim();
      // Skip var() references
      if (value.includes('var(')) return;
      // Skip auto, inherit, etc.
      if (/^(auto|inherit|initial|unset|0)$/.test(value)) return;
      // Skip percentage values
      if (/%/.test(value)) return;
      // Skip calc()
      if (value.includes('calc(')) return;
      // Skip negative values — check the absolute
      const clean = value.replace(/^-/, '');

      // Check each value in shorthand (e.g. "16px 24px")
      const parts = clean.split(/\s+/);
      for (const part of parts) {
        if (part === 'auto' || part === '0' || part.includes('var(') || part.includes('%')) continue;
        const px = parseFloat(part);
        if (isNaN(px)) continue;
        if (!part.endsWith('px')) continue;
        if (!ALLOWED_PX.has(Math.abs(px))) {
          stylelint.utils.report({
            message: messages.rejected(prop, value),
            node: decl,
            result,
            ruleName,
          });
          break;
        }
      }
    });
  };
};

ruleFunction.ruleName = ruleName;
ruleFunction.messages = messages;
module.exports = stylelint.createPlugin(ruleName, ruleFunction);
