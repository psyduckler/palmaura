# PalmAura UX/UI Redesign Implementation Plan

> **For Hermes:** Use `subagent-driven-development` to implement this plan task-by-task. Keep commits small. Verify on iPhone simulator and, before any TestFlight/App Store push, on Bernard's physical phone.

**Goal:** Turn PalmAura from a technically working palm-reading MVP into a distinctive, ritual-feeling, video-shareable consumer iOS product without overbuilding the camera, retention, or backend too early.

**Architecture:** Keep the current SwiftUI + Cloudflare Worker architecture. Ship the redesign in four practical waves: (1) foundation and core emotional loop, (2) viral share exports, (3) physical retention mechanics, (4) advanced camera/social loops. Do not let `AVCaptureSession`, App Clips, push notifications, or custom illustration dependencies block the first major UX upgrade.

**Tech Stack:** SwiftUI, UIKit bridge where needed, ImageRenderer, AVFoundation/AVAssetWriter for video export, UserDefaults/AppStorage for local state, existing Cloudflare Worker TypeScript backend, existing `LastReadingStore`, existing analytics wrapper.

---

## 0. Executive Synthesis

Opus's plan is directionally right: the product needs pacing, a memorable visual identity, better share surfaces, and a real oracle voice. Gemini's critique is also right: the plan overreaches in three places that would add friction or delay:

1. **Reveal sequence length:** 13 taps is excellent first-run theater but too much for repeat use.
2. **Camera rewrite:** custom `AVCaptureSession` + Vision hand detection is valuable, but too risky for Phase 1.
3. **Static sharing and generic retention:** the viral unit should be a short looping video, and daily engagement should keep a tactile/body interaction.

The merged strategy:

- **First-time users get ceremony. Returning users get velocity.**
- **Phase 1 uses the system camera and improves framing/review around it.**
- **The main share artifact becomes a 3–5 second 9:16 looping MP4, with still image fallback.**
- **Retention rewards total participation in a moon cycle, not punitive streaks.**
- **Daily Glimpse requires a physical press-and-hold interaction so PalmAura does not devolve into a horoscope text app.**

---

## 1. Audit of Current App and Opus Plan

### Current codebase reality

Observed files in `/Users/psy/projects/palm-aura`:

- `ios/PalmAura/PalmAura/Views/ReadingResultView.swift`
  - Current result is a single `ScrollView` with title, summary, archetype, tiny horizontal share cards, 8 report sections, and footer.
  - Uses fixed Georgia typography and yellow/purple visual language.
- `ios/PalmAura/PalmAura/Views/ShareCardView.swift`
  - Current cards are gradient + abstract curves + text.
  - No palm imagery.
  - Uses absolute curve coordinates (`420 + i * 120`) that assume one canvas size.
- `ios/PalmAura/PalmAura/Views/OnboardingView.swift`
  - Current onboarding stacks three questions in one scroll view.
  - `Continue` and `Skip` are visually close in priority.
- `ios/PalmAura/PalmAura/Views/PalmCaptureView.swift`
  - Uses `UIImagePickerController` and `PhotosPicker`.
  - Capture affordance is a dashed rectangle plus `✋` emoji.
- `ios/PalmAura/PalmAura/Views/PalmReviewView.swift`
  - Shows dev-leaked `Upload size: X KB` text.
- `ios/PalmAura/PalmAura/Views/LoadingReadingView.swift`
  - Strongest current screen: 8-second minimum, phrase rotation.
  - Still uses `✋` emoji.
- `ios/PalmAura/PalmAura/Services/ShareCardRenderer.swift`
  - Exports only still `UIImage` via `ImageRenderer`.
- `ios/PalmAura/PalmAura/Models/PalmReadingResponse.swift`
  - Already has `nextReadingHook` available but underused.
- `backend/src/index.ts`
  - Backend prompt and response generation need voice updates, rare aura support later, and additional endpoints later.

### Opus plan: keep

- Reveal-first product framing.
- One-thing-per-screen onboarding and reading reveal.
- Replace generic hand emoji with a brand palm asset.
- Make share cards the climax, not a sidebar.
- Rewrite oracle voice away from generic therapy-speak.
- Add friend/compare mechanics after core loop works.
- Use `nextReadingHook` as the teaser at the end.
- Accessibility pass: dynamic type, reduced motion, contrast, camera fallback.

