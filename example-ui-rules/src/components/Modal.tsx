import * as React from 'react'
import { cn } from '../utils'

// ─── Types ────────────────────────────────────────────────────────────────────

export interface ModalProps {
  /** Whether the modal is visible */
  open: boolean
  /** Called when the overlay or close button is clicked */
  onClose: () => void
  /** Max width of the modal panel */
  maxWidth?: 'sm' | 'md' | 'lg' | 'xl' | '2xl' | 'full'
  /** Extra class names on the panel */
  className?: string
  children: React.ReactNode
  /** Accessible label (used as aria-labelledby if provided via ModalTitle) */
  'aria-label'?: string
}

const maxWidthClasses: Record<NonNullable<ModalProps['maxWidth']>, string> = {
  sm: 'max-w-sm',
  md: 'max-w-md',
  lg: 'max-w-lg',
  xl: 'max-w-xl',
  '2xl': 'max-w-2xl',
  full: 'max-w-full',
}

// ─── Modal ────────────────────────────────────────────────────────────────────

export const Modal: React.FC<ModalProps> = ({
  open,
  onClose,
  maxWidth = 'lg',
  className,
  children,
  'aria-label': ariaLabel,
}) => {
  // Close on Escape
  React.useEffect(() => {
    if (!open) return
    const handler = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose()
    }
    document.addEventListener('keydown', handler)
    return () => document.removeEventListener('keydown', handler)
  }, [open, onClose])

  // Prevent body scroll
  React.useEffect(() => {
    if (open) {
      document.body.style.overflow = 'hidden'
    } else {
      document.body.style.overflow = ''
    }
    return () => {
      document.body.style.overflow = ''
    }
  }, [open])

  if (!open) return null

  return (
    // Portal-like: fixed fullscreen overlay
    <div
      className="fixed inset-0 z-50 flex items-center justify-center p-4"
      role="dialog"
      aria-modal="true"
      aria-label={ariaLabel}
    >
      {/* Backdrop */}
      <div
        className="absolute inset-0 bg-black/50 backdrop-blur-sm"
        onClick={onClose}
        aria-hidden="true"
      />

      {/* Panel */}
      <div
        className={cn(
          'relative z-10 w-full',
          maxWidthClasses[maxWidth],
          // Card style
          'bg-surface-secondary rounded-card shadow-card',
          'animate-in fade-in-0 zoom-in-95 duration-150',
          className
        )}
        onClick={(e) => e.stopPropagation()}
      >
        {children}
      </div>
    </div>
  )
}

// ─── Modal Header ─────────────────────────────────────────────────────────────

export interface ModalHeaderProps extends React.HTMLAttributes<HTMLDivElement> {
  onClose?: () => void
}

export const ModalHeader: React.FC<ModalHeaderProps> = ({
  onClose,
  className,
  children,
  ...props
}) => (
  <div
    className={cn(
      'flex items-center justify-between p-6 pb-4 border-b border-border-subtle',
      className
    )}
    {...props}
  >
    <div className="flex-1">{children}</div>
    {onClose && (
      <button
        type="button"
        onClick={onClose}
        aria-label="Close modal"
        className={cn(
          'ml-4 p-1.5 rounded-button',
          'text-text-muted hover:text-text-primary',
          'hover:bg-surface-tertiary',
          'transition-colors duration-150',
          'outline-none focus-visible:ring-2 focus-visible:ring-accent',
        )}
      >
        <svg
          xmlns="http://www.w3.org/2000/svg"
          width="16"
          height="16"
          viewBox="0 0 24 24"
          fill="none"
          stroke="currentColor"
          strokeWidth="2"
          strokeLinecap="round"
          strokeLinejoin="round"
          aria-hidden="true"
        >
          <line x1="18" y1="6" x2="6" y2="18" />
          <line x1="6" y1="6" x2="18" y2="18" />
        </svg>
      </button>
    )}
  </div>
)

// ─── Modal Title ─────────────────────────────────────────────────────────────

export interface ModalTitleProps extends React.HTMLAttributes<HTMLHeadingElement> {}

export const ModalTitle: React.FC<ModalTitleProps> = ({ className, children, ...props }) => (
  <h2
    className={cn('text-text-primary font-semibold text-lg leading-tight', className)}
    {...props}
  >
    {children}
  </h2>
)

// ─── Modal Body ───────────────────────────────────────────────────────────────

export interface ModalBodyProps extends React.HTMLAttributes<HTMLDivElement> {}

export const ModalBody: React.FC<ModalBodyProps> = ({ className, children, ...props }) => (
  <div className={cn('p-6 text-text-secondary text-sm', className)} {...props}>
    {children}
  </div>
)

// ─── Modal Footer ─────────────────────────────────────────────────────────────

export interface ModalFooterProps extends React.HTMLAttributes<HTMLDivElement> {}

export const ModalFooter: React.FC<ModalFooterProps> = ({ className, children, ...props }) => (
  <div
    className={cn(
      'flex items-center justify-end gap-3 p-6 pt-4 border-t border-border-subtle',
      className
    )}
    {...props}
  >
    {children}
  </div>
)
