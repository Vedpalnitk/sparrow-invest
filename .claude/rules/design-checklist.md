# Design System Validation Checklist

Use this checklist after implementing or updating any page to ensure consistency with the Sparrow Invest design system.

---

## Portal Themes

The Sparrow Invest platform uses a **unified Main Design (Blue/Cyan)** theme:

| Portal | Primary Color | Secondary Color | Use Case |
|--------|--------------|-----------------|----------|
| **Admin Portal** | Blue (#3B82F6) | Cyan (#38BDF8) | Admin dashboard, system management |
| **FA Portal** | Blue (#3B82F6) | Cyan (#38BDF8) | Financial advisor interface |

> **Note:** Both portals use the same Blue/Cyan theme for consistent branding across the platform.

---

## Font

**Primary Font: Plus Jakarta Sans** — A modern, geometric sans-serif with soft, rounded terminals. Popular in fintech/SaaS dashboards.

### Import
```css
@import url('https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@300;400;500;600;700&display=swap');
```

### CSS Variable
```css
--font-main: 'Plus Jakarta Sans', system-ui, -apple-system, sans-serif;
```

### Font Weights
| Weight | Value | Use Case |
|--------|-------|----------|
| Light | `300` | Decorative, large display text |
| Regular | `400` | Body text, descriptions |
| Medium | `500` | Labels, subtitles |
| Semibold | `600` | Headings, buttons, emphasis |
| Bold | `700` | Stats, values, key metrics |

### Key Rules
- [ ] All UI text uses Plus Jakarta Sans font family
- [ ] Never use font weights below 400 or above 700
- [ ] Use `font-semibold` (600) for interactive elements
- [ ] Use `font-bold` (700) for numerical values and stats

---

## Admin Portal Colors (Blue/Cyan)

### Light Mode
```typescript
const ADMIN_COLORS_LIGHT = {
  // Primary Blue (Subtle)
  primary: '#3B82F6',        // Soft blue
  primaryDark: '#2563EB',
  primaryDeep: '#1D4ED8',
  accent: '#60A5FA',         // Light sky blue

  // Secondary Cyan (Subtle)
  secondary: '#38BDF8',      // Soft cyan
  secondaryDark: '#0EA5E9',

  // Semantic
  success: '#10B981',
  warning: '#F59E0B',
  error: '#EF4444',

  // Backgrounds
  background: '#FFFFFF',
  backgroundSecondary: '#F8FAFC',
  backgroundTertiary: '#F1F5F9',

  // Glass (Subtle)
  glassBackground: 'rgba(255, 255, 255, 0.85)',
  glassBorder: 'rgba(59, 130, 246, 0.1)',
  glassShadow: 'rgba(59, 130, 246, 0.06)',

  // Text
  textPrimary: '#1E293B',
  textSecondary: '#64748B',
  textTertiary: '#94A3B8',

  // Cards (Subtle opacity)
  cardBg: 'linear-gradient(135deg, rgba(59, 130, 246, 0.03) 0%, rgba(96, 165, 250, 0.01) 100%)',
  cardBorder: 'rgba(59, 130, 246, 0.08)',

  // Inputs
  inputBg: 'rgba(59, 130, 246, 0.02)',
  inputBorder: 'rgba(59, 130, 246, 0.1)',

  // Chips/Badges
  chipBg: 'rgba(59, 130, 246, 0.04)',
  chipBorder: 'rgba(59, 130, 246, 0.1)',
};
```

### Dark Mode
```typescript
const ADMIN_COLORS_DARK = {
  // Primary Blue (Soft for dark mode)
  primary: '#93C5FD',        // Soft sky blue
  primaryDark: '#60A5FA',
  primaryDeep: '#3B82F6',
  accent: '#BFDBFE',         // Very light blue

  // Secondary Cyan (Soft)
  secondary: '#7DD3FC',      // Soft cyan
  secondaryDark: '#38BDF8',

  // Semantic
  success: '#34D399',
  warning: '#FBBF24',
  error: '#F87171',

  // Backgrounds - Deep navy
  background: '#0B1120',
  backgroundSecondary: '#111827',
  backgroundTertiary: '#1E293B',

  // Glass (Subtle)
  glassBackground: 'rgba(17, 24, 39, 0.85)',
  glassBorder: 'rgba(147, 197, 253, 0.1)',
  glassShadow: 'rgba(0, 0, 0, 0.3)',

  // Text
  textPrimary: '#F8FAFC',
  textSecondary: '#E2E8F0',
  textTertiary: '#94A3B8',

  // Cards (Subtle opacity)
  cardBg: 'linear-gradient(135deg, rgba(147, 197, 253, 0.06) 0%, rgba(191, 219, 254, 0.03) 100%)',
  cardBorder: 'rgba(147, 197, 253, 0.12)',

  // Inputs
  inputBg: 'rgba(147, 197, 253, 0.04)',
  inputBorder: 'rgba(147, 197, 253, 0.12)',

  // Chips/Badges
  chipBg: 'rgba(147, 197, 253, 0.06)',
  chipBorder: 'rgba(147, 197, 253, 0.12)',
};
```

---

## FA Portal Colors (Purple/Pink)

### Light Mode
```typescript
const FA_COLORS_LIGHT = {
  // Primary Purple (Subtle)
  primary: '#A855F7',        // Soft lavender
  primaryDark: '#9333EA',
  primaryDeep: '#7C3AED',
  accent: '#C084FC',         // Light lavender

  // Secondary Pink (Subtle)
  secondary: '#F472B6',      // Soft pink
  secondaryDark: '#EC4899',

  // Semantic
  success: '#10B981',
  warning: '#F59E0B',
  error: '#EF4444',

  // Backgrounds
  background: '#FFFFFF',
  backgroundSecondary: '#FEFBFF',
  backgroundTertiary: '#FAF5FF',

  // Glass (Subtle)
  glassBackground: 'rgba(255, 255, 255, 0.85)',
  glassBorder: 'rgba(168, 85, 247, 0.1)',
  glassShadow: 'rgba(168, 85, 247, 0.06)',

  // Text
  textPrimary: '#1E293B',
  textSecondary: '#64748B',
  textTertiary: '#94A3B8',

  // Cards (Subtle opacity)
  cardBg: 'linear-gradient(135deg, rgba(168, 85, 247, 0.03) 0%, rgba(244, 114, 182, 0.01) 100%)',
  cardBorder: 'rgba(168, 85, 247, 0.08)',

  // Inputs
  inputBg: 'rgba(168, 85, 247, 0.02)',
  inputBorder: 'rgba(168, 85, 247, 0.1)',

  // Chips/Badges
  chipBg: 'rgba(168, 85, 247, 0.04)',
  chipBorder: 'rgba(168, 85, 247, 0.1)',
};
```

### Dark Mode
```typescript
const FA_COLORS_DARK = {
  // Primary Purple (Soft for dark mode)
  primary: '#D8B4FE',        // Soft lavender
  primaryDark: '#C084FC',
  primaryDeep: '#A855F7',
  accent: '#E9D5FF',         // Very light purple

  // Secondary Pink (Soft)
  secondary: '#F9A8D4',      // Soft pink
  secondaryDark: '#F472B6',

  // Semantic
  success: '#34D399',
  warning: '#FBBF24',
  error: '#F87171',

  // Backgrounds - Deep purple
  background: '#0F0B18',
  backgroundSecondary: '#1A1128',
  backgroundTertiary: '#251A3A',

  // Glass (Subtle)
  glassBackground: 'rgba(26, 17, 40, 0.85)',
  glassBorder: 'rgba(216, 180, 254, 0.1)',
  glassShadow: 'rgba(0, 0, 0, 0.3)',

  // Text
  textPrimary: '#F8FAFC',
  textSecondary: '#E2E8F0',
  textTertiary: '#94A3B8',

  // Cards (Subtle opacity)
  cardBg: 'linear-gradient(135deg, rgba(216, 180, 254, 0.06) 0%, rgba(249, 168, 212, 0.03) 100%)',
  cardBorder: 'rgba(216, 180, 254, 0.12)',

  // Inputs
  inputBg: 'rgba(216, 180, 254, 0.04)',
  inputBorder: 'rgba(216, 180, 254, 0.12)',

  // Chips/Badges
  chipBg: 'rgba(216, 180, 254, 0.06)',
  chipBorder: 'rgba(216, 180, 254, 0.12)',
};
```

---

## Color Comparison Quick Reference

### Primary Colors
| Portal | Light Mode | Dark Mode |
|--------|------------|-----------|
| Admin | `#3B82F6` | `#93C5FD` |
| FA | `#A855F7` | `#D8B4FE` |

### Secondary Colors
| Portal | Light Mode | Dark Mode |
|--------|------------|-----------|
| Admin | `#38BDF8` | `#7DD3FC` |
| FA | `#F472B6` | `#F9A8D4` |

### Accent Colors
| Portal | Light Mode | Dark Mode |
|--------|------------|-----------|
| Admin | `#60A5FA` | `#BFDBFE` |
| FA | `#C084FC` | `#E9D5FF` |

---

## Border Radius

| Element | Radius | Notes |
|---------|--------|-------|
| Buttons | `rounded-full` | Pill shape for all buttons |
| Inputs/Selects | `rounded-xl` | All form controls |
| Glass Cards | `rounded-xl` | Main section containers |
| Tinted Cards | `rounded-2xl` | Interactive list items with hover |
| Liquid Glass | `rounded-3xl` | Premium KPI tiles |
| Chips/Tags | `rounded` | Small inline elements |
| Icon Containers | `rounded-xl` | Icon wrapper divs |
| Avatars | `rounded-xl` | Not `rounded-full` unless circular by design |

---

## Form Elements

- [ ] **Labels**: Theme primary color, uppercase, `text-xs font-semibold mb-1.5 uppercase tracking-wide`
- [ ] **Input Height**: Consistent `h-10` for ALL inputs and selects
- [ ] **Input Padding**: `px-4` horizontal padding only
- [ ] **Input Background**: `colors.inputBg`
- [ ] **Input Border**: `1px solid ${colors.inputBorder}`
- [ ] **Input Text**: `text-sm` with `colors.textPrimary`
- [ ] **Focus States**: `focus:outline-none`

### Common Mistakes to Avoid
- ❌ Using `py-2.5` instead of `h-10` (causes inconsistent heights)
- ❌ Using gray color for labels instead of theme primary
- ❌ Using lowercase labels instead of uppercase
- ❌ Using `rounded-lg` instead of `rounded-xl`

---

## Buttons

- [ ] **Shape**: `rounded-full` (pill) - NEVER `rounded-lg` or `rounded-xl`
- [ ] **Height**: `py-2.5` for consistent height
- [ ] **Font**: `text-sm font-semibold text-white`
- [ ] **Background**: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`
- [ ] **Shadow**: `boxShadow: 0 4px 14px ${colors.glassShadow}`
- [ ] **Hover**: `hover:shadow-lg`
- [ ] **Transition**: `transition-all`

---

## Typography

### Font Scale
| Class | Size | Use Case |
|-------|------|----------|
| `text-xs` | 11px | Small captions, meta info |
| `text-sm` | 13px | Secondary content, subtitles |
| `text-base` | 15px | Primary body text (default) |
| `text-lg` | 17px | Large body, card titles |
| `text-xl` | 19px | Section headers (H3) |
| `text-2xl` | 21px | Page subtitles (H2) |
| `text-3xl` | 26px | Page titles (H1) |

### Hierarchy
| Element | Classes | Color |
|---------|---------|-------|
| Page Title | `text-2xl font-bold` | `colors.textPrimary` |
| Card Title | `text-base font-semibold` | `colors.textPrimary` |
| Large Stats | `text-lg font-bold` | `colors.primary` |
| Body Text | `text-base` | `colors.textSecondary` |
| Labels/Headers | `text-xs font-semibold uppercase tracking-wide` | `colors.primary` |
| Meta/Captions | `text-xs` | `colors.textTertiary` |

---

## Card Types

### 1. Glass Card (Main Containers)
Use for: Section containers, modal bodies, form containers.

```tsx
<div
  className="p-5 rounded-xl"
  style={{
    background: colors.cardBackground,
    border: `1px solid ${colors.cardBorder}`,
    boxShadow: `0 4px 24px ${colors.glassShadow}`
  }}
>
```

### 2. Gradient Border Card (Premium Cards)
Use for: Featured content, premium features, hero cards.

```tsx
<div className="p-[1px] rounded-2xl overflow-hidden" style={{
  background: `linear-gradient(135deg, ${colors.primary}40 0%, ${colors.secondary}30 50%, ${colors.accent}20 100%)`
}}>
  <div className="p-6 rounded-2xl" style={{
    background: colors.cardBackground,
    backdropFilter: 'blur(20px)'
  }}>
    {/* Content */}
  </div>
</div>
```

### 3. Duo-Tone Gradient Card (Hero Cards)
Use for: Main KPIs, hero metrics, featured stats.

```tsx
<div className="p-6 rounded-2xl relative overflow-hidden" style={{
  background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.secondary} 100%)`,
  boxShadow: `0 8px 32px ${isDark ? 'rgba(0,0,0,0.4)' : `${colors.primary}30`}`
}}>
  {/* Decorative circles */}
  <div className="absolute -top-6 -right-6 w-24 h-24 rounded-full" style={{ background: 'rgba(255,255,255,0.1)' }} />
  <div className="absolute -bottom-8 -left-8 w-32 h-32 rounded-full" style={{ background: 'rgba(255,255,255,0.05)' }} />
  <div className="relative z-10">
    <p className="text-3xl font-bold text-white">₹1,24,500</p>
  </div>
</div>
```

### 4. Secondary Accent Card
Use for: Supporting metrics, alternative highlights.

```tsx
<div className="p-6 rounded-2xl transition-all duration-300 hover:-translate-y-1 hover:shadow-xl" style={{
  background: `linear-gradient(145deg, ${colors.cardBackground} 0%, ${isDark ? colors.backgroundTertiary : colors.backgroundSecondary} 100%)`,
  border: `1px solid ${colors.cardBorder}`,
  boxShadow: `0 4px 20px ${colors.glassShadow}`
}}>
  <div className="w-10 h-10 rounded-xl flex items-center justify-center" style={{
    background: `linear-gradient(135deg, ${colors.secondary} 0%, ${colors.secondaryDark} 100%)`
  }}>
    <svg className="w-5 h-5 text-white" />
  </div>
  <span className="text-2xl font-bold" style={{ color: colors.secondary }}>+24.5%</span>
</div>
```

### 5. Stat Card with Color Variants
Use for: Dashboard statistics, metric grids.

```tsx
{/* Primary variant */}
<div className="p-4 rounded-xl" style={{
  background: `linear-gradient(135deg, ${colors.primary}08 0%, ${colors.primary}03 100%)`,
  border: `1px solid ${colors.cardBorder}`
}}>
  <div className="w-9 h-9 rounded-lg" style={{ background: `${colors.primary}12` }}>
    <svg style={{ color: colors.primary }} />
  </div>
  <p className="text-2xl font-bold">₹45.2K</p>
</div>

{/* Secondary variant */}
<div className="p-4 rounded-xl" style={{
  background: `linear-gradient(135deg, ${colors.secondary}08 0%, ${colors.secondary}03 100%)`,
  border: `1px solid ${isDark ? `${colors.secondary}20` : `${colors.secondary}15`}`
}}>
  {/* Same structure with colors.secondary */}
</div>

{/* Success variant */}
<div className="p-4 rounded-xl" style={{
  background: `linear-gradient(135deg, ${colors.success}08 0%, ${colors.success}03 100%)`,
  border: `1px solid ${isDark ? `${colors.success}20` : `${colors.success}15`}`
}}>
  {/* Same structure with colors.success */}
</div>
```

### 6. Tinted Card (Interactive Items)
Use for: Clickable cards, list items, activity items.

**Admin Portal:**
```tsx
<div
  className="p-3 rounded-2xl transition-all duration-200 hover:-translate-y-0.5"
  style={{
    background: isDark
      ? 'linear-gradient(135deg, rgba(147, 197, 253, 0.06) 0%, rgba(191, 219, 254, 0.03) 100%)'
      : 'linear-gradient(135deg, rgba(59, 130, 246, 0.03) 0%, rgba(96, 165, 250, 0.01) 100%)',
    border: `1px solid ${colors.cardBorder}`,
    boxShadow: `0 4px 20px ${colors.glassShadow}`
  }}
>
```

**FA Portal:**
```tsx
<div
  className="p-3 rounded-2xl transition-all duration-200 hover:-translate-y-0.5"
  style={{
    background: isDark
      ? 'linear-gradient(135deg, rgba(216, 180, 254, 0.06) 0%, rgba(249, 168, 212, 0.03) 100%)'
      : 'linear-gradient(135deg, rgba(168, 85, 247, 0.03) 0%, rgba(244, 114, 182, 0.01) 100%)',
    border: `1px solid ${colors.cardBorder}`,
    boxShadow: `0 4px 20px ${colors.glassShadow}`
  }}
>
```

### 7. Liquid Glass (Premium KPIs)
Use for: Dashboard KPI tiles, hero metrics.

**Admin Portal:**
```tsx
<div
  className="p-4 rounded-3xl"
  style={{
    background: isDark
      ? 'linear-gradient(135deg, rgba(147, 197, 253, 0.08) 0%, rgba(125, 211, 252, 0.04) 100%)'
      : 'linear-gradient(135deg, rgba(59, 130, 246, 0.05) 0%, rgba(56, 189, 248, 0.02) 100%)',
    backdropFilter: 'blur(24px)',
    border: `1px solid ${colors.cardBorder}`
  }}
>
```

**FA Portal:**
```tsx
<div
  className="p-4 rounded-3xl"
  style={{
    background: isDark
      ? 'linear-gradient(135deg, rgba(216, 180, 254, 0.08) 0%, rgba(249, 168, 212, 0.04) 100%)'
      : 'linear-gradient(135deg, rgba(168, 85, 247, 0.05) 0%, rgba(244, 114, 182, 0.02) 100%)',
    backdropFilter: 'blur(24px)',
    border: `1px solid ${colors.cardBorder}`
  }}
>
```

### 8. Card with Top Gradient Bar
Use for: Section cards, feature cards, utility panels.

```tsx
<div className="relative overflow-hidden rounded-2xl" style={{
  background: `linear-gradient(145deg, ${colors.cardBackground} 0%, ${isDark ? colors.backgroundTertiary : colors.backgroundSecondary} 100%)`,
  border: `1px solid ${colors.cardBorder}`,
  boxShadow: `0 4px 24px ${colors.glassShadow}`
}}>
  {/* Gradient top bar */}
  <div className="absolute top-0 left-0 w-full h-1" style={{
    background: `linear-gradient(90deg, ${colors.primary} 0%, ${colors.secondary} 100%)`
  }} />
  <div className="p-6">
    {/* Content */}
  </div>
</div>
```

---

## Information Tiles

### Hierarchy Levels

| Level | Description | Use Case |
|-------|-------------|----------|
| **Primary** | Duo-tone gradient (primary → secondary) | Hero metrics, main CTAs |
| **Secondary** | Card with gradient top bar accent | Supporting stats |
| **Tertiary** | Subtle glass with accent icon | Metadata, footnotes |

### Primary Tile (Duo-Tone Gradient)
```tsx
<div className="p-5 rounded-2xl relative overflow-hidden" style={{
  background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 50%, ${colors.secondary} 100%)`,
  boxShadow: `0 8px 32px ${isDark ? 'rgba(96, 165, 250, 0.25)' : `${colors.primary}25`}`
}}>
  {/* Decorative circle */}
  <div className="absolute top-0 right-0 w-20 h-20 rounded-full" style={{ background: 'rgba(255,255,255,0.1)', transform: 'translate(30%, -30%)' }} />
  <div className="relative z-10">
    <div className="flex items-center gap-2 mb-3">
      <div className="w-8 h-8 rounded-lg flex items-center justify-center" style={{ background: 'rgba(255,255,255,0.2)' }}>
        <svg className="w-4 h-4 text-white" />
      </div>
      <span className="text-xs font-semibold uppercase tracking-wider text-white/80">Primary</span>
    </div>
    <p className="text-3xl font-bold text-white mb-1">₹12.4 Cr</p>
    <p className="text-sm text-white/70">Hero metrics, main CTAs</p>
  </div>
