import * as React from 'react'
import { cn } from '../utils'

// ─── Table Root ───────────────────────────────────────────────────────────────

export interface TableProps extends React.HTMLAttributes<HTMLDivElement> {
  /** Remove max-height / overflow (useful when table is already in scrollable container) */
  noScroll?: boolean
}

export const Table = React.forwardRef<HTMLDivElement, TableProps>(
  ({ noScroll = false, className, children, ...props }, ref) => (
    <div
      ref={ref}
      className={cn(
        'w-full rounded-container bg-surface-primary',
        'border border-border-subtle overflow-hidden',
        !noScroll && 'overflow-x-auto',
        className
      )}
      {...props}
    >
      <table className="w-full border-collapse text-sm">
        {children}
      </table>
    </div>
  )
)
Table.displayName = 'Table'

// ─── Table Head ───────────────────────────────────────────────────────────────

export interface TableHeadProps extends React.HTMLAttributes<HTMLTableSectionElement> {}

export const TableHead = React.forwardRef<HTMLTableSectionElement, TableHeadProps>(
  ({ className, children, ...props }, ref) => (
    <thead
      ref={ref}
      className={cn(
        'sticky top-0 z-10',
        'bg-surface-secondary',
        'border-b border-border-subtle',
        className
      )}
      {...props}
    >
      {children}
    </thead>
  )
)
TableHead.displayName = 'TableHead'

// ─── Table Body ───────────────────────────────────────────────────────────────

export interface TableBodyProps extends React.HTMLAttributes<HTMLTableSectionElement> {}

export const TableBody = React.forwardRef<HTMLTableSectionElement, TableBodyProps>(
  ({ className, children, ...props }, ref) => (
    <tbody ref={ref} className={cn(className)} {...props}>
      {children}
    </tbody>
  )
)
TableBody.displayName = 'TableBody'

// ─── Table Row ────────────────────────────────────────────────────────────────

export interface TableRowProps extends React.HTMLAttributes<HTMLTableRowElement> {
  /** Index used to determine alternating background */
  index?: number
}

export const TableRow = React.forwardRef<HTMLTableRowElement, TableRowProps>(
  ({ index, className, children, ...props }, ref) => (
    <tr
      ref={ref}
      className={cn(
        'transition-colors',
        // Alternating rows — no hard borders
        index !== undefined
          ? index % 2 === 0
            ? 'bg-surface-primary'
            : 'bg-surface-secondary'
          : 'even:bg-surface-secondary odd:bg-surface-primary',
        'hover:bg-surface-tertiary',
        className
      )}
      {...props}
    >
      {children}
    </tr>
  )
)
TableRow.displayName = 'TableRow'

// ─── Table Header Cell ────────────────────────────────────────────────────────

export interface TableHeaderCellProps extends React.ThHTMLAttributes<HTMLTableCellElement> {}

export const TableHeaderCell = React.forwardRef<HTMLTableCellElement, TableHeaderCellProps>(
  ({ className, children, ...props }, ref) => (
    <th
      ref={ref}
      className={cn(
        'px-4 py-3 text-left',
        'text-xs font-semibold uppercase tracking-wider',
        'text-text-muted',
        'whitespace-nowrap',
        className
      )}
      {...props}
    >
      {children}
    </th>
  )
)
TableHeaderCell.displayName = 'TableHeaderCell'

// ─── Table Cell ───────────────────────────────────────────────────────────────

export interface TableCellProps extends React.TdHTMLAttributes<HTMLTableCellElement> {}

export const TableCell = React.forwardRef<HTMLTableCellElement, TableCellProps>(
  ({ className, children, ...props }, ref) => (
    <td
      ref={ref}
      className={cn('px-4 py-3 text-text-secondary', className)}
      {...props}
    >
      {children}
    </td>
  )
)
TableCell.displayName = 'TableCell'

// ─── Table Footer ─────────────────────────────────────────────────────────────

export interface TableFooterProps extends React.HTMLAttributes<HTMLTableSectionElement> {}

export const TableFooter = React.forwardRef<HTMLTableSectionElement, TableFooterProps>(
  ({ className, children, ...props }, ref) => (
    <tfoot
      ref={ref}
      className={cn(
        'bg-surface-secondary border-t border-border-subtle text-text-secondary text-sm',
        className
      )}
      {...props}
    >
      {children}
    </tfoot>
  )
)
TableFooter.displayName = 'TableFooter'
