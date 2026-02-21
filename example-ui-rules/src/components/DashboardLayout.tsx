import * as React from 'react'
import { cn } from '../utils'

// ─── Types ────────────────────────────────────────────────────────────────────

export interface SidebarNavItem {
  label: string
  href: string
  icon?: React.ReactNode
  active?: boolean
  /** Sub-items for grouped sections */
  children?: Omit<SidebarNavItem, 'children'>[]
}

export interface SidebarNavGroup {
  heading?: string
  items: SidebarNavItem[]
}

export interface DashboardLayoutProps {
  /** Sidebar navigation groups */
  navGroups?: SidebarNavGroup[]
  /** Logo / brand in sidebar header */
  logo?: React.ReactNode
  /** Top bar breadcrumb */
  breadcrumb?: React.ReactNode
  /** Top bar right slot */
  topBarRight?: React.ReactNode
  /** Main content */
  children: React.ReactNode
  /** Start collapsed on mobile */
  defaultCollapsed?: boolean
  /** Custom link renderer (for router integration) */
  renderLink?: (item: SidebarNavItem) => React.ReactNode
  className?: string
}

// ─── Sidebar Nav Item ─────────────────────────────────────────────────────────

const DefaultNavItem: React.FC<{ item: SidebarNavItem }> = ({ item }) => (
  <a
    href={item.href}
    className={cn(
      'flex items-center gap-3 px-3 py-2 rounded-button text-sm font-medium',
      'transition-colors duration-150',
      item.active
        ? 'bg-accent/15 text-accent'
        : 'text-text-secondary hover:text-text-primary hover:bg-surface-tertiary',
    )}
    aria-current={item.active ? 'page' : undefined}
  >
    {item.icon && (
      <span className="w-4 h-4 flex-shrink-0" aria-hidden="true">
        {item.icon}
      </span>
    )}
    {item.label}
  </a>
)

// ─── Collapse Icon ────────────────────────────────────────────────────────────

const CollapseIcon: React.FC<{ collapsed: boolean }> = ({ collapsed }) => (
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
    className={cn('transition-transform duration-200', collapsed && 'rotate-180')}
    aria-hidden="true"
  >
    <polyline points="15 18 9 12 15 6" />
  </svg>
)

// ─── DashboardLayout ──────────────────────────────────────────────────────────

export const DashboardLayout: React.FC<DashboardLayoutProps> = ({
  navGroups = [],
  logo,
  breadcrumb,
  topBarRight,
  children,
  defaultCollapsed = false,
  renderLink,
  className,
}) => {
  const [collapsed, setCollapsed] = React.useState(defaultCollapsed)

  return (
    <div className={cn('flex h-screen overflow-hidden bg-surface-primary', className)}>
      {/* ── Sidebar ─────────────────────────────────────────────────────── */}
      <aside
        className={cn(
          'flex flex-col flex-shrink-0',
          'bg-surface-secondary border-r border-border-subtle',
          'transition-all duration-200 ease-in-out',
          collapsed ? 'w-16' : 'w-64',
        )}
      >
        {/* Sidebar Header */}
        <div
          className={cn(
            'h-16 flex items-center border-b border-border-subtle flex-shrink-0',
            collapsed ? 'justify-center px-2' : 'justify-between px-4',
          )}
        >
          {!collapsed && logo && (
            <div className="flex-1 min-w-0">{logo}</div>
          )}
          {collapsed && logo && (
            <div className="flex items-center justify-center w-8 h-8">{logo}</div>
          )}
          <button
            type="button"
            onClick={() => setCollapsed((c) => !c)}
            aria-label={collapsed ? 'Expand sidebar' : 'Collapse sidebar'}
            className={cn(
              'p-1.5 rounded-button text-text-muted hover:text-text-primary',
              'hover:bg-surface-tertiary transition-colors duration-150',
              'outline-none focus-visible:ring-2 focus-visible:ring-accent',
              collapsed && 'rotate-180',
            )}
          >
            <CollapseIcon collapsed={!collapsed} />
          </button>
        </div>

        {/* Nav Groups */}
        <nav className="flex-1 overflow-y-auto py-4 px-2 space-y-6" aria-label="Sidebar navigation">
          {navGroups.map((group, gi) => (
            <div key={gi}>
              {group.heading && !collapsed && (
                <p className="px-3 mb-1 text-xs font-semibold uppercase tracking-wider text-text-muted">
                  {group.heading}
                </p>
              )}
              <div className="space-y-0.5">
                {group.items.map((item) =>
                  renderLink ? (
                    <React.Fragment key={item.href}>{renderLink(item)}</React.Fragment>
                  ) : (
                    <DefaultNavItem key={item.href} item={item} />
                  )
                )}
              </div>
            </div>
          ))}
        </nav>
      </aside>

      {/* ── Main Area ───────────────────────────────────────────────────── */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        {/* Top Bar */}
        <header className="h-16 flex-shrink-0 flex items-center justify-between px-6 border-b border-border-subtle bg-surface-primary">
          {/* Breadcrumb */}
          <div className="flex items-center min-w-0">
            {breadcrumb ?? <span className="text-text-muted text-sm">Dashboard</span>}
          </div>
          {/* Right slot */}
          {topBarRight && (
            <div className="flex items-center gap-3 flex-shrink-0 ml-4">
              {topBarRight}
            </div>
          )}
        </header>

        {/* Content */}
        <main className="flex-1 overflow-y-auto bg-surface-primary p-6">
          {children}
        </main>
      </div>
    </div>
  )
}

DashboardLayout.displayName = 'DashboardLayout'
