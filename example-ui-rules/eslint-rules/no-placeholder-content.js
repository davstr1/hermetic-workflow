/**
 * fs/no-placeholder-content — Detect forgotten placeholder content from AI.
 */
const PATTERNS = [
  'lorem ipsum', 'placeholder', 'example.com', 'john@example',
  'your title here', 'description goes here', 'click here',
  'via.placeholder.com', 'picsum.photos', 'jane doe', 'john doe',
  'foo bar', 'test@test', 'acme corp', 'your name here',
  'coming soon', 'content goes here', 'add your',
];

module.exports = {
  meta: {
    type: 'problem',
    docs: { description: 'Detect placeholder content left by AI' },
    messages: {
      placeholder: 'Placeholder content detected: "{{match}}". Replace with real content before shipping.',
    },
  },
  create(context) {
    function checkValue(node, value) {
      if (typeof value !== 'string') return;
      const lower = value.toLowerCase();
      for (const p of PATTERNS) {
        if (lower.includes(p)) {
          context.report({ node, messageId: 'placeholder', data: { match: p } });
          break;
        }
      }
    }

    return {
      Literal(node) { checkValue(node, node.value); },
      JSXText(node) { checkValue(node, node.value); },
      TemplateLiteral(node) {
        for (const quasi of node.quasis) checkValue(quasi, quasi.value.raw);
      },
    };
  },
};
