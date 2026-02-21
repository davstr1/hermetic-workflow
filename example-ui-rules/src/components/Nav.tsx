import * as React from 'react'
import { cn } from '../utils'

// ─── Types ────────────────────────────────────────────────────────────────────

export interface NavLink {
  label: string
  href: string
  active?: boolean
}

export interface NavProps extends React.HTMLAttributes<HTMLElement> {
  /** Brand logo or text */
  logo?: React.ReactNode
  /** Navigation links for the center */
  links?: NavLink[]
  /** CTA button or element for the right side */
  cta?: React.ReactNode
  /** Custom link renderer (for router integration) */
  renderLink?: (link: NavLink) => React.ReactNode
}

// ─── Nav ──────────────────────────────────────────────────────────────────────

export const Nav = React.forwardRef<HTMLElement, NavProps>(
  ({ logo, links = [], cta, renderLink, className, children, ...props }, ref) => {
    const defaultRenderLink = (link: NavLink) => (
      <a
        key={link.href}
        href={link.href}
        className={cn(
          'px-3 py-1.5 rounded-button text-sm font-medium transition-colors duration-150',
          link.active
            ? 'text-text-primary bg-surface-tertiary'
            : 'text-text-secondary hover:text-text-primary hover:bg-surface-tertiary',
        )}
        aria-current={link.active ? 'page' : undefined}
      >
        {link.label}
      </a>
    )

    const resolvedRenderLink = renderLink ?? defaultRenderLink

    return (
      <header
        ref={ref}
        className={cn(
          'sticky top-0 z-40 w-full h-16',
          'bg-surface-primary/80 backdrop-blur-md',
          'border-b border-border-default',
          className
        )}
        {...props}
      >
        <div className="h-full max-w-screen-xl mx-auto px-4 sm:px-6 lg:px-8 flex items-center gap-6">
          {/* Logo */}
          {logo && (
            <div className="flex-shrink-0 flex items-center">
              {logo}
            </div>
          )}

          {/* Center links */}
          {links.length > 0 && (
            <nav
              aria-label="Main navigation"
              className="hidden md:flex items-center gap-1 flex-1 justify-center"
            >
              {links.map((link) => resolvedRenderLink(link))}
            </nav>
          )}

          {/* Spacer when no links */}
          {links.length === 0 && <div className="flex-1" />}

          {/* CTA */}
          {cta && (
            <div className="flex-shrink-0 flex items-center">
              {cta}
            </div>
          )}

          {/* Extra children (e.g. mobile menu toggle) */}
          {children}
        </div>
      </header>
    )
  }
)

Nav.displayName = 'Nav'
