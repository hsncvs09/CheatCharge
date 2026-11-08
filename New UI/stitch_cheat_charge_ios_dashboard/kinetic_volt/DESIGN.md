---
name: Kinetic Volt
colors:
  surface: '#131313'
  surface-dim: '#131313'
  surface-bright: '#393939'
  surface-container-lowest: '#0e0e0e'
  surface-container-low: '#1c1b1b'
  surface-container: '#201f1f'
  surface-container-high: '#2a2a2a'
  surface-container-highest: '#353534'
  on-surface: '#e5e2e1'
  on-surface-variant: '#c4c9ac'
  inverse-surface: '#e5e2e1'
  inverse-on-surface: '#313030'
  outline: '#8e9379'
  outline-variant: '#444933'
  surface-tint: '#abd600'
  primary: '#ffffff'
  on-primary: '#283500'
  primary-container: '#c3f400'
  on-primary-container: '#556d00'
  inverse-primary: '#506600'
  secondary: '#ffb2b8'
  on-secondary: '#67001e'
  secondary-container: '#ac0037'
  on-secondary-container: '#ffb7bc'
  tertiary: '#ffffff'
  on-tertiary: '#373100'
  tertiary-container: '#fde400'
  on-tertiary-container: '#716500'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#c3f400'
  primary-fixed-dim: '#abd600'
  on-primary-fixed: '#161e00'
  on-primary-fixed-variant: '#3c4d00'
  secondary-fixed: '#ffdadb'
  secondary-fixed-dim: '#ffb2b8'
  on-secondary-fixed: '#40000f'
  on-secondary-fixed-variant: '#91002d'
  tertiary-fixed: '#fde400'
  tertiary-fixed-dim: '#dec800'
  on-tertiary-fixed: '#201c00'
  on-tertiary-fixed-variant: '#504700'
  background: '#131313'
  on-background: '#e5e2e1'
  surface-variant: '#353534'
typography:
  display-lg:
    fontFamily: Space Grotesk
    fontSize: 56px
    fontWeight: '700'
    lineHeight: 60px
    letterSpacing: -0.04em
  display-lg-mobile:
    fontFamily: Space Grotesk
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Space Grotesk
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.03em
  headline-lg-mobile:
    fontFamily: Space Grotesk
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Space Grotesk
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.02em
  headline-sm:
    fontFamily: Space Grotesk
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Space Grotesk
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 26px
  body-md:
    fontFamily: Space Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Space Grotesk
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Space Grotesk
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 18px
    letterSpacing: 0.06em
  label-md:
    fontFamily: Space Grotesk
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.08em
  label-sm:
    fontFamily: Space Grotesk
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.1em
spacing:
  gutter: 1rem
  gutter-desktop: 1.5rem
  margin: 1rem
  margin-desktop: 2.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2.5rem
---

## Brand & Style

This design system delivers a high-voltage, aggressive fitness aesthetic rooted in Dark Neobrutalism. Built for athletes and hyper-focused individuals tracking PRs, intervals, and functional conditioning, the visual direction replaces clinical health tracking with raw athletic momentum and digital subculture energy.

### Core Tenets
- **High-Velocity Contrast:** Deep charcoal and true black backdrops supercharged by piercing neon accents.
- **Physical Tactility:** Solid, unblurred offset hard drop shadows, thick structural borders, and modular panel construction that evoke vintage digital timers and industrial gym gear.
- **Micro-Aggressive Details:** High-energy badge stickers, data-dense ticker strips, and dot-grid textures that frame metrics like a digital heads-up display.

## Colors

The palette relies on absolute darkness paired with hyper-saturated warning signals.

### Application Rules
- **Canvas & Backgrounds:** The base app background uses `#09090b` overlaid with a subtle dark dot grid (`radial-gradient(#27272a 1px, transparent 0)` spaced at 16px). Surface panels leverage `#121212` and `#18181b`.
- **Primary (`#ccff00` - Cyber Acid Lime):** Main call-to-actions, primary rep counters, completion states, active toggles.
- **Secondary (`#ff4d6d` - Coral Pink):** Strain levels, maximum heart rate thresholds, warnings, destructive PR resets.
- **Tertiary (`#ffe600` - Electric Neon Yellow):** Rest timers, streak badges, secondary callouts.
- **Borders & Dividers:** High-contrast structural division using crisp pure white (`#ffffff`) for interior card containers on dark surfaces, or pure pitch black (`#000000`) when resting directly against vibrant neon containers.
- **Text:** High-contrast `#ffffff` for titles, `#e4e4e7` for readable body copy, and `#a1a1aa` for muted metadata. Inverted pitch black `#000000` text is mandatory whenever placed on neon-filled elements.

## Typography

The type system is unapologetically brutal, geometric, and high-impact. Space Grotesk drives every level from display numbers to tracking labels, delivering a mechanical, technical feel.

