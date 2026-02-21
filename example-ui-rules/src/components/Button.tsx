import * as React from 'react'
import { cn } from '../utils'

export type ButtonVariant = 'primary' | 'secondary' | 'danger' | 'ghost'
export type ButtonSize = 'sm' | 'md' | 'lg'

export interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant
  size?: ButtonSize
  loading?: boolean
  /** Render as a different element (e.g. anchor) */
  asChild?: boolean
}

const variantClasses: Record<ButtonVariant, string> = {
  primary: [
    // text-accent-text resolves to var(--accent-text), defaulting to #fff.
    // Presets override --accent-text at runtime (e.g. mono → #09090b).
    'bg-accent text-accent-text border border-transparent',
    'hover:bg-accent-hover hover:shadow-glow',
    'focus-visible:ring-2 focus-visible:ring-accent focus-visible:ring-offset-2 focus-visible:ring-offset-surface-primary',
    'active:bg-accent',
    'disabled:opacity-50 disabled:cursor-not-allowed disabled:shadow-none',
  ].join(' '),

  secondary: [
    'bg-surface-secondary text-text-primary border border-border-default',
    'hover:bg-surface-tertiary hover:border-border-strong',
    'focus-visible:ring-2 focus-visible:ring-accent focus-visible:ring-offset-2 focus-visible:ring-offset-surface-primary',
    'active:bg-surface-tertiary',
    'disabled:opacity-50 disabled:cursor-not-allowed',
  ].join(' '),

  danger: [
    'bg-danger text-white border border-transparent',
    'hover:bg-danger/90',
    'focus-visible:ring-2 focus-visible:ring-danger focus-visible:ring-offset-2 focus-visible:ring-offset-surface-primary',
    'active:bg-danger/80',
    'disabled:opacity-50 disabled:cursor-not-allowed',
  ].join(' '),

  ghost: [
    'bg-transparent text-text-secondary border border-transparent',
    'hover:bg-surface-tertiary hover:text-text-primary',
    'focus-visible:ring-2 focus-visible:ring-accent focus-visible:ring-offset-2 focus-visible:ring-offset-surface-primary',
    'active:bg-surface-tertiary',
    'disabled:opacity-50 disabled:cursor-not-allowed',
  ].join(' '),
}

const sizeClasses: Record<ButtonSize, string> = {
  sm: 'h-8 px-3 text-xs gap-1.5',
  md: 'h-10 px-4 text-sm gap-2',
  lg: 'h-12 px-6 text-base gap-2.5',
}

const Spinner = () => (
  <svg
    className="animate-spin h-4 w-4"
    xmlns="http://www.w3.org/2000/svg"
    fill="none"
    viewBox="0 0 24 24"
    aria-hidden="true"
  >
    <circle
      className="opacity-25"
      cx="12"
      cy="12"
      r="10"
      stroke="currentColor"
      strokeWidth="4"
    />
    <path
      className="opacity-75"
      fill="currentColor"
      d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z"
    />
  </svg>
)

export const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  (
    {
      variant = 'primary',
      size = 'md',
      loading = false,
      disabled,
      className,
      children,
      ...props
    },
    ref
  ) => {
    return (
      <button
        ref={ref}
        disabled={disabled || loading}
        className={cn(
          // Base
          'inline-flex items-center justify-center font-medium',
          'rounded-button',
          'transition-all duration-150 ease-in-out',
          'select-none whitespace-nowrap',
          'outline-none',
          // Variant + size
          variantClasses[variant],
          sizeClasses[size],
          className
        )}
        {...props}
      >
        {loading && <Spinner />}
        {children}
      </button>
    )
  }
)

Button.displayName = 'Button'
