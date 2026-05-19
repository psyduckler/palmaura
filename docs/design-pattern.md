# PalmAura · Design Pattern & Style Guide

> **Canonical reference for every screen, component, and copy moment in
> PalmAura.** When you author a new view, pull it through this doc first.
> When you review a PR, compare against this doc. If a screen breaks one of
> these rules, the rule wins by default — open an issue if you think a rule
> should change.
>
> The design system itself lives in [`ios/PalmAura/PalmAura/DesignSystem.swift`](../ios/PalmAura/PalmAura/DesignSystem.swift).
> This document is the *contract* the design system implements.

---

## 0. The brand stance, in one paragraph

PalmAura is a **vintage palmistry plate brought to life on a phone.** Not a
slick wellness app. Not a Co-Star clone. Not a fortune-telling carnival. The
visual register is a **night sky** with **brass engraving** and **parchment
keepsakes** — and the typographic register is *Cormorant Garamond for awe,
EB Garamond for thinking aloud, Cinzel for ceremony, Caveat for warmth.*
Every screen should feel like an instrument you'd find in a 19th-century
bookshop, scanned and reprinted with care.

If a design choice doesn't pull toward that posture, the choice is wrong.

---

## 1. The canonical screen skeleton

Every full-screen view in PalmAura follows this skeleton:

```swift
struct SomeView: View {
    // existing state…

    var body: some View {
        ZStack {
            DarkScreenBackground()                  // ① night sky + starfield
            VStack(spacing: 0) {
                ScreenHeader(eyebrow: "Section",    // ② moon dial top-right
                             back: true)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 22) {
                        // body content…
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, 30)
                }

                Spacer(minLength: 16)
                GoldButton(title: "Primary CTA  ›") { … }   // ③ primary action
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.bottom, 30)
            }
        }
        .navigationBarBackButtonHidden(true)              // ScreenHeader owns ‹
    }
}
```

Three structural rules:

- **① Background is always `DarkScreenBackground()`** — never `MysticalBackground` (removed), never `Color.black`, never a custom gradient. The starfield + indigo/mulberry warm hotspots are part of the brand.
- **② Top chrome is always `ScreenHeader`** — never the system `.navigationTitle`. The header carries the moon-phase dial (right) and a brass-circled back chevron (left). `navigationBarBackButtonHidden(true)` everywhere because of this.
- **③ Primary action is `GoldButton`** — never `.buttonStyle(.borderedProminent)`, never `LinearGradient([.yellow, .orange])`. There is exactly one GoldButton per screen. Secondary actions are `GhostButton`.

The handful of legitimate exceptions:

- **`AppOpeningView`** — no header (it *is* the chrome).
- **`PalmMapView` interior** — uses an overlaid bottom sheet rather than a footer button; the GoldButton lives inside the sheet.
- **`DisclaimerView`** — `back: false`, `moon: false` on the header (no back stack to return to).
- **`ShareOptionsSheet`** — modal sheet style; header has no back, sheet has a drag handle on top.

---

## 2. Design tokens

All values live in `DesignSystem.swift`. **Never hardcode a color, font name,
size, radius, shadow, or animation duration in a view.** If you need a value
that isn't in the design system, add it there first, then consume it.

### 2.1 Color palette

| Layer | Token | Use |
|-------|-------|-----|
| **Night sky** | `skyDeep` `#0B0820` | base background, top of gradient |
| | `skyWarm` `#15102F` | bottom of background gradient |
| | `skyIndigo` `#2A2055` | warm hotspot, top-left |
| | `skyMulberry` `#4A1F4A` | warm hotspot, bottom-right |
| **Gold-cream (emphasis)** | `goldCream` `#F3DDA8` | primary accent, primary button fill, glyphs |
| | `goldCreamSoft` `#FFF6D8` | brightest highlight, star cores |
| | `gold` `#A07A3A` | parchment-card accent, share-card border |
| | `goldDeep` `#7C5A22` | engraving ink on parchment |
| **Parchment (light surfaces)** | `parchmentLight` `#F1E7CF` | share card, photo cards |
| | `parchment` `#E8DBB9` | mid tone |
| | `parchmentDeep` `#D9C89C` | aged parchment |
| | `ink` `#2A1F15` | type on parchment |
| | `inkSoft` `#4A3826` | secondary type on parchment |
| **Text on dark** | `textPrimary` | `goldCreamSoft @ 92%` |
| | `textSecondary` | `goldCreamSoft @ 72%` |
| | `textTertiary` | `goldCreamSoft @ 55%` |
| **Borders** | `borderSoft` | `goldCream @ 35%` |
| | `surfaceSoft` | `goldCream @ 6%` |

