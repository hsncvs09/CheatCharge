---
name: Cheat & Charge Claymorphism
colors:
  surface: '#fdf9f3'
  surface-dim: '#ddd9d4'
  surface-bright: '#fdf9f3'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f7f3ed'
  surface-container: '#f1ede7'
  surface-container-high: '#ebe8e2'
  surface-container-highest: '#e6e2dc'
  on-surface: '#1c1c18'
  on-surface-variant: '#58423c'
  inverse-surface: '#31302d'
  inverse-on-surface: '#f4f0ea'
  outline: '#8b716b'
  outline-variant: '#dfc0b8'
  surface-tint: '#a7391e'
  primary: '#a7391e'
  on-primary: '#ffffff'
  primary-container: '#ff7a59'
  on-primary-container: '#701500'
  inverse-primary: '#ffb4a2'
  secondary: '#006a65'
  on-secondary: '#ffffff'
  secondary-container: '#79f3ea'
  on-secondary-container: '#006f69'
  tertiary: '#785a00'
  on-tertiary: '#ffffff'
  tertiary-container: '#c59c36'
  on-tertiary-container: '#493500'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdad2'
  primary-fixed-dim: '#ffb4a2'
  on-primary-fixed: '#3c0700'
  on-primary-fixed-variant: '#862208'
  secondary-fixed: '#7cf6ec'
  secondary-fixed-dim: '#5dd9d0'
  on-secondary-fixed: '#00201e'
  on-secondary-fixed-variant: '#00504c'
  tertiary-fixed: '#ffdf9b'
  tertiary-fixed-dim: '#edc157'
  on-tertiary-fixed: '#251a00'
  on-tertiary-fixed-variant: '#5b4300'
  background: '#fdf9f3'
  on-background: '#1c1c18'
  surface-variant: '#e6e2dc'
typography:
  display-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '800'
    lineHeight: 56px
  display-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 36px
    fontWeight: '800'
    lineHeight: 44px
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '700'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 34px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '700'
    lineHeight: 32px
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 28px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-lg:
    fontFamily: Space Grotesk
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
  label-md:
    fontFamily: Space Grotesk
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 18px
  label-sm:
    fontFamily: Space Grotesk
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 16px
rounded:
  sm: 0.5rem
  DEFAULT: 1rem
  md: 1.5rem
  lg: 2rem
  xl: 3rem
  full: 9999px
spacing:
  gutter: 1.25rem
  margin: 1.5rem
  space-xs: 0.5rem
  space-sm: 0.75rem
  space-md: 1.25rem
  space-lg: 1.75rem
  space-xl: 2.5rem
---

## Brand & Style
This design system crafts a tangible, tactile, and lighthearted digital companion for balanced living. Designed around the push-and-pull dynamic of "Cheat & Charge" (indulgence paired with physical recharge), the aesthetic moves completely away from austere athletic performance dashboards. Instead, it invites physical touch through friendly, inflated claymorphic surfaces.

The visual style is **Claymorphism combined with Tactile/Skeuomorphic depth**:
- Surfaces appear thick, matte, pillowy, and softly extruded.
- The UI rejects glossy skeuomorphism in favor of powdery, vinyl-like, tactile surfaces reminiscent of sculpted polymer clay.
- Interactions produce an impression of volume and elasticity rather than mechanical digital toggles.
- The tone is forgiving, encouraging, celebratory, and intentionally anti-guilt.

## Colors
The palette balances appetizing warmth with revitalizing energy across a warm, creamy canvas:
- **Primary (`#FF7A59` - Persimmon Clay):** Used for "Cheat" rewards, streak surges, primary actions, and key progress metrics.
- **Secondary (`#4ECDC4` - Mint Clay):** Represents "Charge", active recovery, calorie burn, replenishment, and positive reinforcement.
- **Tertiary (`#FFD166` - Banana Puff):** Highlights streaks, micro-celebrations, tactile pill notifications, and secondary badges.
- **Neutral Base (`#F4F0EA` - Soft Alabaster Dough):** The foundational matte surface canvas. Never use pure `#FFFFFF` as a background; tinted warm light allows outer white clay highlights to read distinctly.

### Functional Tint & Shadow Logic
- **Highlight Inset Tint:** Pure white (`#FFFFFF`) with 60%–80% opacity applied strictly from the top-left angle (`-45°` / `315°`).
- **Lowlight Inset Tint:** A saturated, darkened version of the parent surface color (e.g., `#D95B3D` for Primary, `#329D95` for Secondary, `#D8CEBE` for Neutral surfaces) applied at 35%–55% opacity from the bottom-right angle (`135°`).
- **Text & Glyphs:** Deep Umber Charcoal (`#2D2825`) to preserve warm organic contrast, avoiding harsh digital pitch black.

