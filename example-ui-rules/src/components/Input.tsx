import * as React from 'react'
import { cn } from '../utils'

export type InputSize = 'sm' | 'md' | 'lg'

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  /** Input size variant */
  inputSize?: InputSize
  /** Label displayed above the input */
  label?: string
  /** Error message displayed below the input */
  error?: string
  /** Helper text displayed below the input (hidden when error is shown) */
  hint?: string
  /** Left-side icon/element */
  leftAddon?: React.ReactNode
  /** Right-side icon/element */
  rightAddon?: React.ReactNode
}

const sizeClasses: Record<InputSize, string> = {
  sm: 'h-8 px-2.5 text-xs',
  md: 'h-10 px-3 text-sm',
  lg: 'h-12 px-4 text-base',
}

const addonSizeClasses: Record<InputSize, string> = {
  sm: 'px-2.5',
  md: 'px-3',
  lg: 'px-4',
}

export const Input = React.forwardRef<HTMLInputElement, InputProps>(
  (
    {
      inputSize = 'md',
      label,
      error,
      hint,
      leftAddon,
      rightAddon,
      id,
      className,
      disabled,
      ...props
    },
    ref
  ) => {
    const generatedId = React.useId()
    const inputId = id ?? generatedId
    const errorId = `${inputId}-error`
    const hintId = `${inputId}-hint`

    return (
      <div className="flex flex-col gap-1.5 w-full">
        {/* Label */}
        {label && (
          <label
            htmlFor={inputId}
            className={cn(
              'text-text-secondary font-medium',
              inputSize === 'sm' ? 'text-xs' : 'text-sm',
              disabled && 'opacity-50 cursor-not-allowed'
            )}
          >
            {label}
          </label>
        )}

        {/* Input wrapper */}
        <div
          className={cn(
            'relative flex items-center',
            'bg-surface-tertiary border border-border-default',
            'rounded-input',
            'transition-all duration-150',
            // Focus-within ring
            'has-[:focus]:border-accent has-[:focus]:shadow-[0_0_0_3px_rgba(99,102,241,0.15)]',
            // Error state
            error && 'border-danger has-[:focus]:border-danger has-[:focus]:shadow-[0_0_0_3px_rgba(239,68,68,0.15)]',
            // Disabled
            disabled && 'opacity-50 cursor-not-allowed',
          )}
        >
          {/* Left addon */}
          {leftAddon && (
            <span className={cn('text-text-muted flex-shrink-0', addonSizeClasses[inputSize])}>
              {leftAddon}
            </span>
          )}

          <input
            ref={ref}
            id={inputId}
            disabled={disabled}
            aria-invalid={!!error}
            aria-describedby={error ? errorId : hint ? hintId : undefined}
            className={cn(
              'flex-1 bg-transparent text-text-primary placeholder:text-text-muted',
              'outline-none border-none',
              'disabled:cursor-not-allowed',
              sizeClasses[inputSize],
              // Remove padding if addons present
              leftAddon && 'pl-0',
              rightAddon && 'pr-0',
              className
            )}
            {...props}
          />

          {/* Right addon */}
          {rightAddon && (
            <span className={cn('text-text-muted flex-shrink-0', addonSizeClasses[inputSize])}>
              {rightAddon}
            </span>
          )}
        </div>

        {/* Error / Hint */}
        {error ? (
          <p id={errorId} role="alert" className="text-danger text-xs">
            {error}
          </p>
        ) : hint ? (
          <p id={hintId} className="text-text-muted text-xs">
            {hint}
          </p>
        ) : null}
      </div>
    )
  }
)

Input.displayName = 'Input'