</div>
```

### Secondary Tile (Side Border Accent)
```tsx
<div className="p-5 rounded-2xl" style={{
  background: `linear-gradient(145deg, ${colors.cardBackground} 0%, ${isDark ? colors.backgroundTertiary : colors.backgroundSecondary} 100%)`,
  border: `1px solid ${colors.cardBorder}`,
  borderLeft: `4px solid ${colors.secondary}`,  /* KEY: Use CSS borderLeft for side accent */
  boxShadow: `0 4px 20px ${colors.glassShadow}`
}}>
  <div className="flex items-center gap-2 mb-3">
    <div className="w-8 h-8 rounded-lg flex items-center justify-center" style={{ background: `${colors.secondary}15` }}>
      <svg className="w-4 h-4" style={{ color: colors.secondary }} />
    </div>
    <span className="text-xs font-semibold uppercase tracking-wider" style={{ color: colors.secondary }}>Secondary</span>
  </div>
  <p className="text-3xl font-bold mb-1" style={{ color: colors.textPrimary }}>₹8.2 Cr</p>
  <p className="text-sm" style={{ color: colors.textSecondary }}>Supporting stats, highlights</p>
</div>
```

### Tertiary Tile (Subtle Glass)
```tsx
<div className="p-5 rounded-2xl" style={{
  background: `linear-gradient(135deg, ${colors.chipBg} 0%, ${isDark ? colors.backgroundTertiary : colors.backgroundSecondary} 100%)`,
  border: `1px solid ${colors.cardBorder}`,
  boxShadow: isDark ? 'none' : '0 2px 12px rgba(0,0,0,0.04)'
}}>
  <div className="flex items-center gap-2 mb-3">
    <div className="w-8 h-8 rounded-lg flex items-center justify-center" style={{ background: `${colors.accent}12` }}>
      <svg className="w-4 h-4" style={{ color: colors.accent }} />
    </div>
    <span className="text-xs font-semibold uppercase tracking-wider" style={{ color: colors.textTertiary }}>Tertiary</span>
  </div>
  <p className="text-3xl font-bold mb-1" style={{ color: colors.textSecondary }}>₹3.1 Cr</p>
  <p className="text-sm" style={{ color: colors.textTertiary }}>Background info, metadata</p>
