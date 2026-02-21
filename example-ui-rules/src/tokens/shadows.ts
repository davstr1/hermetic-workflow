/**
 * Nexum UI — Shadow Tokens
 */

export const shadows = {
  card: '0px 1px 0px 0px rgba(255,255,255,0.10) inset, 0px 30px 50px rgba(0,0,0,0.40)',
  subtle: '0 28px 70px rgba(0,0,0,0.14), 0 14px 32px rgba(0,0,0,0.08)',
  glow: '0 0 40px 10px hsla(249, 91%, 77%, 0.1)',
  none: 'none',
} as const

export type ShadowToken = keyof typeof shadows