### Opus plan: revise

- **13-step reveal:** Keep for first reading only. Returning users get a condensed 4-step reveal.
- **Custom camera:** Defer full camera rewrite to Phase 4. Phase 1 keeps `UIImagePickerController` and builds better pre/post capture UX around it.
- **Static share cards:** Still images remain fallback; primary export becomes looping MP4.
- **Streaks:** Replace consecutive-day streaks with non-punitive moon-cycle totals and collection unlocks.
- **Daily Glimpse:** Must require press-and-hold/touch ritual.
- **App Clip:** Strong idea, but App Clip + universal links + web share page is Phase 3/4, not Phase 1.

---

## 2. Product Principles for the Redesign

1. **The palm is the brand.** Every major surface should contain either the captured palm, the illustrated palm, or glowing palm lines.
2. **Motion beats static.** If it is meant to be shared, it should have a video version.
3. **Ceremony only when it earns attention.** First run can be theatrical; repeat runs must be fast.
4. **Keep the body involved.** Capture, press, hold, haptics, and touch are the category moat.
5. **Reward without punishing.** Avoid streak anxiety; use moon-cycle counts, collections, and unlocks.
6. **Ship the vibe before deep platform work.** Visual system + reveal + share export matter more than App Clips and custom camera in the next sprint.
7. **Entertainment safety stays visible but not ugly.** Single elegant footer line on share media; clear disclaimers in app/profile.

---

## 3. Target UX: Core Loops

### 3.1 First-time reading loop

1. Disclaimer accepted.
2. Home screen introduces the ritual.
3. Three-card onboarding, one choice per screen:
   - Focus: `What's pulling at you today?`
   - Season: `What season are you in?`
   - Oracle voice: `How should the oracle speak to you?`
4. Capture prep screen with palm illustration + tips.
5. System camera / photo picker.
6. Review screen with captured image, aura preview, no debug data.
7. Loading ritual with animated palm line ignition.
8. Full reveal sequence, 8–10 beats max for first reading.
9. Full-screen share carousel with video export as primary CTA.
10. Tomorrow teaser and save state.

### 3.2 Returning reading loop

1. Home screen.
2. Primary CTA: `Read again`.
3. Uses previous onboarding defaults unless user taps `change focus`.
4. Capture/review/loading.
5. Condensed reveal sequence:
   - New aura/title.
   - One-line summary.
   - Biggest new insight/guidance.
   - Share/video carousel.
6. Full report remains accessible via `Read full report`.

### 3.3 Share loop

1. User lands on share carousel.
2. Primary button: `Share as Video`.
3. MP4 export generates 3–5 second 9:16 looping clip.
4. Secondary button: `Share Still`.
5. Output includes one-line footer: `palmaura.app · @PalmAuraApp · entertainment only`.
6. Analytics logs format and target intent.

### 3.4 Daily Glimpse loop

1. Home card: `Today's transmission is waiting.`
2. User presses and holds thumb on an animated glyph for ~2 seconds.
3. Haptics pulse while hold completes.
4. A 2–3 line daily insight appears, based on stored aura/archetype.
5. Optional share video/still.
6. Count increments toward moon-cycle total; no streak reset language.

---

## 4. Phased Roadmap

## Phase 1 — Core Feel + Launchable Redesign, no risky platform rewrites

**Objective:** Change the emotional category of the app in one focused sprint while preserving current technical stability.

**Do now:** design system, onboarding split, palm illustration placeholder, loading upgrade, dynamic reveal, share card redesign still export, backend voice prompt update, basic accessibility.

**Do not do yet:** full custom camera, App Clip, push notifications, rare aura backend dice roll, compare endpoint, web share pages.

### Task 1.1: Create a centralized design system

**Objective:** Remove scattered Georgia/yellow/purple styling and create reusable design tokens.

**Files:**
- Create: `ios/PalmAura/PalmAura/DesignSystem.swift`
- Modify later: all SwiftUI views that hard-code Georgia/yellow/purple.

**Implementation notes:**

Add:

- `enum Palette`
  - `inkBlack`
  - `pageCream`
  - `mistPeach`
  - `auraViolet`
  - `auraGold`
  - `auraFire`
  - `auraMoon`
  - `auraWater`
  - `auraRose`
- `enum Typography`
  - `display(size:)`
  - `body(size:weight:)`
  - `mono(size:)`
