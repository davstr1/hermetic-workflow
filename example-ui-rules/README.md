# @nexum/ui

> Opinionated dark-mode-first UI component library for Nexum projects — dashboards, tools, landing pages.

Built with **React 18+**, **TypeScript**, and **Tailwind CSS 3.4+**. Ships as ESM + CJS via tsup.

---

## Installation

```bash
npm install @nexum/ui
# or
pnpm add @nexum/ui
```

Peer dependencies (install separately in your app):

```bash
npm install react react-dom tailwindcss
```

---

## Setup

### 1 — Tailwind config

Import the Nexum preset in your `tailwind.config.ts`:

```ts
import nexumPreset from '@nexum/ui/tailwind-preset'
import type { Config } from 'tailwindcss'

export default {
  presets: [nexumPreset],
  content: [
    './src/**/*.{ts,tsx}',
    './node_modules/@nexum/ui/src/**/*.{ts,tsx}', // ← include library source
  ],
} satisfies Config
```

This injects all semantic colors, radius values, and shadows into your Tailwind theme.

### 2 — Base styles

Import the base CSS once (in your app root or `_app.tsx`):

```ts
import '@nexum/ui/styles'
```

This pulls in `@tailwind base/components/utilities` plus the Nexum base resets.

### 3 — Use components

```tsx
import { Button, Card, CardHeader, CardTitle, CardContent } from '@nexum/ui'

export default function App() {
  return (
    <Card>
      <CardHeader>
        <CardTitle>Hello Nexum</CardTitle>
      </CardHeader>
      <CardContent>
        <Button variant="primary">Get started</Button>
      </CardContent>
    </Card>
  )
}
```

---

## Components

### `<Button>`

```tsx
<Button variant="primary" size="md">Click me</Button>
<Button variant="secondary">Cancel</Button>
<Button variant="danger" loading>Deleting…</Button>
<Button variant="ghost" size="sm">Learn more</Button>
```

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `variant` | `primary \| secondary \| danger \| ghost` | `primary` | Visual style |
| `size` | `sm \| md \| lg` | `md` | Height/padding |
| `loading` | `boolean` | `false` | Shows spinner, disables button |

---

### `<Card>` / `<CardHeader>` / `<CardTitle>` / `<CardContent>` / `<CardFooter>`

```tsx
<Card>
  <CardHeader>
    <CardTitle>Revenue</CardTitle>
    <CardDescription>Last 30 days</CardDescription>
  </CardHeader>
  <CardContent>$12,400</CardContent>
  <CardFooter>
    <Button variant="ghost" size="sm">View details</Button>
  </CardFooter>
</Card>
```

| Prop (Card) | Type | Default | Description |
|-------------|------|---------|-------------|
| `noPadding` | `boolean` | `false` | Remove default `p-6` |

---

### `<Input>`

```tsx
<Input
  label="Email"
  placeholder="you@example.com"
  type="email"
  hint="We'll never share your email."
/>

<Input
  label="Password"
  type="password"
  error="Password must be at least 8 characters."
/>
```

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `inputSize` | `sm \| md \| lg` | `md` | Height/padding |
| `label` | `string` | — | Label above the input |
| `error` | `string` | — | Error message below |
| `hint` | `string` | — | Helper text below |
| `leftAddon` | `ReactNode` | — | Icon/element on the left |
| `rightAddon` | `ReactNode` | — | Icon/element on the right |

---

### `<Badge>`

```tsx
<Badge variant="accent">New</Badge>
<Badge variant="success" dot>Active</Badge>
<Badge variant="warning">Pending</Badge>
<Badge variant="danger">Failed</Badge>
```

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `variant` | `default \| accent \| success \| warning \| danger \| info` | `default` | Color style |
| `dot` | `boolean` | `false` | Show leading dot |

---

### `<Table>`