### Usage
- **Case Formatting:** All `label-*` and utility badges must use strict uppercase styling (`text-transform: uppercase`) paired with wide tracking.
- **Metric Readouts:** Large numerical readouts for timers, load weight, and sets use `display-lg` with tight tracking (`-0.04em`) to establish visual dominance.
- **Monospace Accent:** For milliseconds, raw intervals, and split-lap timestamps, tabular lining figures (`font-variant-numeric: tabular-nums`) must be enforced.

## Layout & Spacing

Layouts follow a structured, rigid box-model grid prioritizing high density and immediate visual scannability during workouts.

### Grid & Breakpoints
- **Mobile (< 768px):** 4-column fluid layout, `margin: 1rem` (16px), `gutter: 1rem` (16px).
- **Tablet (768px - 1024px):** 8-column layout, `margin: 1.5rem` (24px), `gutter: 1.25rem` (20px).
- **Desktop (> 1024px):** 12-column layout, max-width container 1280px centered, `margin-desktop: 2.5rem` (40px), `gutter-desktop: 1.5rem` (24px).

### Spacing Philosophy
Spacing avoids soft airy margins in favor of defined modular blocks. Cards and sections nest within concrete rectangular zones separated by visible borders or hard spacing increments. Use compact internal padding (`space-md` or `space-lg`) to maximize usable screen real estate.

## Elevation & Depth

This system avoids Gaussian blurs, soft glows, and diffuse drop shadows. Elevation is achieved exclusively through **Hard Offset Drop Shadows** and **Border Weight Hierarchy**.

### Hard Shadow Levels
- **Level 1 (Subtle / Interactive Base):** `2px 2px 0px #000000` on surfaces layered over lighter containers, or `2px 2px 0px #ffffff` on dark cards.
- **Level 2 (Cards & Modules):** `4px 4px 0px #000000` (for neon-filled surfaces) or `4px 4px 0px #ccff00` (for dark surface panels).
- **Level 3 (Modals & Primary CTAs):** `6px 6px 0px #000000` or `6px 6px 0px #ccff00`.

### Physical Interaction
- **Hover/Focus State:** The hard offset translates outward: `box-shadow: 6px 6px 0px #ccff00; transform: translate(-2px, -2px);`.
- **Active / Pressed State:** The hard offset collapses fully: `box-shadow: 0px 0px 0px #000000; transform: translate(4px, 4px);`. This mimics a heavy physical arcade or power switch.

## Shapes

The geometric identity is completely unrounded (`roundedness: 0`, 0px border radius). Everything—buttons, inputs, cards, notification banners, floating pills—retains razor-sharp 90-degree corners.

### Construction Details
- **Border Thickness:** Base elements feature `2px solid #ffffff` or `2px solid #000000`. Heavy display cards or active PR highlight containers use `3px solid #ccff00`.
- **Angled Notches & Tags:** Certain badge chips and stickers feature diagonal chamfered corners (clip-path 45° cuts of 8px) to reinforce an industrial machinery look.

## Components

### Buttons
- **Primary CTA:** Background `#ccff00`, text `#000000`, 2px solid `#000000`, box-shadow `4px 4px 0px #ffffff`. Label is uppercase `label-lg`.
- **Secondary Action:** Background `#18181b`, text `#ffffff`, 2px solid `#ffffff`, box-shadow `4px 4px 0px #ccff00`.
- **Danger / Kill Button:** Background `#ff4d6d`, text `#000000`, 2px solid `#000000`, box-shadow `4px 4px 0px #ffffff`.

### Cards & Panels
- **Workout Card:** Background `#121212`, 2px solid `#ffffff`, box-shadow `4px 4px 0px #000000`. Includes a top header ribbon with an inverted black-on-lime label tag.
- **Live Metric Block:** Background `#18181b`, 2px solid `#3f3f46`. Active state shifts border to `2px solid #ccff00` with a `4px 4px 0px #ccff00` offset.

### Input Fields
- Dark `#09090b` field with `2px solid #27272a`, text `#ffffff`.
- Focus state: `2px solid #ccff00` with `3px 3px 0px #ccff00`. Placeholder text `#52525b`.

### Chips & Stickers
- **Status Badges:** Thick-bordered, micro-sized rectangular tags. Example: `SET 1 / 4` sticker with `#ffe600` background, `#000000` text, and a slight -2° tilt (`transform: rotate(-2deg)`).
- **PR Badges:** Hot coral `#ff4d6d` background with white uppercase monospace text, offset shadow `2px 2px 0px #000000`.

### Checkboxes & Segmented Controls
- **Checkboxes:** 20x20px square, 2px solid `#ffffff`, no radius. Checked state fills with `#ccff00`, showing a solid pitch black checkmark with a `2px 2px 0px #000000` offset.
- **Segmented Unit Toggles (KG/LB):** Connected horizontal blocks separated by 2px vertical rules; active segment highlights in `#ccff00` with `#000000` bold text.