- `enum Motion`
  - `breathe`
  - `revealTap`
  - `lineIgnite`
- `extension Color.init(hex:)`
- `func color(for aura: AuraColor) -> Color`

**Acceptance criteria:**

- No new screens use raw `.purple`, `.yellow`, or `.custom("Georgia"...)`.
- Existing screens can be migrated incrementally.
- App still builds.

**Verification:**

```bash
cd /Users/psy/projects/palm-aura/ios/PalmAura
xcodebuild -project PalmAura.xcodeproj -scheme PalmAura -destination 'platform=iOS Simulator,name=iPhone 16' build
```

---

### Task 1.2: Add brand palm placeholder component

**Objective:** Replace the `✋` emoji with a reusable SwiftUI palm mark that can later be swapped for commissioned illustration assets.

**Files:**
- Create: `ios/PalmAura/PalmAura/Components/PalmAuraMark.swift`
- Modify: `PalmCaptureView.swift`
- Modify: `LoadingReadingView.swift`
- Modify: `DisclaimerView.swift` if it uses a hand/brand mark.

**Implementation notes:**

Build `PalmAuraMark` using SwiftUI shapes for now:

- Palm outline simplified with `Path`.
- Four line segments: heart/head/life/fate.
- Parameters:
  - `auraColor: AuraColor?`
  - `ignitedLines: Set<PalmLine>`
  - `isBreathing: Bool`
  - `lineStyle: PalmLineStyle`
- Respect `@Environment(\.accessibilityReduceMotion)`.
- Add accessibility label: `Illustrated palm with glowing reading lines`.

**Acceptance criteria:**

- No visible `✋` remains in capture/loading/result/disclaimer surfaces.
- Component can display 0–4 ignited lines.
- Reduced motion disables breathing scale animation.

---

### Task 1.3: Remove production-leaked debug copy from review

**Objective:** Clean the review screen and make it feel like a ritual handoff.

**Files:**
- Modify: `ios/PalmAura/PalmAura/Views/PalmReviewView.swift`

**Changes:**

- Delete `Text("Upload size: \(byteCount / 1024) KB")` from UI.
- Keep `byteCount` only for console/logging if useful.
- Add copy:
  - Title: `Your palm is captured.`
  - Body: `When you're ready, the oracle will read what your hand is willing to say.`
- Primary CTA: `Read my palm`.
- Secondary retake affordance should be visually quiet. If navigation retake is awkward, add copy: `Back to retake if the lines are blurry.`

**Acceptance criteria:**

- No upload size appears in user UI.
- Primary button is visually dominant.
- Review remains accessible after camera and photo-library selection.

---

### Task 1.4: Split onboarding into three ritual screens

**Objective:** Reduce cognitive load and make the first interaction feel magical.

**Files:**
- Replace/modify: `ios/PalmAura/PalmAura/Views/OnboardingView.swift`
- Create optional components:
  - `ios/PalmAura/PalmAura/Components/RitualChoiceCard.swift`
  - `ios/PalmAura/PalmAura/Views/OnboardingStepView.swift`

**Flow:**

Step 1 — Focus:

- Prompt: `What's pulling at you today?`
- Cards:
  - Love → moth
  - Career → key
  - Self → mirror
  - Purpose → compass
  - General → moon

Step 2 — Season:

- Prompt: `What season are you in?`
- Cards:
  - New beginning → sapling
  - Big decision → crossroads
  - Healing → bandaged bird
  - Building momentum → wave
  - Feeling stuck → stone in water

Step 3 — Oracle voice:

- Prompt: `How should the oracle speak to you?`
- Cards:
  - Gentle → dove
  - Direct → lightning
  - Mysterious → smoke
  - Deep spiritual → eye

**Gemini adjustment:**

- Keep skip, but make it a tiny top-right text link, not equal-weight button.
- If skipped, use `OnboardingAnswers.default` and log `onboarding_skipped`.

**Acceptance criteria:**

- User never sees all three questions at once.
- Tapping a card advances automatically.
- Haptic `.light` on each selection.
- Back navigation works between onboarding steps.
- No scroll required on normal iPhone screen sizes.

---

### Task 1.5: Add Home screen as the stable app root

**Objective:** Stop dropping every accepted user directly into onboarding. Create a simple destination for repeat use and future retention.

