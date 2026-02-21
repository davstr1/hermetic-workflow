/**
 * fs/accessible-interactive — onClick on non-interactive elements must have role + tabIndex + keyboard handler.
 */
const INTERACTIVE_TAGS = new Set(['button', 'a', 'input', 'select', 'textarea', 'summary', 'details']);

module.exports = {
  meta: {
    type: 'problem',
    docs: { description: 'Enforce accessibility on interactive elements' },
    messages: {
      noInteractive: 'onClick on non-interactive element <{{tag}}>. Use <button> or <a>, or add role + tabIndex + keyboard handler.',
    },
  },
  create(context) {
    return {
      JSXOpeningElement(node) {
        // Only check native HTML elements (lowercase)
        const tag = node.name?.name;
        if (!tag || typeof tag !== 'string' || tag[0] !== tag[0].toLowerCase()) return;
        if (INTERACTIVE_TAGS.has(tag)) return;

        const attrs = node.attributes || [];
        const hasOnClick = attrs.some(a => a.name?.name === 'onClick');
        if (!hasOnClick) return;

        const hasRole = attrs.some(a => a.name?.name === 'role');
        const hasTabIndex = attrs.some(a => a.name?.name === 'tabIndex');
        const hasKeyHandler = attrs.some(a =>
          a.name?.name === 'onKeyDown' || a.name?.name === 'onKeyUp' || a.name?.name === 'onKeyPress'
        );

        if (!hasRole || !hasTabIndex || !hasKeyHandler) {
          context.report({ node, messageId: 'noInteractive', data: { tag } });
        }
      },
    };
  },
};