**Banned in views (forever):** `Color.yellow`, `Color.purple`, `Color.orange`,
`Color.red`, `Color.pink`, system `.indigo`. If you find one in a PR, it's a
bug. The only place raw `Color.black` is acceptable is inside the share-card
exporter (where shadow renders against the iOS share sheet).

**Aura colors (per-reading accent):** PalmAura has six `AuraColor` cases —
`violet`, `gold`, `fire`, `moon`, `water`, `rose`. Each gets a *tint* via
`PalmCanvasView` and the share card halo. They are accents on top of the
night-sky / parchment palette — never used as the dominant surface.

### 2.2 Typography

Four families, all bundled in `Resources/Fonts/` (OFL):

| Family | PostScript reference | Use |
|--------|----------------------|-----|
| **Cormorant Garamond** | `CormorantGaramond-Medium`, `CormorantGaramond-MediumItalic` | Display headlines, italic emotional emphasis |
| **EB Garamond** | `EBGaramond-Regular`, `EBGaramond-Italic` | Body copy, long-form reading content |
| **Cinzel** | `Cinzel-Regular` (loaded + `.weight(.semibold)` → 600 via variable axis) | All-caps eyebrows, button labels, ornament tags |
| **Caveat** | `Caveat-Regular` | Reserved for handwritten marginalia (currently unused — keep available) |

**Type scale tokens** (always via `DesignSystem.FontToken.*`):

| Token | Size | Family | Use |
|-------|------|--------|-----|
| `display(54)` | 54 | Cormorant Garamond Medium | Home hero, "What answer / are you seeking?" |
| `display(44)` | 44 | Cormorant Garamond Medium | Other large headlines |
| `display(38)` | 38 | Cormorant Garamond Medium | DisclaimerView title |
| `display(34)` | 34 | Cormorant Garamond Medium | Onboarding section setup |
| `display(28)` | 28 | Cormorant Garamond Medium | Card titles in panels |
| `display(22)` | 22 | Cormorant Garamond Medium | Inline emphasis |
| `display(18)` | 18 | Cormorant Garamond Medium | Bullet titles |
| `body(20, italic: true)` | 20 italic | Cormorant Garamond Medium Italic | Tagline / quote |
| `body(15, italic: true)` | 15 italic | Cormorant Garamond MediumItalic | Subtitle copy |
| `body(14)` | 14 | EB Garamond Regular | Body paragraphs |
| `body(13)` | 13 | EB Garamond Regular | Caption-adjacent body |
| `caps(11)` | 11 | Cinzel @ semibold | Primary button label |
| `caps(10)` | 10 | Cinzel @ semibold | Eyebrow / section header |
| `caps(9)` | 9 | Cinzel @ semibold | Smaller eyebrow / nav row |
| `caps(8)` | 8 | Cinzel @ semibold | Footer disclaimer |

**Tracking** (always via `DesignSystem.Tracking.*`):

- Eyebrows / caps headers: `DesignSystem.Tracking.caps` (= 3.5)
- Button labels: `DesignSystem.Tracking.capsLg` (= 5) — manually `tracking(4)` is fine for smaller variants
- Body text: no tracking (use default)

### 2.3 Spacing (8-pt grid)