**Files:**
- Create: `ios/PalmAura/PalmAura/Views/HomeView.swift`
- Modify: `ios/PalmAura/PalmAura/Views/RootView.swift`
- Modify/use: `LastReadingStore.swift`

**Home layout:**

- Title: `PalmAura`.
- Primary CTA:
  - No reading yet: `Begin the ritual`.
  - Has reading: `Read again`.
- Secondary card if `LastReadingStore` has reading:
  - Aura color dot.
  - Last archetype/title.
  - `View last reading`.
- Small profile/settings icon in top-right.
- Footer disclaimer link.

**Acceptance criteria:**

- First-time accepted users can start onboarding.
- Returning users can go directly to capture with previous/default answers.
- Last reading is not hidden only inside Settings.

---

### Task 1.6: Replace result scroll with dynamic reveal sequence

**Objective:** Make the reading reveal feel like the product while avoiding Gemini's repeat-use friction warning.

**Files:**
- Create: `ios/PalmAura/PalmAura/Views/RevealSequenceView.swift`
- Create: `ios/PalmAura/PalmAura/Views/RevealSteps/*.swift` or keep private structs in one file initially.
- Modify: `ios/PalmAura/PalmAura/Views/LoadingReadingView.swift` navigation destination.
- Keep: `ReadingResultView.swift` as `FullReadingView` or refactor it.

**State model:**

Create:

```swift
enum RevealMode {
    case firstRun
    case returning
}

enum RevealStep: Hashable {
    case title
    case summary
    case archetype
    case heartLine
    case headLine
    case lifeLine
    case fateLine
    case currentSeason
    case guidance
    case ritual
    case share
    case tomorrow
    case end
}
```

**First-run sequence:**

Use 9–10 beats, not the full 13:

1. Title/aura.
2. One-line summary.
3. Archetype.
4. Palm lines combined screen with tap-to-cycle lines internally or 2 grouped screens:
   - heart/head
   - life/fate
5. Current season.
6. Guidance.
7. Ritual.
8. Share carousel.
9. Tomorrow teaser.
10. End state.

**Returning sequence:**

1. New aura/title.
2. One-line summary.
3. Guidance or most distinctive line.
4. Share carousel.
5. `Read full report` secondary link.

**Controls:**

- Tap anywhere advances.
- Swipe via `TabView` works.
- Top-right `Skip` / `Full report` link.
- Progress dots or tiny moon phase indicator, not numeric `3/13`.

**Acceptance criteria:**

- First reading reaches share in under ~60 seconds if user taps at natural pace.
- Returning reading reaches share in <=4 taps.
- Full text still accessible.
- `nextReadingHook` renders at the end if present.
- Reduced motion changes transitions to opacity fades.

---

### Task 1.7: Keep full report, but demote it

**Objective:** Preserve depth without making the default result feel like a PDF.

**Files:**
- Rename or refactor: `ReadingResultView.swift` → `FullReadingView.swift` or keep name and create new reveal as default.

**Changes:**

- Full report is accessible from reveal end state and history.
- Full report can remain scrollable, but should use new design system and better section cards.
- Settings gear should not be only here.

**Acceptance criteria:**

- User can inspect all 8 report fields.
- Default post-loading path is reveal, not scroll report.

---

### Task 1.8: Redesign share cards with proportional layout and palm centerpiece

**Objective:** Make still card exports look like brand artifacts and prepare for video export in Phase 2.

**Files:**
- Modify: `ios/PalmAura/PalmAura/Views/ShareCardView.swift`
- Modify: `ios/PalmAura/PalmAura/Services/ShareCardRenderer.swift`

**Card formats:**

1. Aura Card
   - Top 55–60%: `PalmAuraMark` with aura glow.
   - Bottom: title/body.
2. Archetype Card
   - Centered symbolic figure placeholder until art exists.
   - Tarot-ish border, restrained.
3. 30-Day Theme Card
   - Magazine/movie-poster layout.
   - Big theme line.
   - Small date/reading ID style mono caption.

**Layout rule:**

- Use `GeometryReader` and proportional positions.
- No hard-coded `y = 420 + i * 120` style offsets.

**Footer:**

Single line:

`palmaura.app · @PalmAuraApp · entertainment only`

**Acceptance criteria:**

- Render at 1080×1920 via `ShareCardRenderer`.
- Looks good at in-app preview sizes and full export size.
- No palm-less card remains.
- Footer is one quiet line.