</div>
```

---

## Semantic Information Tiles

Use colored left border accents (`borderLeft` CSS property) to indicate semantic meaning.

### Semantic Tile Pattern (using CSS borderLeft)
```tsx
<div className="p-4 rounded-xl" style={{
  background: `linear-gradient(145deg, ${colors.cardBackground} 0%, ${isDark ? colors.backgroundTertiary : colors.backgroundSecondary} 100%)`,
  border: `1px solid ${isDark ? `${semanticColor}20` : `${semanticColor}15`}`,
  borderLeft: `4px solid ${semanticColor}`,  /* KEY: Use CSS borderLeft, not positioned div */
  boxShadow: isDark ? 'none' : '0 2px 12px rgba(0,0,0,0.04)'
}}>
  <div className="flex items-center gap-2 mb-3">
    <div className="w-8 h-8 rounded-lg flex items-center justify-center" style={{ background: `${semanticColor}12` }}>
      <svg className="w-4 h-4" style={{ color: semanticColor }} />
    </div>
    <span className="text-xs font-semibold uppercase" style={{ color: semanticColor }}>Label</span>
  </div>
  <p className="text-sm" style={{ color: colors.textSecondary }}>Description text</p>
</div>
```

### FA Portal Components
- **FAInfoTile**: Use for semantic info tiles with automatic variant colors
- **FATintedCard with accentColor**: Use for clickable cards with left accent

```tsx
// Using FAInfoTile (auto semantic colors)
<FAInfoTile variant="success" padding="md">
  <p>Success message</p>
