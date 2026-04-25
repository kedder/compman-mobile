---
name: Skybound Utility
colors:
  surface: '#f9f9ff'
  surface-dim: '#cfdaf2'
  surface-bright: '#f9f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f0f3ff'
  surface-container: '#e7eeff'
  surface-container-high: '#dee8ff'
  surface-container-highest: '#d8e3fb'
  on-surface: '#111c2d'
  on-surface-variant: '#40484e'
  inverse-surface: '#263143'
  inverse-on-surface: '#ecf1ff'
  outline: '#70787f'
  outline-variant: '#c0c7cf'
  surface-tint: '#006590'
  primary: '#004c6e'
  on-primary: '#ffffff'
  primary-container: '#006591'
  on-primary-container: '#b5deff'
  inverse-primary: '#89ceff'
  secondary: '#505f76'
  on-secondary: '#ffffff'
  secondary-container: '#d4e3ff'
  on-secondary-container: '#56657c'
  tertiary: '#444749'
  on-tertiary: '#ffffff'
  tertiary-container: '#5c5f61'
  on-tertiary-container: '#d7d9db'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#c8e6ff'
  primary-fixed-dim: '#89ceff'
  on-primary-fixed: '#001e2f'
  on-primary-fixed-variant: '#004c6e'
  secondary-fixed: '#d4e3ff'
  secondary-fixed-dim: '#b8c7e2'
  on-secondary-fixed: '#0c1c30'
  on-secondary-fixed-variant: '#39485e'
  tertiary-fixed: '#e1e3e5'
  tertiary-fixed-dim: '#c4c7c9'
  on-tertiary-fixed: '#191c1e'
  on-tertiary-fixed-variant: '#444749'
  background: '#f9f9ff'
  on-background: '#111c2d'
  surface-variant: '#d8e3fb'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 30px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-caps:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.05em
  status-badge:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '800'
    lineHeight: 12px
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base-unit: 4px
  stack-sm: 8px
  stack-md: 12px
  stack-lg: 20px
  gutter: 12px
  margin-mobile: 16px
---

## Brand & Style
The brand personality is **utilitarian, precise, and dependable**, designed for outdoor and high-stakes technical environments like competitive gliding. The visual language leans into a **Modern Corporate** aesthetic with a strong emphasis on information density and hierarchy.

The UI prioritizes clarity over ornamentation, using a systematic approach to colors and spacing to ensure critical flight data and task updates are instantly scannable. The emotional response is one of trust and systematic organization, achieved through a clean, light-filled interface with subtle tonal shifts to indicate depth.

## Colors
The palette is dominated by a range of **functional blues and cool greys**.
- **Primary Blue (#006591)** is used for actionable elements, branding, and emphasis on key data points (like distances).
- **Surface Tiers** use a subtle "cool-white" scale (ranging from `#ffffff` to `#f0f3ff`) to create soft separation between content modules without relying on heavy borders.
- **Semantic Colors** are used with high intentionality: a deep red for critical updates and the primary blue for "Active" status badges.
- **Text** follows a strict hierarchy using `#111c2d` for headlines and `#3e4850` for secondary metadata to maintain high legibility in daylight conditions.

## Typography
The system uses **Inter** exclusively to lean into its utilitarian and highly readable characteristics.
- **Hierarchy through Weight:** High-contrast weights (400 vs 700) are used instead of massive scale shifts to maintain density.
- **Technical Labels:** Small, uppercase labels with increased letter-spacing are used for section headers to provide a "dashboard" feel.
- **Data Readability:** Secondary metadata (like file sizes and timestamps) is reduced to 11px-12px to keep the focus on the primary object names.

## Layout & Spacing
The layout uses a **Fixed Width (Max-width: 2xl)** centered model for mobile-first delivery.
- **Vertical Rhythm:** A "Stack" system is used where 12px (`stack-md`) is the standard gap between cards, and 4px (`base-unit`) is used for internal tight-coupling of labels and values.
- **Margins:** A consistent 16px lateral margin ensures content doesn't hit the screen edges on mobile devices.
- **Enclosure:** Content is grouped into cards that use internal padding of 12px to 16px to maintain a compact but breathable information density.

## Elevation & Depth
The system uses **Tonal Layers** supplemented by low-intensity shadows.
- **Level 0 (Background):** `#f9f9ff` (The lowest base).
- **Level 1 (Cards):** `#ffffff` with a subtle `shadow-sm` and a 1px border of `#bec8d2`. This creates clear boundaries for primary data modules.
- **Level 2 (In-card containers):** Nested sections within cards use `#f0f3ff` (Surface Container Low) to differentiate actions (like "Install" footers) from information headers.
- **Flat Header:** The App Bar is pinned with a simple border-bottom, avoiding shadow to remain integrated with the background.

## Shapes
The shape language is **Soft but disciplined**.
- **Standard Radius:** 0.25rem (`4px`) for small elements like status badges.
- **Container Radius:** 0.75rem (`12px`) for main content cards to provide a modern, approachable feel.
- **Interactive Radius:** Buttons and selection inputs use a 0.5rem (`8px`) radius to feel distinct from the sharp technical data.
- **Full Radius:** Reserved exclusively for icon-button backgrounds and circular avatars to denote "tool" functionality.

## Components
- **Buttons:**
  - *Primary:* Solid `#006591` with white text, 48px height for main actions.
  - *Secondary/Ghost:* White background with a `#006591/30` border and 11px Bold All-Caps text for utility actions.
- **Cards:** Two-part construction with a white header (metadata/title) and a tinted footer (actions/secondary history). Divided by a 1px `#e7eeff` separator.
- **Status Badges:** Small (10px font), heavy weight (800), high-contrast background with 2px padding. The "New Update" variant uses a soft ring-glow effect.
- **Selection Inputs:** Full-width containers with a "Change" action on the right, using `#f0f3ff` background to denote it's a configurable setting.
- **Icons:** Material Symbols Outlined, typically 20px for main section icons and 16px for inline metadata.