| Token | Pixels | Use |
|-------|--------|-----|
| `xxs` | 4 | inline padding in chips |
| `xs` | 8 | gap between cards |
| `sm` | 12 | gap inside button content |
| `md` | 16 | card internal padding |
| `lg` | 24 | **standard screen horizontal margin** |
| `xl` | 32 | top of major section breaks |
| `xxl` | 48 | rare — welcome hero |

**Screen padding is always `Spacing.lg` (24)** unless the screen is the share
card (40) or onboarding (22).

### 2.4 Radii

| Token | Pixels | Use |
|-------|--------|-----|
| `pill` | 999 | buttons, chips, mount circles |
| `cardLg` | 22 | photo cards, hero panels |
| `cardMd` | 18 | section panels |
| `cardSm` | 14 | inline chips |
| `tab` | 26 | iOS-style inset (Settings, if reused) |
| `hero` | 32 | rare — reveal-step hero rectangle |

### 2.5 Shadows

| Use | Spec |
|-----|------|
| Primary button glow | `goldCream.opacity(0.28)`, radius 15 |
| Center glyph halo | `goldCream.opacity(0.45)`, radius 24 |
| Photo card | `black.opacity(0.55)`, radius 24, y 24 + 1px gold border |
| Share card preview | `black.opacity(0.5)`, radius 28, y 14 |

### 2.6 Motion

| Token | Duration | Easing |
|-------|----------|--------|
| `Motion.stepAdvance` | 0.22s | easeInOut — onboarding step advance |
| `Motion.palmIgnitionDuration` | 2.4s | ease — palm-line draw-on |
| `Motion.minimumReadingDuration` | 8s | linear — loading state floor |
| `Motion.phraseInterval` / `phraseFade` | 2.8s | linear / ease — loading phrase rotation |

**Respect `.accessibilityReduceMotion`** — if it's true, snap to final state
instead of animating. Every long animation in the codebase honors this; new
ones must too.

---

## 3. Component library

Every reusable component lives in [`DesignSystem.swift`](../ios/PalmAura/PalmAura/DesignSystem.swift)
(or `Components/` for the larger ones). Use these. Don't build a one-off.

| Component | Purpose | Notes |
|-----------|---------|-------|
| `DarkScreenBackground` | Night sky + starfield | Every full-screen view |
| `ScreenHeader(eyebrow:back:moon:trailingText:)` | Top chrome | Renders moon dial OR a trailing text button, not both |
| `GoldButton(title:action:small:)` | Primary CTA | One per screen, near bottom |
| `GhostButton(title:action:leading:)` | Secondary CTA | Outline + caps label |
| `ChoiceCard(glyph:title:subtitle:selected:action:)` | Selectable option in onboarding | Right-side checkbox automatically wired |
| `GlyphCircle(glyph:size:selected:)` | Brass circle around a planetary glyph | Used in disclaimers + nav rows |
| `ParchmentPanel { content }` | Soft-glass card container | Home recap, settings sections, ritual bullets |
| `OrnamentRule()` | `——— ✦ ———` divider on dark surfaces | Section breaks |
| `OrnamentRuleLight()` | Same, but on parchment | Share card interior |
| `StepPips(total:index:)` | Onboarding step indicator | Wider pill on active step |
| `MoonPhase(phase:size:)` | Tiny moon dial | Embedded in ScreenHeader |
| `OrbitLoader` | Planetary orrery animation | App opening splash |
| `InkLinesLoader` | Three palm lines drawing on | Reading generation loader |
| `PalmCanvasView` | The palm photo + overlaid lines | Capture review, palm map, share card export |
| `DisclaimerFoot` | Tiny centered disclaimer | Bottom of every gated screen |

**If you find yourself recreating any of these inside a view, stop and use
the shared component.**

---

## 4. The copy pattern

PalmAura's voice is *quiet, knowing, slightly archaic.* The pattern repeats:

```
EYEBROW (small caps)
Setup phrase
   followed by italic emotional emphasis.
```

Examples:

- `· BEFORE THE HAND OPENS ·` / `Three answers,` / *before the hand opens.*
- `· A QUIET PROMISE ·` / `Before the hand` / *opens.*
- `· INSIDE THIS READING ·` / `Your fate line is` / *folding.*
- `LAST ANSWER` / `The Violet Wanderer` / *A quiet hour. The hand has heard you.*

Rules:

1. **Italic is used to underline emotion, not entire sentences.** The setup
   is roman; the resonant noun or verb is italic.
2. **Every screen has an eyebrow** in Cinzel small caps. It's the masthead of
   the screen. Without one, the screen feels naked.
3. **Avoid therapy-speak.** Never: "hold space", "lean into", "your truth",
   "lived experience". The oracle is older than therapy language.
4. **Never use exclamation marks.** Period.
5. **Soft prediction language only.** "The next few weeks favor X" — not
   "you will get X". This is also a legal/safety rule (see `copy-guardrails.md`).

---

## 5. Glyph mapping (no emoji, ever)

Emoji are **never** rendered in PalmAura, anywhere — not in UI, not in
captions, not in error messages. Use the engraved Unicode glyphs instead:

| Concept | Glyph | Notes |
|---------|-------|-------|
| Sun / star burst / brightness | `☉` | astrological sun |
| Moon / mystery / night | `☽` | crescent moon |
| Mercury / message / quickness | `☿` | |
| Venus / love / softness | `♀` | also used for "feminine current" if needed |
| Mars / drive / will | `♂` | |
| Jupiter / luck / expansion | `♃` | |
| Saturn / discipline / structure | `♄` | |
| Generic star / accent / decoration | `✦` | use sparingly |
| Generic ornament | `❋` | rare |
| Up arrow / external link | `↗` | not the emoji 🡵 |
| Back chevron | `‹` | ScreenHeader handles this |
| Forward indicator | `›` | append to button labels |

**No SF Symbols in user-facing UI either.** They look like iOS, not like
PalmAura. The one exception is system primitives that *must* use them (e.g.
the iOS share-sheet wraps `UIActivityViewController` which has its own).

---

## 6. Asset rules

There is **one** hero illustration: the engraved palmistry plate from a
19th-century reference. It ships as `PalmPlate` in the asset catalog.

- `PalmPlate` — original dark-ink engraving on transparent background. Use
  on parchment-style symbolic surfaces, including share cards, photo review
  cards, and the home palm map.

Do **not** place a hand silhouette over the live capture viewfinder. Capture
must remain neutral for left or right hands; use the camera preview, gold
frame, ticks, and copy as the guide.

Custom palm illustrations are not allowed without a brand-level approval.
Same plate everywhere is the brand.

---

## 7. State patterns

### 7.1 `@AppStorage` for first-run-only decisions

```swift
@AppStorage("disclaimerAccepted")    private var disclaimerAccepted = false
@AppStorage("hasCompletedFirstReveal") private var hasCompletedFirstReveal = false
```

### 7.2 Local stores for persistent data

- `LastReadingStore` — most recent `PalmReadingResponse`
- `PersonalizationStore` — `ReadingPersonalization` (birthday/gender/hand)
- `PalmPhotoStore` — locally saved palm photos (keyed by readingId)

Never use `UserDefaults.standard.set(_:forKey:)` directly. Always go through
the typed store. If you need a new persistent thing, **add a typed store** —
don't sprinkle UserDefaults across the views.

### 7.3 Analytics is a side effect of intent, not state

Every meaningful user action calls `Analytics.shared.track("event_name",
properties: [...])`. Preserve existing event names across refactors — the
backend dashboards depend on them.

### 7.4 No model changes inside view reskins

A view-layer redesign **never** touches `OnboardingAnswers`,
`ReadingPersonalization`, `PalmReadingResponse`, `ShareCard`, or
`ReadingBundle`. If a redesign needs a new field, it's a separate PR.

---

## 8. Build & tooling rules

- **iOS deployment target: 17.0.** All views are free to use SwiftUI 5
  features (`Canvas`, `TimelineView`, `.contentTransition`, `.tracking`,
  variable fonts).
