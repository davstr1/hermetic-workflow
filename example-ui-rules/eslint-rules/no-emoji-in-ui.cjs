/**
 * fs/no-emoji-in-ui — Ban emoji in visible UI copy (JSX text, strings).
 * Use SVG icons or text instead. Emoji break professional tone.
 */

// Matches most common emoji ranges
const EMOJI_RE = /[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{FE00}-\u{FE0F}\u{1FA00}-\u{1FA9F}\u{1FAA0}-\u{1FAFF}\u{200D}\u{20E3}\u{E0020}-\u{E007F}]/u;

module.exports = {
  meta: {
    type: 'problem',
    docs: { description: 'Ban emoji in UI copy' },
    messages: {
      emoji: 'Emoji in UI copy: "{{char}}". Use icons (SVG) or text instead. Emoji break professional tone and age poorly.',
    },
  },
  create(context) {
    function checkValue(node, value) {
      if (typeof value !== 'string') return;
      const match = value.match(EMOJI_RE);
      if (match) {
        context.report({ node, messageId: 'emoji', data: { char: match[0] } });
      }
    }

    return {
      JSXText(node) { checkValue(node, node.value); },
      Literal(node) {
        // Skip non-JSX contexts (imports, config, etc.) — only check if inside JSX or className
        const parent = node.parent;
        if (parent && (parent.type === 'JSXAttribute' || parent.type === 'JSXElement' || parent.type === 'JSXExpressionContainer')) {
          checkValue(node, node.value);
        }
      },
    };
  },
};
