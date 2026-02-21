/**
 * fs/prefer-semantic-tokens — Ban raw Tailwind color classes, force semantic tokens.
 */
const RAW_COLOR_PATTERN = /(?:^|\s)(?:bg|text|border|ring|outline|decoration|shadow|divide|from|via|to)-(?:gray|zinc|slate|neutral|stone|blue|red|green|yellow|purple|pink|orange|indigo|violet|emerald|teal|cyan|amber|lime|rose|fuchsia|sky)-\d{1,3}(?:\/\d+)?(?:\s|$|")/;

module.exports = {
  meta: {
    type: 'problem',
    docs: { description: 'Ban raw Tailwind color classes — use semantic tokens' },
    messages: {
      raw: 'Raw Tailwind color "{{cls}}" detected. Use semantic token instead (surface-primary, text-secondary, etc.). AI doesn\'t know our design system — that\'s why this rule exists. See tokens/colors.ts',
    },
  },
  create(context) {
    function checkValue(node, value) {
      if (typeof value !== 'string') return;
      const matches = value.match(/(?:bg|text|border|ring|outline|decoration|shadow|divide|from|via|to)-(?:gray|zinc|slate|neutral|stone|blue|red|green|yellow|purple|pink|orange|indigo|violet|emerald|teal|cyan|amber|lime|rose|fuchsia|sky)-\d{1,3}(?:\/\d+)?/g);
      if (matches) {
        for (const cls of matches) {
          context.report({ node, messageId: 'raw', data: { cls } });
        }
      }
    }

    return {
      Literal(node) { checkValue(node, node.value); },
      TemplateLiteral(node) {
        for (const quasi of node.quasis) {
          checkValue(quasi, quasi.value.raw);
        }
      },
    };
  },
};