## Typography
Typography reinforces the inflated, approachable character of the system:
- **Display and Body Font:** `Plus Jakarta Sans` provides soft, rounded apertures, humanist warmth, and clean legibility across chunky button scales and metric readings.
- **Label & Data Font:** `Space Grotesk` injects a subtle geometric, structured precision into metric trackers, nutritional counts, charge percentages, and status chips, contrasting pleasantly against the organic shapes.
- All headline weights range between `Bold (700)` and `ExtraBold (800)` to hold visual weight alongside the dimensional, cast-shadow surfaces.

## Layout & Spacing
Because claymorphic elements feature dual inner highlights, deep corner radii, and ambient drop shadows, they occupy larger perceptual volume. Layout structures require generous breathing room to prevent visual density and shadow clipping:
- **Grid Structure:** A fluid 4-column layout on mobile, expanding to 8 columns on tablet and 12 columns on desktop web layouts.
- **Card Margins & Padding:** Cards and interactive containers utilize generous inner padding (`space-lg` / `1.75rem`) to ensure typography and icons sit comfortably away from the extruded inner bevel zones.
- **Stacking Spacing:** Vertical stacks enforce a minimum gap of `space-md` (`1.25rem`) to ensure bottom-projected floating ambient shadows do not bleed into neighboring header titles.

## Elevation & Depth
Claymorphism avoids flat 2D surfaces and translucent glass blurs. Depth is achieved via an inflated 3-point lighting formula applied to every elevated container:

### 1. Dual Inset Lighting (The "Clay Bead" Formula)
Every elevated clay element carries two composite inner shadows:
- **Top-Left Highlight Inset:** `inset -6px -6px 12px rgba(255, 255, 255, 0.75)` to simulate overhead key light striking rounded polymer rims.
- **Bottom-Right Lowlight Inset:** `inset 6px 6px 14px [Parent-Saturated-Dark-Color]` at 25%–40% opacity, generating an organic, volumetric under-roll.

### 2. Ambient Floating Drop Shadows
Surfaces rest above the canvas using soft, colored ambient shadows:
- **Resting Elevation:** `0 16px 32px -8px rgba(184, 172, 156, 0.35), 0 8px 16px -4px rgba(184, 172, 156, 0.2)`
- **Hover/Floating State:** `0 24px 44px -8px rgba(184, 172, 156, 0.45), 0 12px 20px -6px rgba(184, 172, 156, 0.25)`
- **Pressed/Sunken State (Debossed):** Reverses outer depth into internal indentation: `inset 4px 4px 8px rgba(0, 0, 0, 0.15), inset -3px -3px 6px rgba(255, 255, 255, 0.8)`, accompanied by zero external drop shadow.

Never apply 1px solid stroke borders; physical clay transitions rely entirely on lighting gradients and soft inner contours.

## Shapes
Shapes must feel soft, chunky, molded, and hand-formed:
- Standard surface cards and interactive modules require corner radii between `28px` and `36px` (`rounded-3xl`).
- Buttons, chips, progress capsules, and pill badges adhere to complete capsule rounding (`rounded-full` / `9999px`).
- Sharp geometric edges (0px to 8px) are strictly prohibited; acute corners break the inflated clay illusion.

## Components

### Buttons
- **Primary & Action Buttons:** Rendered as full pills (`rounded-full`) in primary persimmon or secondary mint. Elevated with top-left white inset highlights and bottom-right shaded lowlights.
- **Tactile Depress Interaction:** On `:active`, remove the outer shadow, translate the element `2px` downward (`transform: translateY(2px)`), and switch inner shadows to inverted debossed values, simulating a tactile squish.

### Cards & Modules
- **Metric Cards:** Built with neutral background clay (`#FFFFFF` or warm ivory `#F9F6F0`), 32px rounded corners, dual inner clay shadows, and deep ambient drop shadows.
- Cards contain dedicated sculpted pockets: inset data modules where secondary stats sit sunken into the parent container.

### Chips & Pill Badges
- **Status Pills:** Compact capsules using tertiary banana puff (`#FFD166`) or secondary mint (`#4ECDC4`).
- Inner shadows are calibrated finer (`inset -2px -2px 4px rgba(255,255,255,0.8)` and `inset 2px 2px 5px rgba(0,0,0,0.08)`) with `label-sm` or `label-md` typography in `Space Grotesk`.

### Inputs & Sliders
- **Text Inputs:** Styled as inverted/sunken clay reservoirs rather than floating blocks. Background uses a slightly darker tone than the canvas with negative inset shadows creating an indented well.
- **Thumb Controls & Toggles:** Sculpted floating spheres that slide across carved-out track wells, offering high physical contrast.

### Checkboxes & Segmented Controls
- **Toggle Segments:** Carved background tracks housing a floating pill selector that glides into position with an elastic cubic-bezier easing curve (`cubic-bezier(0.34, 1.56, 0.64, 1)`).
- **Checkboxes:** Chunky 24px squircle pads (`10px` radius) that visually pop upward when unselected and press debossed into the canvas with a vivid colored checkmark when active.

### Cheat vs. Charge Balance Meter
- A customized signature dual-gauge component: a pill-shaped inflated container showing dynamic balance between indulgence points (Cheat) and exertion recovery (Charge), featuring continuous squishy physics on thumb release.