```tsx
<Table>
  <TableHead>
    <TableRow>
      <TableHeaderCell>Name</TableHeaderCell>
      <TableHeaderCell>Status</TableHeaderCell>
      <TableHeaderCell>Revenue</TableHeaderCell>
    </TableRow>
  </TableHead>
  <TableBody>
    {rows.map((row, i) => (
      <TableRow key={row.id} index={i}>
        <TableCell>{row.name}</TableCell>
        <TableCell><Badge variant="success">{row.status}</Badge></TableCell>
        <TableCell>{row.revenue}</TableCell>
      </TableRow>
    ))}
  </TableBody>
</Table>
```

Pass `index` prop to `TableRow` for deterministic alternating backgrounds (useful for SSR).

---

### `<Modal>`

```tsx
const [open, setOpen] = React.useState(false)

<Button onClick={() => setOpen(true)}>Open modal</Button>

<Modal open={open} onClose={() => setOpen(false)}>
  <ModalHeader onClose={() => setOpen(false)}>
    <ModalTitle>Confirm delete</ModalTitle>
  </ModalHeader>
  <ModalBody>
    This action cannot be undone. Are you sure?
  </ModalBody>
  <ModalFooter>
    <Button variant="secondary" onClick={() => setOpen(false)}>Cancel</Button>
    <Button variant="danger">Delete</Button>
  </ModalFooter>
</Modal>
```

| Prop | Type | Default | Description |
|------|------|---------|-------------|
| `open` | `boolean` | — | **Required.** Controls visibility |
| `onClose` | `() => void` | — | **Required.** Called on overlay click or Escape |
| `maxWidth` | `sm \| md \| lg \| xl \| 2xl \| full` | `lg` | Panel max width |

---

### `<Nav>`

```tsx
<Nav
  logo={<span className="font-bold text-text-primary">Nexum</span>}
  links={[
    { label: 'Home', href: '/', active: true },
    { label: 'Docs', href: '/docs' },
    { label: 'Pricing', href: '/pricing' },
  ]}
  cta={<Button size="sm">Sign up</Button>}
/>
```

For Next.js / React Router, pass a `renderLink` prop to use your router's `<Link>` component.

---

### `<DashboardLayout>`

```tsx
<DashboardLayout
  logo={<span className="font-bold text-text-primary">Nexum</span>}
  navGroups={[
    {
      heading: 'General',
      items: [
        { label: 'Dashboard', href: '/', active: true, icon: <HomeIcon /> },
        { label: 'Analytics', href: '/analytics', icon: <BarChartIcon /> },
      ],
    },
    {
      heading: 'Settings',
      items: [
        { label: 'Account', href: '/account', icon: <UserIcon /> },
      ],
    },
  ]}
  breadcrumb={<span className="text-text-primary font-medium">Dashboard</span>}
  topBarRight={<Button size="sm" variant="secondary">Invite</Button>}
>
  <h1>Page content here</h1>
</DashboardLayout>
```

The sidebar collapses to icon-only mode (w-16) via its built-in toggle button.

---

## Design Tokens

All tokens are available as Tailwind classes after importing the preset:

| Token | Class |
|-------|-------|
| `surface-primary` | `bg-surface-primary`, `text-surface-primary` |
| `accent` | `bg-accent`, `text-accent`, `border-accent` |
| `border-default` | `border-border-default` |
| card radius (14px) | `rounded-card` |
| button radius (10px) | `rounded-button` |
| card shadow | `shadow-card` |
| glow shadow | `shadow-glow` |

You can also import tokens directly in JS/TS:

```ts
import { colors, shadows, radius } from '@nexum/ui'

console.log(colors.dark.accent) // '#6366f1'
console.log(shadows.card) // '0px 1px 0px ...'
```

---

## Light mode

Dark mode is the default. Add the `light` class to `<html>` to switch:

```html
<html class="light">
```

The preset ships `-light` color variants (e.g. `surface-primary-light`) for explicit overrides.
Full light-mode support via `darkMode: 'class'` in the Tailwind config.

---

## Building

```bash
pnpm run build       # produces dist/ (ESM + CJS + .d.ts)
pnpm run build:watch # watch mode
pnpm run type-check  # tsc --noEmit
pnpm run lint        # eslint
```

---

## License

MIT © Nexum