</FAInfoTile>

// Using FATintedCard with accentColor
<FATintedCard accentColor={colors.primary} padding="md">
  <p>Card with left accent</p>
</FATintedCard>
```

### Semantic Colors
| Type | Color Variable | Use Case |
|------|---------------|----------|
| Info | `colors.primary` | Neutral information, tips, guidance |
| Success | `colors.success` | Positive outcomes, gains, completions |
| Warning | `colors.warning` | Cautions, pending actions, reviews |
| Error | `colors.error` | Alerts, losses, critical issues |

### Info Tile
Uses gradient left border: `linear-gradient(180deg, ${colors.primary} 0%, ${colors.accent} 100%)`

### Success Tile
Uses solid left border: `colors.success`

### Warning Tile
Uses solid left border: `colors.warning`

### Error Tile
Uses solid left border: `colors.error`

---

## Background Opacity Guide

Use subtle opacity values to prevent heavy/dark appearance:

| Visual Weight | Light Mode | Dark Mode | Use For |
|--------------|------------|-----------|---------|
| **Highest** | 0.05 | 0.08 | KPI tiles |
| **High** | 0.03 | 0.06 | Section containers |
| **Medium** | 0.02 | 0.04 | Cards, panels |
| **Low** | 0.01 | 0.03 | List items |
| **Subtle** | 0.005 | 0.02 | Hover states |

---

## Icons

- [ ] **NO EMOJIS** - Use SVG vector icons only
- [ ] **Size**: `w-5 h-5` (standard) or `w-4 h-4` (small)
- [ ] **Stroke**: `strokeWidth={1.5}` or `strokeWidth={2}`
- [ ] **Style**: `fill="none"` with `stroke="currentColor"`
- [ ] **Color**: Inherit via `currentColor` or use `colors.primary`

### Icon Container
```tsx
<div className="w-9 h-9 rounded-xl flex items-center justify-center" style={{ background: colors.chipBg }}>
  <svg className="w-5 h-5" style={{ color: colors.primary }} ...>
