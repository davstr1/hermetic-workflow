/**
 * Nexum UI — Radius Tokens
 */

export const radius = {
  card: '14px',
  button: '10px',
  input: '8px',
  pill: '9999px',
  container: '24px',
} as const

export type RadiusToken = keyof typeof radius
