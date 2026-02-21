/** @type {import('eslint').Linter.Config} */
module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
    ecmaFeatures: { jsx: true },
    project: './tsconfig.json',
  },
  plugins: ['@typescript-eslint', 'react', 'react-hooks'],
  extends: [
    'eslint:recommended',
    'plugin:@typescript-eslint/recommended',
    'plugin:react/recommended',
    'plugin:react-hooks/recommended',
  ],
  settings: {
    react: { version: 'detect' },
  },
  rules: {
    // === TypeScript ===
    '@typescript-eslint/no-unused-vars': ['warn', { argsIgnorePattern: '^_' }],
    '@typescript-eslint/consistent-type-imports': ['error', { prefer: 'type-imports' }],
    '@typescript-eslint/no-explicit-any': 'warn',

    // === React ===
    'react/react-in-jsx-scope': 'off',
    'react/prop-types': 'off',
    'react/self-closing-comp': 'warn',
    'react-hooks/rules-of-hooks': 'error',
    'react-hooks/exhaustive-deps': 'warn',

    // === General ===
    'no-console': ['warn', { allow: ['warn', 'error'] }],
    'prefer-const': 'error',
    'no-var': 'error',
    eqeqeq: ['error', 'always', { null: 'ignore' }],
    curly: ['error', 'all'],

    // === Frontend Specs — Enforced Patterns ===
    'no-restricted-syntax': [
      'error',
      // fs/no-hover-translate — ban hover:translate-y (jittery chase effect)
      {
        selector: "Literal[value=/hover:[+-]?translate-y/]",
        message: 'hover:translate-y causes jittery chase effect. Use hover:shadow-* or hover:border-* instead.',
      },
      {
        selector: "TemplateLiteral[quasis.0.value.raw=/hover:[+-]?translate-y/]",
        message: 'hover:translate-y causes jittery chase effect. Use hover:shadow-* or hover:border-* instead.',
      },
      // fs/no-div-soup — warn on deeply nested divs (heuristic: className with nested div patterns)
      // Note: true depth detection requires a custom rule, this catches the most common AI pattern
    ],

    // === Em dash limit (heuristic) ===
    // Note: true per-file em dash counting requires custom rule,
    // but the AI reads this config and learns the constraint:
    // Max 2 em dashes (— or –) per file in visible copy.
  },
  env: {
    browser: true,
    es2020: true,
    node: true,
  },
  overrides: [
    {
      // Apply custom @nexum rules to consumer projects
      // When used as shared config, load our plugin:
      files: ['*.tsx', '*.ts', '*.jsx', '*.js'],
      plugins: ['@nexum'],
      rules: {
        // fs/no-ai-slop — ban AI corporate filler in all text
        '@nexum/no-ai-slop': 'error',
        // fs/prefer-semantic-tokens — ban raw Tailwind colors
        '@nexum/prefer-semantic-tokens': 'error',
        // fs/no-placeholder-content — catch lorem ipsum, example.com, etc.
        '@nexum/no-placeholder-content': 'error',
        // fs/no-ai-comments — comments explain WHY not WHAT
        '@nexum/no-ai-comments': 'warn',
        // fs/accessible-interactive — onClick needs button/a or role+tabIndex+keyboard
        '@nexum/accessible-interactive': 'error',
        // fs/image-dimensions — img must have width+height
        '@nexum/image-dimensions': 'error',
        // fs/consistent-spacing — enforce restricted spacing scale (0,1,2,4,6,8,10,12,16,20,24,32)
        '@nexum/consistent-spacing': 'error',
      },
    },
  ],
  ignorePatterns: ['dist', 'node_modules', '*.config.*', '.eslintrc.js'],
}