</div>
```

---

## Spacing

| Context | Value |
|---------|-------|
| Card Padding | `p-4` or `p-5` |
| List Item Padding | `p-3` |
| Section Gaps | `gap-3` or `space-y-3` |
| Label to Input | `mb-1.5` |
| Grid Gaps | `gap-3` |

---

## Progress Bars

- [ ] **Track**: `colors.progressBg`
- [ ] **Fill**: `linear-gradient(90deg, ${colors.primary} 0%, ${colors.secondary} 100%)`
- [ ] **Height**: `h-2`
- [ ] **Border Radius**: `rounded-full`

---

## Dark Mode Support

- [ ] All colors use theme color system (Admin or FA)
- [ ] Backgrounds use `isDark ? darkValue : lightValue` pattern
- [ ] Borders use theme-aware `colors.cardBorder`
- [ ] Shadows use theme-aware `colors.glassShadow`

---

## Theme Selection Guide

| Page/Feature | Theme |
|--------------|-------|
| Admin Dashboard | Admin (Blue/Cyan) |
| System Configuration | Admin (Blue/Cyan) |
| User Management | Admin (Blue/Cyan) |
| ML Models/Lab | Admin (Blue/Cyan) |
| FA Dashboard | FA (Purple/Pink) |
| Client Management | FA (Purple/Pink) |
| Portfolio Management | FA (Purple/Pink) |
| Investment Recommendations | FA (Purple/Pink) |

---

## Quick Reference Code Snippets

### useThemeColors Hook
```tsx
const useThemeColors = (theme: 'admin' | 'fa' = 'admin') => {
  const isDark = useDarkMode();
  if (theme === 'fa') {
    return isDark ? FA_COLORS_DARK : FA_COLORS_LIGHT;
  }
  return isDark ? ADMIN_COLORS_DARK : ADMIN_COLORS_LIGHT;
};
```

### Form Label
```tsx
<label className="block text-xs font-semibold mb-1.5 uppercase tracking-wide" style={{ color: colors.primary }}>
  FIELD NAME
