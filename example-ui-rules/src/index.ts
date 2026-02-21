// ─── Utilities ────────────────────────────────────────────────────────────────
export { cn } from './utils'

// ─── Design Tokens ────────────────────────────────────────────────────────────
export { colors } from './tokens/colors'
export { cssTokens } from './tokens/css-string'
export type { ColorToken } from './tokens/colors'

export { shadows } from './tokens/shadows'
export type { ShadowToken } from './tokens/shadows'

export { radius } from './tokens/radius'
export type { RadiusToken } from './tokens/radius'

// ─── Presets & Runtime Theme Switching ────────────────────────────────────────
export { presets, presetNames, applyPreset, resetPreset } from './presets'
export type { ColorPreset } from './presets'

// ─── Components ───────────────────────────────────────────────────────────────

// Button
export { Button } from './components/Button'
export type { ButtonProps, ButtonVariant, ButtonSize } from './components/Button'

// Card
export {
  Card,
  CardHeader,
  CardTitle,
  CardDescription,
  CardContent,
  CardFooter,
} from './components/Card'
export type {
  CardProps,
  CardHeaderProps,
  CardTitleProps,
  CardDescriptionProps,
  CardContentProps,
  CardFooterProps,
} from './components/Card'

// Input
export { Input } from './components/Input'
export type { InputProps, InputSize } from './components/Input'

// Badge
export { Badge } from './components/Badge'
export type { BadgeProps, BadgeVariant } from './components/Badge'

// Table
export {
  Table,
  TableHead,
  TableBody,
  TableRow,
  TableHeaderCell,
  TableCell,
  TableFooter,
} from './components/Table'
export type {
  TableProps,
  TableHeadProps,
  TableBodyProps,
  TableRowProps,
  TableHeaderCellProps,
  TableCellProps,
  TableFooterProps,
} from './components/Table'

// Modal
export {
  Modal,
  ModalHeader,
  ModalTitle,
  ModalBody,
  ModalFooter,
} from './components/Modal'
export type {
  ModalProps,
  ModalHeaderProps,
  ModalTitleProps,
  ModalBodyProps,
  ModalFooterProps,
} from './components/Modal'

// Nav
export { Nav } from './components/Nav'
export type { NavProps, NavLink } from './components/Nav'

// DashboardLayout
export { DashboardLayout } from './components/DashboardLayout'
export type {
  DashboardLayoutProps,
  SidebarNavItem,
  SidebarNavGroup,
} from './components/DashboardLayout'