---

### Task 1.9: Update loading with palm line ignition

**Objective:** Preserve the strongest current screen while making it branded and tactile.

**Files:**
- Modify: `ios/PalmAura/PalmAura/Views/LoadingReadingView.swift`

**Changes:**

- Replace emoji with `PalmAuraMark`.
- Ignite lines at approximate loading times:
  - 2s heart
  - 4s head
  - 6s life
  - 7.5s fate
- Haptic `.medium` per ignition, unless reduced motion/haptics disabled.
- Add phrases:
  - `Asking the moon for permission…`
  - `The cosmos is checking its notes…`
  - `Translating from the language of skin…`
  - `Consulting your great-great-grandmother…`
  - `Bargaining with a small star…`
  - `Listening for the answer your palm already gave…`

**Acceptance criteria:**

- Minimum 8-second ritual remains.
- Line ignition happens even when backend returns quickly.
- Error retry path still works.

---

### Task 1.10: Backend oracle voice rewrite

**Objective:** Make generated readings feel screenshot/share-worthy and less generic.

**Files:**
- Modify: `backend/src/index.ts`
- Update fixture if needed: `ios/PalmAura/PalmAura/Resources/fixture-reading.json`

**Prompt rules:**

- No therapy-speak: avoid `hold space`, `lean into`, `your truth`, `could perhaps`, `might consider`.
- Specific, embodied, concrete language.
- Occasionally cheeky, never insulting.
- Strong style differentiation:
  - Gentle: warm, protective, soft but specific.
  - Direct: concise, blunt, no hedging.
  - Mysterious: symbolic, strange, moonlit, not vague.
  - Deep spiritual: ritualistic, ancient, grounded in action.
- Keep entertainment disclaimer unchanged.
- Preserve current response schema.

**Example target copy:**

- `Violet. Of course it's violet. You overthink at parties and your palm is tired of pretending otherwise.`
- `Tonight: write down the decision. Circle the option your shoulders prefer. Trust them.`

**Acceptance criteria:**

- Backend typecheck passes.
- `/api/read` still returns same schema.
- Fixture demonstrates the new voice.
- No medical/financial/deterministic life claims.

---

### Task 1.11: First accessibility pass

**Objective:** Avoid building a beautiful app that fails App Store accessibility scrutiny.

**Files:**
- Touch all new/modified SwiftUI views.

**Checklist:**

- `accessibilityLabel` on palm mark and symbolic cards.
- `accessibilityHint` on tap-to-advance reveal.
- Dynamic Type: avoid fixed body text that cannot scale.
- Reduced motion: all breathing/ignition/transition animations have fallbacks.
- Contrast: avoid low-opacity white text on saturated gradients for key copy.
- Camera denial: system picker fallback remains available.

**Acceptance criteria:**

- VoiceOver labels are not emoji names.
- Reduced Motion path has no continuous parallax/breathing.
- Primary text passes eyeball contrast check; run Xcode Accessibility Inspector before release.

---

## Phase 2 — Video-First Virality

**Objective:** Upgrade the share artifact from nice static cards to TikTok/IG-friendly looping video.

### Task 2.1: Define animated share templates

**Files:**
- Create: `ios/PalmAura/PalmAura/Views/AnimatedShareCardView.swift`
- Create: `ios/PalmAura/PalmAura/Models/ShareExportFormat.swift`

**Templates:**

- Aura video: aura pulses, palm lines ignite, title fades in.
- Archetype video: figure/card floats in, border shimmer, title locks.
- Theme video: poster text types/fades, motif drifts.

**Acceptance criteria:**

- All templates fit 9:16.
- Duration target: 3–5 seconds.
- Loops cleanly enough for Stories/Reels preview.

---

### Task 2.2: Add MP4 export service

**Files:**
- Create: `ios/PalmAura/PalmAura/Services/ShareVideoRenderer.swift`
- Modify: `ios/PalmAura/PalmAura/Views/ShareOptionsSheet.swift`

**Implementation options:**

- Preferred: render SwiftUI frames with `ImageRenderer` at fixed FPS, encode with `AVAssetWriter`.
- MVP fallback: generate 60–90 PNG frames at 1080×1920, encode to H.264 MP4.
- Keep still `UIImage` export path as fallback.

**Export spec:**

