import * as React from 'react'
import { cn } from '../utils'

export type BadgeVariant = 'default' | 'accent' | 'success' | 'warning' | 'danger' | 'info'

export interface BadgeProps extends React.HTMLAttributes<HTMLSpanElement> {
  variant?: BadgeVariant
  /** Show a leading dot indicator */
  dot?: boolean
}

const variantClasses: Record<BadgeVariant, string> = {
  default:
    'bg-surface-tertiary text-text-secondary border border-border-default',
  accent:
    'bg-accent/15 text-accent border border-accent/20',
  success:
    'bg-success/15 text-success border border-success/20',
  warning:
    'bg-warning/15 text-warning border border-warning/20',
  danger:
    'bg-danger/15 text-danger border border-danger/20',
  info:
    'bg-info/15 text-info border border-info/20',
}

const dotVariantClasses: Record<BadgeVariant, string> = {
  default: 'bg-text-muted',
  accent: 'bg-accent',
  success: 'bg-success',
  warning: 'bg-warning',
  danger: 'bg-danger',
  info: 'bg-info',
}

export const Badge = React.forwardRef<HTMLSpanElement, BadgeProps>(
  ({ variant = 'default', dot = false, className, children, ...props }, ref) => (
    <span
      ref={ref}
      className={cn(
        'inline-flex items-center gap-1.5',
        'rounded-pill px-2 py-0.5',
        'text-xs font-medium',
        'whitespace-nowrap',
        variantClasses[variant],
        className
      )}
      {...props}
    >
      {dot && (
        <span
          className={cn('w-1.5 h-1.5 rounded-full flex-shrink-0', dotVariantClasses[variant])}
          aria-hidden="true"
        />
      )}
      {children}
    </span>
  )
)

Badge.displayName = 'Badge'
