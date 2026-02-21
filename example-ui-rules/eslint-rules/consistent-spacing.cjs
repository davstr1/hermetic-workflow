/**
 * fs/consistent-spacing — Enforce spacing scale, ban odd values and arbitrary spacing.
 * 
 * Allowed Tailwind spacing values: 0, 1, 2, 4, 6, 8, 10, 12, 16, 20, 24, 32
 * Banned: 3, 5, 7, 9, 11, 13, 14, 15, etc. + all arbitrary values like mt-[13px]
 */
const SPACING_PROPS = ['p', 'px', 'py', 'pt', 'pr', 'pb', 'pl', 'm', 'mx', 'my', 'mt', 'mr', 'mb', 'ml', 'gap', 'gap-x', 'gap-y', 'space-x', 'space-y', 'inset', 'top', 'right', 'bottom', 'left'];

const ALLOWED_VALUES = new Set(['0', '1', '2', '4', '6', '8', '10', '12', '16', '20', '24', '32', 'px', 'auto', 'full']);

// Match spacing classes like p-3, mt-5, gap-7, -mb-3, etc.
const SPACING_RE = new RegExp(
  `(?:^|\\s)-?(?:${SPACING_PROPS.join('|')})-(\\d+|\\[.+?\\])(?:\\s|$|")`,
  'g'
);

// Match arbitrary spacing like p-[13px], mt-[2rem]
const ARBITRARY_RE = new RegExp(
  `(?:^|\\s)-?(?:${SPACING_PROPS.join('|')})-\\[.+?\\]`,
  'g'
);

module.exports = {
  meta: {
    type: 'problem',
    docs: { description: 'Enforce consistent spacing scale' },
    messages: {
      oddValue: 'Spacing value "{{cls}}" is off-scale. Use allowed values: 0, 1, 2, 4, 6, 8, 10, 12, 16, 20, 24, 32. Odd values break visual rhythm.',
      arbitrary: 'Arbitrary spacing "{{cls}}" detected. Use standard spacing scale. Arbitrary values break consistency across the design system.',
    },
  },
  create(context) {
    function checkValue(node, value) {
      if (typeof value !== 'string') return;

      // Check arbitrary values
      const arbitraryMatches = value.match(ARBITRARY_RE);
      if (arbitraryMatches) {
        for (const cls of arbitraryMatches) {
          context.report({ node, messageId: 'arbitrary', data: { cls: cls.trim() } });
        }
      }

      // Check odd/off-scale values
      let match;
      const re = new RegExp(SPACING_RE.source, 'g');
      while ((match = re.exec(value)) !== null) {
        const val = match[1];
        if (val.startsWith('[')) continue; // already caught by arbitrary check
        if (!ALLOWED_VALUES.has(val)) {
          const fullMatch = match[0].trim();
          context.report({ node, messageId: 'oddValue', data: { cls: fullMatch } });
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