- Resolution: 1080×1920.
- Duration: 3–5 seconds.
- FPS: 24 or 30.
- Codec: H.264.
- Output temp file: `.mp4` in cache directory.

**Acceptance criteria:**

- Share sheet can share MP4 file.
- Export completes on modern iPhone in acceptable time.
- If video export fails, app falls back to still image and logs failure.

---

### Task 2.3: Make video the primary share CTA

**Files:**
- Modify: `ShareOptionsSheet.swift`
- Modify: `RevealSequenceView.swift` share step.

**UX:**

- Primary: `Share as video`.
- Secondary: `Share still image`.
- Tertiary: `Save to Photos` if permissions are handled.

**Acceptance criteria:**

- User sees video as default, not hidden option.
- Analytics distinguishes `share_video_started`, `share_video_completed`, `share_still_completed`.

---

### Task 2.4: Create social QA harness

**Objective:** Avoid shipping video exports that look broken after compression.

**Files:**
- Create: `docs/qa/share-video-checklist.md`
- Optional: save sample exports under ignored local artifacts.

**Checklist:**

- Export from simulator.
- AirDrop or upload to phone.
- Preview in Photos.
- Test Instagram Story import.
- Test TikTok/Reels import if available.
- Verify footer readable but not ugly.
- Verify no medical/fortune claims appear in exported media.

---

## Phase 3 — Physical Retention, Not Horoscope Slop

**Objective:** Add repeat use without losing the tactile identity.

### Task 3.1: Add local reading counters and moon-cycle progress

**Files:**
- Create: `ios/PalmAura/PalmAura/Services/ReadingProgressStore.swift`
- Modify: `LoadingReadingView.swift` or completion path.
- Modify: `HomeView.swift`.

**Data:**

- Total readings all-time.
- Readings this moon cycle or current 28-day window.
- Archetypes collected.
- Aura colors seen.

**Avoid:**

- Consecutive-day streak counters.
- `You broke your streak` copy.
- Red warning badges.

**Copy examples:**

- `You've read your palm 7 times this moon cycle.`
- `3 more readings until the next archetype shelf opens.`

---

### Task 3.2: Build press-and-hold Daily Glimpse MVP

**Files:**
- Create: `ios/PalmAura/PalmAura/Views/DailyGlimpseView.swift`
- Create: `ios/PalmAura/PalmAura/Services/DailyGlimpseStore.swift`
- Modify: `HomeView.swift`

**MVP behavior:**

- Uses last reading data locally at first; backend endpoint can come later.
- User must press and hold for ~2 seconds.
- Haptic pulses during hold.
- On completion, show short daily line.
- One Daily Glimpse per calendar day locally.

**Gemini requirement:**

- No passive push-only horoscope message. The body/touch ritual is mandatory.

**Acceptance criteria:**

- Releasing before completion cancels.
- Completion feels tactile.
- No palm recapture required for the Daily Glimpse MVP, but touch is required.

---

### Task 3.3: Add backend `/api/daily-glimpse`

**Files:**
- Modify: `backend/src/index.ts`
- Modify: `ReadingAPIClient.swift` or create `DailyGlimpseAPIClient.swift`

**Request:**

- `deviceId`
- `lastAuraColor`
- `lastArchetype`
- `locale`
- `style`

**Response:**

- `glimpseId`
- `title`
- `body`
- `shareCard`
- `createdAt`
- `entertainmentDisclaimer`

**Rate limit:**

- Separate from `/api/read` limit.
- 1/day/device initially.

---

### Task 3.4: Add collection surfaces

**Files:**
- Create: `ios/PalmAura/PalmAura/Views/ProfileView.swift`
- Create: `ios/PalmAura/PalmAura/Views/AuraHistoryView.swift`
- Modify: `SettingsView.swift` or move settings into profile.

**Surfaces:**

- Moon-cycle total.
- Aura color wall/dots.
- Archetypes collected.
- Last reading access.
- Sound toggle placeholder if sound ships.
- Privacy/terms/disclaimer.

---

## Phase 4 — Advanced Growth Loops and Platform Work

**Objective:** Add more complex viral mechanics only after the core redesigned loop proves retention/share interest.

### Task 4.1: Friend palm mode

**Flow:**

- Pre-capture question: `Whose palm is this? Mine / A friend's`.
- If friend: ask first name.
- Reading copy uses friend's name.
- Share card says `A reading for Maya` and has CTA language.

