/**
 * fs/no-ai-slop — Ban AI slop phrases in JSX text and string literals.
 * Banlist loaded from banlists/ai-slop.txt (or inline fallback).
 */
const fs = require('fs');
const path = require('path');

let banlist = [];
try {
  const file = fs.readFileSync(
    path.join(__dirname, '..', '..', 'frontend-specs', 'banlists', 'ai-slop.txt'),
    'utf8'
  );
  banlist = file
    .split('\n')
    .map(l => l.trim())
    .filter(l => l && !l.startsWith('#'));
} catch {
  // Inline fallback
  banlist = [
    "we're thrilled", "don't hesitate", "groundbreaking", "seamless", "delve",
    "leveraging", "cutting-edge", "game-changing", "revolutionary", "state-of-the-art",
    "best-in-class", "unlock the full potential", "take it to the next level",
    "empower", "streamline", "synergy", "paradigm", "robust", "scalable solution",
    "elevate your", "supercharge your", "turbocharge", "unleash", "deep dive",
    "holistic", "ecosystem", "landscape", "harness the power", "bridge the gap",
    "move the needle", "low-hanging fruit", "circle back", "lean in",
    "I'd be happy to", "certainly!", "absolutely!", "great question",
    "it's worth noting that", "needless to say", "embark on",
  ];
}

const banlistLower = banlist.map(b => b.toLowerCase());

module.exports = {
  meta: {
    type: 'suggestion',
    docs: { description: 'Ban AI slop phrases in visible text' },
    messages: {
      slop: 'AI slop detected: "{{word}}". Use direct, human language. Say what you mean without corporate filler.',
    },
  },
  create(context) {
    function checkValue(node, value) {
      if (typeof value !== 'string') return;
      const lower = value.toLowerCase();
      for (const phrase of banlistLower) {
        if (lower.includes(phrase)) {
          context.report({
            node,
            messageId: 'slop',
            data: { word: phrase },
          });
        }
      }
    }

    return {
      // JSX text content
      JSXText(node) {
        checkValue(node, node.value);
      },
      // String literals (template literals too)
      Literal(node) {
        checkValue(node, node.value);
      },
      TemplateLiteral(node) {
        for (const quasi of node.quasis) {
          checkValue(quasi, quasi.value.raw);
        }
      },
    };
  },
};
