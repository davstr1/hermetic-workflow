/**
 * fs/no-ai-comments — Detect AI-style explanatory comments (WHAT instead of WHY).
 */
const AI_COMMENT_PATTERNS = [
  /^\/\/\s*this (?:component|function|hook|module|file) (?:renders?|handles?|is responsible|manages?|creates?|defines?)/i,
  /^\/\/\s*here we (?:handle|define|create|render|manage|set up)/i,
  /^\/\/\s*the following (?:code|function|component|section)/i,
  /^\/\/\s*we need to/i,
  /^\/\/\s*this is (?:the|a|an|where)/i,
  /^\/\/\s*import(?:ing)? (?:the|all|necessary)/i,
  /^\/\/\s*(?:first|next|then|finally),? we/i,
  /^\/\/\s*set(?:ting)? up the/i,
];

module.exports = {
  meta: {
    type: 'suggestion',
    docs: { description: 'Detect AI-style explanatory comments' },
    messages: {
      aiComment: 'AI-style explanatory comment. Comments should explain WHY, not WHAT. The code explains what it does.',
    },
  },
  create(context) {
    const source = context.getSourceCode();
    return {
      Program() {
        for (const comment of source.getAllComments()) {
          if (comment.type !== 'Line') continue;
          const text = '//' + comment.value;
          for (const pattern of AI_COMMENT_PATTERNS) {
            if (pattern.test(text.trim())) {
              context.report({ node: comment, messageId: 'aiComment' });
              break;
            }
          }
        }
      },
    };
  },
};