**Files:**

- Extend `PalmReadingRequest` onboarding/context.
- Backend prompt update.
- Share card footer/metadata update.

---

### Task 4.2: Compare auras mode

**Flow:**

- User completes their reading.
- CTA: `Compare auras`.
- Capture second palm.
- Generate compatibility result/card.

**Implementation choice:**

- MVP: call `/api/read` twice and combine client-side with a lightweight backend prompt later.
- Later: `/api/compare` endpoint accepts two reading summaries and returns compatibility copy/cards.

---

### Task 4.3: Web share page + App Store conversion

**Files/Infra:**

- Create landing route for `palmaura.app/r/<readingId>`.
- If no real reading persistence yet, render static public share metadata or signed card image/video URL.
- Aggressive CTA: `Get your own aura`.
- App Store Smart App Banner.
- Universal links when available.

**Gemini note:**

- A web view alone is not enough. The page exists to convert to scan/install.

---

### Task 4.4: App Clip exploration

**Objective:** Let recipients scan a hand without full app install.

**Reality check:**

- App Clips require Apple Developer setup, size constraints, associated domains, and careful scope.
- Do only after share links get traffic.

**Acceptance criteria for starting:**

- Share link CTR exists.
- App Store Connect/account setup is ready.
- Core app loop is stable.

---

### Task 4.5: Custom camera with Vision hand guidance

**Objective:** Upgrade capture from system picker to Apple-grade live guidance once the product loop is proven.

**Files:**

- Create `CameraSessionView.swift`.
- Use `AVCaptureSession`.
- Optional Vision: `VNDetectHumanHandPoseRequest`.

**Guidance states:**

- `Fill the frame…`
- `Hold steady…`
- `Lighting looks good…`
- `Hold for one second…`
- Auto-capture.

**Why deferred:**

- Hardware variability and camera permissions can burn days.
- Current `UIImagePickerController` is stable and good enough while the product's vibe is being validated.

---

### Task 4.6: Rare aura mechanic

**Backend:**

- Add server-side rare aura roll to OK readings.
- Rates:
  - Obsidian: 1%
  - Iridescent: 3–4%
  - Eclipse: event-gated only, later.
- Return same schema if possible, or extend enum carefully.

**iOS:**

- Update `AuraColor` enum to include rare cases.
- Rare aura gets unique haptic `.heavy` and special share template.

**Caution:**

- Do not mention rarity in onboarding.
- Avoid gambling/paywall language.

---

## 5. Design Direction Decision

Recommended direction: **lo-fi whimsy with brutalist typography accents**.

### Visual ingredients

- Backgrounds: cream/peach/lavender/ink rather than stock purple nebula.
- Typography: expressive display face + clean readable body + mono captions.
- Illustration: hand-drawn palm, moth/key/mirror/compass/moon symbols, later archetype figures.
- Texture: subtle paper grain or soft noise.
- Motion: slow pulse, line ignition, floating cards.

### Asset plan

**Immediate placeholder:** SwiftUI `PalmAuraMark` and symbolic SF/hand-drawn-ish simple line icons.

**Commission brief:**

- 1 palm illustration with separate layers:
  - palm outline
  - heart line
  - head line
  - life line
  - fate line
  - aura glow mask
- 15–20 small symbols for onboarding/ritual/share motifs.
- 8 initial archetype figures, expandable to 20.
- Deliverables: SVG/PDF vectors plus PNG exports; transparent background; separate layers.

**Budget guidance:**

- Palm + symbols: highest ROI, commission first.
- Archetypes: phase after share/reveal loop validates.
- Custom font: not needed for v1; use licensed or bundled open-source font first.

---

## 6. Analytics Events to Add

Keep this lightweight but enough to see where magic turns into friction.

### Onboarding

- `onboarding_started`
- `onboarding_focus_selected`
- `onboarding_season_selected`
- `onboarding_style_selected`
- `onboarding_completed`
- `onboarding_skipped`

### Capture/review/loading

- Existing `photo_captured`, `photo_chosen`, `reading_requested`, `reading_completed`, `reading_failed`.
- Add `review_read_tapped`.
- Add `review_back_or_retake_tapped` if implemented.

### Reveal

- `reveal_started` with `mode=firstRun|returning`
- `reveal_step_viewed`
- `reveal_skipped_to_share`
- `reveal_full_report_opened`
- `reveal_completed`

