/**
 * fs/image-dimensions — Every <img> must have width + height (prevents layout shift).
 */
module.exports = {
  meta: {
    type: 'problem',
    docs: { description: 'Require width/height on img elements' },
    messages: {
      missing: '<img> without explicit dimensions causes layout shift. Add width/height attributes or use aspect-ratio.',
    },
  },
  create(context) {
    return {
      JSXOpeningElement(node) {
        if (node.name?.name !== 'img') return;
        const attrs = node.attributes || [];
        const hasWidth = attrs.some(a => a.name?.name === 'width');
        const hasHeight = attrs.some(a => a.name?.name === 'height');
        if (!hasWidth || !hasHeight) {
          context.report({ node, messageId: 'missing' });
        }
      },
    };
  },
};