- **Project is xcodegen-managed.** Edit `ios/PalmAura/project.yml`; never
  edit `PalmAura.xcodeproj/project.pbxproj` by hand. After editing the yml,
  run `xcodegen generate` from `ios/PalmAura/`.
- **Info.plist values live in `project.yml`** under `targets.PalmAura.info.properties`.
  Direct edits to Info.plist are erased on the next `xcodegen generate`.
- **Resources/Fonts/** is the canonical font home. `UIAppFonts` in
  `project.yml` declares them.
- **No new third-party dependencies.** Everything PalmAura needs ships
  with iOS 17 + SwiftUI.

---

## 9. Anti-patterns (PRs containing these will be rejected)

| Don't | Do |
|-------|-----|
| `Color.yellow` / `Color.purple` / `Color.orange` | `DesignSystem.ColorToken.goldCream` / `.skyMulberry` / etc. |
| `Font.custom("Georgia", ...)` | `DesignSystem.FontToken.display(_:italic:)` |
| `.font(.system(size: 18))` | `DesignSystem.FontToken.body(_:)` or `.display(_:)` |
| `.buttonStyle(.borderedProminent)` | `GoldButton(title:action:)` |
| `.buttonStyle(.bordered)` | `GhostButton(title:action:)` |
| `MysticalBackground()` | `DarkScreenBackground()` |
| `.navigationTitle("Settings")` | `ScreenHeader(eyebrow: "Settings", back: true)` |
| Hardcoded hex like `Color(hex: "#F3DDA8")` | Use the color token |
| Emoji in copy (`✨`, `🌙`, `❤️`) | Engraved glyphs (`✦`, `☽`, `♀`) |
| SF Symbols in user-facing copy (`Image(systemName: ...)`) | Engraved glyph text |
| Custom one-off card containers | `ParchmentPanel { ... }` |
| Inline `LinearGradient(...)` for backgrounds | `DarkScreenBackground()` or appropriate token gradient |
| Multiple primary buttons on one screen | One `GoldButton`, others as `GhostButton` |
| `print(...)` for runtime debugging | Remove before merging; use Xcode breakpoints |

---

## 10. How to add a new screen

Step-by-step checklist:

1. **Sketch the screen against the canonical skeleton** (§1). What's the
   eyebrow? What's the primary CTA? Is there a back button?
2. **Choose body content components** (§3). Most screens are some combination
   of `ParchmentPanel`, `ChoiceCard`, `OrnamentRule`, and text blocks.
3. **Write the copy in the pattern** (§4). Eyebrow + roman setup + italic
   emphasis. No exclamation marks. No therapy-speak.
4. **Use glyphs, never emoji** (§5).
5. **Reach only for `DesignSystem.*` tokens** (§2). If you need a new value,
   add it there with a tasteful name and a doc comment.
6. **Wire analytics**. Every primary CTA tracks an event with a
   `screen` property.
7. **Test with `.accessibilityReduceMotion` on.** If your screen has any
   non-trivial motion, gate it.
8. **Add a `#Preview`** showing the screen inside a `NavigationStack`.
9. **Run `xcodebuild ... build`** from `ios/PalmAura/` before opening a PR.
10. **Screenshot the screen on iPhone 17 Pro simulator** and attach to the
    PR description.

---

## 11. How to change the design system itself

Changes to `DesignSystem.swift` (new colors, new fonts, new components, new
motion tokens) are **not** view-layer changes and need a separate PR with:

- A short rationale ("Why does this token need to exist?")
- A description of the visual impact (with before/after screenshots if it
  changes existing screens)
- An update to this document under the relevant section

Token *removals* require a deprecation pass first — keep the old token as a
typealias for one release before deleting.

---

## 12. The single test of any design choice

Before merging any visual change, look at the screen and ask:

> **Does this feel like a page from a 19th-century palmistry book that
> happens to run on a phone?**

If yes, it ships. If no, iterate.

---

*Maintained by the design lead. PRs to this document are welcome — explain
the change in the PR description.*