### Share

- `share_carousel_viewed`
- `share_card_selected`
- `share_video_started`
- `share_video_completed`
- `share_video_failed`
- `share_still_completed`

### Retention

- `daily_glimpse_hold_started`
- `daily_glimpse_hold_cancelled`
- `daily_glimpse_completed`
- `moon_cycle_progress_viewed`

---

## 7. Quality Gates

### Build/test gates per phase

```bash
cd /Users/psy/projects/palm-aura/ios/PalmAura
xcodebuild -project PalmAura.xcodeproj -scheme PalmAura -destination 'platform=iOS Simulator,name=iPhone 16' test
xcodebuild -project PalmAura.xcodeproj -scheme PalmAura -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build

cd /Users/psy/projects/palm-aura/backend
npm run typecheck
```

### Manual QA gates

- First-run flow completes from disclaimer → share.
- Returning flow reaches share in <=4 taps after loading.
- Photo library path works.
- Camera path works.
- Not-palm rejection still works.
- Network timeout/error retry still works.
- Last reading is saved and accessible.
- Share still image exports at 1080×1920.
- Phase 2: MP4 opens in Photos and imports into Instagram/TikTok story composer.
- VoiceOver announces core controls intelligibly.
- Reduced Motion disables continuous breathing/parallax.

---

## 8. Prioritized Sprint Plan

### Sprint A: 2–3 days, immediate UX cleanup

1. Design system.
2. `PalmAuraMark` placeholder.
3. Remove upload size from review.
4. Loading palm-line ignition.
5. Backend voice prompt rewrite + fixture update.
6. Build/typecheck/smoke.

**Outcome:** app already feels less prototype-y.

### Sprint B: 3–5 days, core ritual

1. Home screen.
2. Three-step onboarding.
3. Dynamic reveal sequence.
4. Full report demotion.
5. First accessibility pass.
6. Simulator + physical phone test.

**Outcome:** core product loop feels like a ritual, not a form/report.

### Sprint C: 3–5 days, share engine

1. Share card redesign with proportional layout.
2. Full-screen share carousel.
3. MP4 renderer MVP.
4. Share sheet primary video CTA.
5. Social QA harness.

**Outcome:** users can export the thing that actually has a shot on Stories/Reels/TikTok.

### Sprint D: 3–5 days, retention MVP

1. Moon-cycle total counter.
2. Press-and-hold Daily Glimpse local MVP.
3. Profile/history surface.
4. Optional backend `/api/daily-glimpse` if local signal is promising.

**Outcome:** engagement loop exists without turning PalmAura into generic horoscope spam.

---

## 9. Explicit Non-Goals Until Core Loop Is Proven

Do not build these before Phase 1/2 metrics and manual QA are healthy:

- Full custom `AVCaptureSession` with Vision hand detection.
- App Clip.
- Push notifications.
- Web reading pages with real persistence.
- Compare aura endpoint.
- Full archetype illustration set.
- Rare aura backend mechanic.
- Subscriptions/paywalls.
- Custom display font commission.

---

## 10. Success Metrics

### Product feel metrics

- First-run completion: user reaches share carousel after successful reading.
- Returning reveal speed: share carousel in <=4 taps after loading.
- Share intent: percentage of completed readings where user opens share sheet.
- Video share: percentage choosing video over still once available.

### Engagement metrics

- Repeat reading within 7 days.
- Daily Glimpse completion after viewing home prompt.
- Moon-cycle readings per active user.

### Quality metrics

- Reading API error rate.
- Reading timeout rate.
- Share export failure rate.
- App crash-free sessions.
- Not-palm rejection path remains understandable.

---

## 11. Final Recommendation

Start with **Sprint A + Sprint B** before any platform-heavy work. The highest-ROI path is not the custom camera or App Clip yet. It is:

1. Replace the emoji/stock mystic look with a real palm mark and design system.
2. Split onboarding into tactile, one-choice screens.
3. Replace the scroll result with a first-run/returning dynamic reveal.
4. Make share the climax.
5. Rewrite the oracle voice.

Then immediately do **Sprint C** for video exports. Gemini is right: if the artifact is only static, the viral surface is underpowered.

If we execute in this order, PalmAura gets the emotional upgrade without burying the team in camera/app-clip complexity before the core loop proves it deserves that investment.