</label>
```

### Input Field
```tsx
<input
  className="w-full h-10 px-4 rounded-xl text-sm transition-all focus:outline-none"
  style={{ background: colors.inputBg, border: `1px solid ${colors.inputBorder}`, color: colors.textPrimary }}
/>
```

### Primary Button
```tsx
<button
  className="w-full py-2.5 rounded-full font-semibold text-sm text-white transition-all hover:shadow-lg"
  style={{ background: `linear-gradient(135deg, ${colors.primary} 0%, ${colors.primaryDark} 100%)`, boxShadow: `0 4px 14px ${colors.glassShadow}` }}
>
  Button Text
</button>
```

### Section Header
```tsx
<span className="text-xs font-semibold uppercase tracking-wide" style={{ color: colors.primary }}>
  SECTION TITLE
</span>
```

### Chip/Tag
```tsx
<span
  className="text-xs px-2 py-0.5 rounded"
  style={{ background: colors.chipBg, color: colors.primary, border: `1px solid ${colors.chipBorder}` }}
>
  Tag
</span>
```

---

## Validation Checklist

### Before Committing
- [ ] Correct theme used (Admin or FA)
- [ ] Font is Plus Jakarta Sans throughout
- [ ] Colors from theme constants (not hardcoded)
- [ ] Buttons use `rounded-full` pill shape
- [ ] Labels are uppercase with theme primary color
- [ ] Inputs have consistent `h-10` height
- [ ] Cards use correct radius (`rounded-xl`, `rounded-2xl`, or `rounded-3xl`)
- [ ] Dark mode tested and working
- [ ] Opacity values are subtle (not heavy/dark)
- [ ] No emojis used (SVG icons only)
