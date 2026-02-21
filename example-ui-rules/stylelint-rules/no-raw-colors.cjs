/**
 * @nexum/ui stylelint: no-raw-colors
 * Ban raw hex/rgb/hsl colors in CSS — force var(--token) usage.
 * 
 * Allowed exceptions:
 * - Inside :root or [data-theme] (token definitions)
 * - transparent, currentColor, inherit
 * - rgba() with var() inside (e.g. rgba(var(--accent-rgb), 0.5))
 */
const stylelint = require('stylelint');

const ruleName = 'nexum/no-raw-colors';
const messages = stylelint.utils.ruleMessages(ruleName, {
  rejected: (value) =>
    `Raw color "${value}" detected. Use a design token: var(--surface-*), var(--text-*), var(--border-*), var(--accent), var(--success), etc. Raw colors bypass the design system.`,
});

const HEX_RE = /#[0-9a-fA-F]{3,8}\b/;
const RGB_RE = /\brgba?\(\s*\d/;
const HSL_RE = /\bhsla?\(\s*\d/;

const COLOR_PROPERTIES = new Set([
  'color', 'background', 'background-color', 'border-color',
  'border-top-color', 'border-right-color', 'border-bottom-color', 'border-left-color',
  'outline-color', 'text-decoration-color', 'fill', 'stroke',
  'box-shadow', 'text-shadow',
]);

/** @type {import('stylelint').Rule} */
const ruleFunction = (primary) => {
  return (root, result) => {
    if (!primary) return;

    root.walkDecls((decl) => {
      // Skip token definitions (:root, [data-theme])
      const parent = decl.parent;
      if (parent && parent.type === 'rule') {
        const sel = parent.selector || '';
        if (sel.includes(':root') || sel.includes('[data-theme')) return;
      }

      const prop = decl.prop.toLowerCase();
      // Only check color-related properties + shorthand border
      if (!COLOR_PROPERTIES.has(prop) && !prop.startsWith('border') && prop !== 'outline') return;

      const value = decl.value;
      if (!value) return;

      // Skip if it's just a var() reference
      if (/^var\(--/.test(value.trim())) return;
      // Skip transparent/inherit/currentColor/none
      if (/^(transparent|currentColor|currentcolor|inherit|initial|unset|none)$/.test(value.trim())) return;

      if (HEX_RE.test(value) || RGB_RE.test(value) || HSL_RE.test(value)) {
        const match = value.match(HEX_RE)?.[0] || value.match(RGB_RE)?.[0] || value.match(HSL_RE)?.[0];
        stylelint.utils.report({
          message: messages.rejected(match),
          node: decl,
          result,
          ruleName,
        });
      }
    });
  };
};

ruleFunction.ruleName = ruleName;
ruleFunction.messages = messages;
module.exports = stylelint.createPlugin(ruleName, ruleFunction);
