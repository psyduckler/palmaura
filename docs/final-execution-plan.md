# PalmAura iOS MVP — Final Execution Plan

> **For Hermes:** Use `subagent-driven-development` to execute this plan task-by-task. Do not add scope unless Bernard explicitly asks. Optimize for a working internal TestFlight build, shareable result cards, and App Store survival.

**Goal:** Ship a native SwiftUI iOS palm-reading app prototype that lets a user scan/upload a palm photo, answer 3 low-friction ritual questions, receive an entertainment-only mystical reading, and share beautiful 9:16 cards to Instagram/TikTok.

**Name posture:** `PalmAura` is the committed app name. Keep app naming, domain, watermark, and copy centralized so the brand is consistent everywhere.

**Default assumptions approved unless changed:**

- App name: `PalmAura`
- Domain: `https://palmaura.app`
- Share watermark: `@PalmAuraApp`
- iOS only, native SwiftUI
- Cloudflare Worker backend, single API endpoint
- Anthropic multimodal model first, model name configured via env var
- No accounts
- No palm image storage by PalmAura
- Device IDFV-based rate limit: 3 readings/day/device
- 3 onboarding questions
- 3 share cards for v0
- Hard-but-friendly rejection if the image is not a palm
- Minimum 8-second mystical loading state
- Optional PostHog + Sentry, no-op if keys are unset
- Internal TestFlight + App Store submission in parallel

---

## Product Principles

### 1. App Store survival first

Apple may scrutinize fortune-telling apps under spam, low utility, misleading claims, or physical/medical harm rules. PalmAura must look and behave like a polished symbolic entertainment / self-reflection app, not a scammy psychic hotline.

Rules:

- First launch must include forced entertainment-only acceptance.
- Every result screen must include an entertainment-only footer.
- Every share card must include tiny `For entertainment only` text.
- The backend must refuse non-palm images instead of generating fake readings.
- Never generate medical, legal, financial, fertility, death, lifespan, diagnosis, pregnancy, guaranteed-outcome, or deterministic fate claims.
- Brand language should feel modern wellness / astrology: Co-Star, The Pattern, mystical but polished.

### 2. No PalmAura image storage

Palm photos are biometric-adjacent. v0 should not store them.

Privacy stance:

- iOS app downsizes image locally.
- Backend receives image in memory for one request.
- Backend sends image to AI provider for real-time inference.
- PalmAura does not save palm photos to a database, object store, logs, or analytics.
- PalmAura may log non-image events: app opened, reading requested, reading completed, bad image, share tapped.

Privacy copy should not overpromise what the AI provider does. Use:

> PalmAura does not store your palm photos on our servers. Images are sent to our AI provider for real-time processing and are not saved by PalmAura.

Avoid:

> Nothing is ever saved anywhere.

### 3. Share cards are the product

The core retention/viral loop is:

```text
Scan palm → feel seen → save/share aesthetic card → friend asks what app made it → install/TestFlight
```

Build a working product around that loop before subscriptions, accounts, compatibility, or custom CV.

---

## Architecture

```text
SwiftUI iOS app
  ├─ onboarding + camera/photo picker
  ├─ local image resize/compress
  ├─ mystical loading state
  ├─ result UI
  └─ SwiftUI ImageRenderer share cards
        ↓ HTTPS JSON
Cloudflare Worker
  ├─ /api/health
  └─ /api/read
        ├─ validate request with Zod
        ├─ rate limit by IDFV using Cloudflare KV
        ├─ call Anthropic multimodal model with forced tool/schema output
        ├─ validate response
        └─ return structured JSON
```

No DB. No accounts. No image storage. Optional PostHog/Sentry only.

---

## Repo Layout

```text
palm-aura/
  README.md
  .gitignore
  ios/
    PalmAura/
      PalmAura.xcodeproj
      PalmAura/
        PalmAuraApp.swift
        BrandConfig.swift
        AppConfig.swift
        Info.plist
        Models/
          OnboardingAnswers.swift
          PalmReadingRequest.swift
          PalmReadingResponse.swift
        Services/
          DeviceID.swift
          ReadingAPIClient.swift
          ImagePreprocessor.swift
          ShareCardRenderer.swift
          InstagramStorySharer.swift
          Analytics.swift
          LastReadingStore.swift
        Views/
          RootView.swift
          DisclaimerView.swift
          OnboardingView.swift
          PalmCaptureView.swift
          PalmReviewView.swift
          LoadingReadingView.swift
          ReadingResultView.swift
          ShareCardView.swift
          ShareOptionsSheet.swift
          SettingsView.swift
        Components/
          PrimaryButton.swift
          QuestionChip.swift
          DisclaimerFooter.swift
          MysticalBackground.swift
        Resources/
          fixture-reading.json
          mystical-loading-phrases.json
        Assets.xcassets/
      PalmAuraTests/
        ContractEncodingTests.swift
        PalmReadingResponseTests.swift
        ImagePreprocessorTests.swift
  backend/
    api/
      health.ts
      read.ts
    package.json
    tsconfig.json
    wrangler.toml
    README.md
  landing/
    index.html
    privacy.html
    terms.html
    apple-app-site-association
  docs/
    app-store-review-checklist.md
    copy-guardrails.md
```

---

## Centralized Brand Configuration

All brand naming must be centralized and consistently use PalmAura.

### iOS: `BrandConfig.swift`

```swift
enum BrandConfig {
    static let appName = "PalmAura"
    static let domain = "palmaura.app"
    static let websiteURL = "https://palmaura.app"
    static let socialHandle = "@PalmAuraApp"
    static let supportEmail = "support@palmaura.app"

    static let entertainmentDisclaimer = "PalmAura readings are symbolic entertainment and self-reflection only. They are not medical, legal, financial, psychological, or life-critical advice."
}
```

### Backend env

```bash
PUBLIC_APP_NAME=PalmAura
PUBLIC_APP_DOMAIN=palmaura.app
PUBLIC_SOCIAL_HANDLE=@PalmAuraApp
```

### Landing page brand constants

Use simple top-level constants at the top of each static HTML file or a tiny build-time replacement script if desired. Do not hardcode scattered names throughout multiple files.

---

## Data Contracts

### Request: iOS → backend

```ts
export type ReadingFocus = 'love' | 'career' | 'self' | 'purpose' | 'general';
export type LifeSeason = 'new_beginning' | 'big_decision' | 'healing' | 'building_momentum' | 'feeling_stuck' | 'unknown';
export type ReadingStyle = 'gentle' | 'direct' | 'mysterious' | 'deep_spiritual';

export interface PalmReadingRequest {
  clientRequestId: string;
  deviceId: string;
  appVersion: string;
  locale: string;
  imageBase64Jpeg: string; // longest edge <= 1024px, target <= 800KB raw JPEG, <= ~1.2MB base64
  onboarding: {
    focus: ReadingFocus;
    lifeSeason: LifeSeason;
    readingStyle: ReadingStyle;
  };
}
```

### Response: backend → iOS

Use one response shape with `status` so the app can render deterministic screens.

```ts
export type ReadingStatus = 'ok' | 'not_palm' | 'bad_image';

export interface PalmReadingResponse {
  status: ReadingStatus;
  readingId: string;
  title: string;
  oneLineSummary: string;
  auraColor: 'violet' | 'gold' | 'fire' | 'moon' | 'water' | 'rose';
  archetype: string;
  shareCards: ShareCard[]; // exactly 3 when status = ok
  report: {
    aura: string;
    heartLine: string;
    headLine: string;
    lifeLine: string;
    fateLine: string;
    currentSeason: string;
    guidance: string;
    ritual: string;
  };
  rejectionMessage?: string;
  nextReadingHook?: {
    focus: ReadingFocus;
    teaser: string;
  };
  entertainmentDisclaimer: string;
  createdAt: string;
}

export interface ShareCard {
  format: 'aura' | 'archetype' | 'thirty_day';
  title: string; // <= 4 words
  body: string;  // <= 22 words
  accentColor: string; // hex
  theme: 'moon' | 'fire' | 'water' | 'gold' | 'violet' | 'rose';
}
```

### Error responses outside model output

```ts
{ "error": "rate_limited", "retryAfterSeconds": 86400, "message": "You've used your free readings today. Come back tomorrow ✨" }
{ "error": "invalid_request", "message": "Invalid request." }
{ "error": "server_error", "message": "The reading was interrupted. Try again." }
```

---

## Backend Prompt and Safety Contract

### System prompt

```text
You are {{APP_NAME}}, a polished mystical palm-reading guide for symbolic entertainment and self-reflection ONLY.

ABSOLUTE SAFETY RULES:
- Never provide medical, legal, financial, psychological, fertility, pregnancy, lifespan, death, diagnosis, or life-critical advice.
- Never predict illness, death, fertility, pregnancy, guaranteed wealth, legal outcomes, or unavoidable future events.
- Never claim certainty. Use language like "suggests," "symbolizes," "may point to," and "invites you to reflect on."
- Never say a person's fate is fixed.
- Do not mention being an AI model.
- Do not output prose outside the required structured tool/schema output.

IMAGE VALIDATION:
- If the image is not clearly a human palm/open hand, return status = "not_palm" and a short friendly rejectionMessage. Do not generate a reading.
- If the image is a palm but too dark, blurry, cropped, or unclear to read, return status = "bad_image" and a short friendly rejectionMessage. Do not fake detailed line observations.
- Only generate status = "ok" when the image appears to contain a human palm/open hand.

READING STYLE:
- gentle: warm, soft, encouraging
- direct: clear, confident, mystical but no-nonsense
- mysterious: poetic, evocative, layered metaphor
- deep_spiritual: sacred, archetypal, transformational

GROUNDING:
- Ground observations in visible palm features and/or the user's onboarding answers.
- It is okay to be symbolic, but do not invent concrete facts about the person's real life.

SHARE CARDS:
Generate exactly 3 share cards when status = "ok":
1. aura — "Your Aura is [Color]" style
2. archetype — "You are: The [Archetype]" style
3. thirty_day — symbolic next-30-days theme

Each share card title must be <= 4 words. Each body must be <= 22 words. Cards should be aesthetically punchy for Instagram/TikTok sharing.

OUTPUT:
Use the required structured output/tool schema only.
```

### User prompt

```text
Onboarding context:
- Seeking clarity on: {{focus}}
- Current season: {{lifeSeason}}
- Reading style: {{readingStyle}}

Read this palm if it is a clear human palm. If not, return the appropriate status and rejection message.
```

---

## Implementation Tasks

### Task 1 — Repo skeleton and centralized naming

**Objective:** Create the monorepo skeleton and centralize placeholder naming.

**Files:**
- Create: `README.md`
- Create: `.gitignore`
- Create: `ios/.gitkeep`
- Create: `backend/README.md`
- Create: `landing/index.html`
- Create: `docs/copy-guardrails.md`

**Acceptance criteria:**

- Repo exists and is committed.
- README states this is an entertainment-only palm-reading app.
- `.gitignore` excludes `.env*`, `.vercel`, `.wrangler`, `node_modules`, `DerivedData`, `.DS_Store`, Xcode user data.
- Copy guardrails document lists banned claim categories.

---

### Task 2 — Manual Xcode project setup

**Objective:** Create the SwiftUI app project.

**Bernard/manual step:**

Create Xcode project:

- Product name: `PalmAura`
- Interface: SwiftUI
- Language: Swift
- Tests: enabled
- Bundle ID: placeholder, e.g. `app.palmaura.PalmAura`
- Path: `ios/PalmAura/`

**Hermes follow-up files:**

- Create: `ios/PalmAura/PalmAura/BrandConfig.swift`
- Create: `ios/PalmAura/PalmAura/AppConfig.swift`
- Create: `ios/PalmAura/PalmAura/Views/RootView.swift`

**Acceptance criteria:**

- App builds to simulator.
- `RootView` loads.
- All visible name/domain/social handle references go through `BrandConfig`.

---

### Task 3 — Swift models and contract encoding tests

**Objective:** Define Codable models that exactly match backend contracts.

**Files:**
- Create: `Models/OnboardingAnswers.swift`
- Create: `Models/PalmReadingRequest.swift`
- Create: `Models/PalmReadingResponse.swift`
- Create: `Services/DeviceID.swift`
- Create: `PalmAuraTests/ContractEncodingTests.swift`

**Implementation requirements:**

- Enums: `ReadingFocus`, `LifeSeason`, `ReadingStyle`, `ReadingStatus`, `AuraColor`, `ShareCardFormat`, `ShareCardTheme`.
- `DeviceID.current` uses `UIDevice.current.identifierForVendor?.uuidString ?? "unknown"`.
- `PalmReadingRequest` encodes `clientRequestId`, `deviceId`, `appVersion`, `locale`, `imageBase64Jpeg`, `onboarding`.
- Swift raw values must match backend strings exactly.

**Acceptance criteria:**

- Unit test encodes a fixture request and asserts JSON keys match backend Zod schema.
- Unit test decodes `fixture-reading.json`.

---

### Task 4 — First-launch disclaimer gate

**Objective:** Ensure App Store-safe entertainment-only framing before usage.

**Files:**
- Create/modify: `Views/RootView.swift`
- Create: `Views/DisclaimerView.swift`
- Create: `Components/PrimaryButton.swift`
- Create: `Components/DisclaimerFooter.swift`
- Create: `Components/MysticalBackground.swift`

**UX requirements:**

- Full-screen polished dark gradient.
- App name from `BrandConfig.appName`.
- Required copy:
  - “Mystical palm readings for entertainment and self-reflection.”
  - “Not medical, legal, financial, psychological, or life-critical advice.”
- Button: “I understand — begin”.
- Store acceptance locally with `AppStorage("disclaimerAccepted")`.

**Acceptance criteria:**

- Fresh install shows disclaimer.
- Accepted users go to onboarding.
- Resetting app data shows disclaimer again.

---

### Task 5 — Three-question ritual onboarding

**Objective:** Make personalization feel like a ritual, not a survey.

**Files:**
- Create: `Views/OnboardingView.swift`
- Create: `Components/QuestionChip.swift`

**Questions:**

1. “What are you seeking clarity on?”
   - Love
   - Career
   - Self
   - Purpose
   - General

2. “What season are you in?”
   - New beginning
   - Big decision
   - Healing
   - Building momentum
   - Feeling stuck

3. “Choose your reading style.”
   - Gentle
   - Direct
   - Mysterious
   - Deep spiritual

**UX requirements:**

- Chip selection only; no typing.
- Skip CTA: “Skip — read my palm”.
- Defaults: `general`, `unknown`, `mysterious`.
- Haptic tap feedback optional.

**Acceptance criteria:**

- User can complete onboarding in under 10 seconds.
- Skip sends default answers.
- Continue navigates to palm capture.

---

### Task 6 — Photo capture, library import, and local image preprocessing

**Objective:** Get a palm image and prepare a small backend-safe JPEG.

**Files:**
- Create: `Views/PalmCaptureView.swift`
- Create: `Views/PalmReviewView.swift`
- Create: `Services/ImagePreprocessor.swift`
- Modify: `Info.plist`

**Info.plist:**

```xml
<key>NSCameraUsageDescription</key>
<string>PalmAura uses your camera to capture your palm for an entertainment-only reading.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>PalmAura uses your photo library to choose a palm photo for an entertainment-only reading.</string>
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>instagram-stories</string>
</array>
```

**Image preprocessing:**

- Resize longest edge to max 1024px.
- JPEG quality 0.7.
- Target raw JPEG <= 800KB.
- If still too large, retry with 768px and quality 0.6.
- Convert to base64 only after compression.

**Acceptance criteria:**

- Camera works on physical device.
- Library import works in simulator.
- Review screen shows selected image.
- Console/debug displays final JPEG byte size during development.
- No backend call yet.

---

### Task 7 — Fixture-driven result screen

**Objective:** Build the full reading UI before backend integration.

**Files:**
- Create: `Resources/fixture-reading.json`
- Create: `Views/ReadingResultView.swift`
- Create: `Components/DisclaimerFooter.swift` if not already created

**Result sections:**

1. Hero title
2. One-line summary
3. Aura/archetype badge
4. Horizontal share card previews
5. Long report cards:
   - Aura
   - Heart Line
   - Head Line
   - Life Line
   - Fate Line
   - Current Season
   - Guidance
   - Ritual
6. “Try another reading” CTA
7. Entertainment-only footer
8. Settings gear

**Style:**

- Modern mystical wellness aesthetic.
- Dark gradient, violet/gold accents.
- Serif display headings, readable body text.
- Haptic success on result appear.

**Acceptance criteria:**

- Result screen renders entirely from fixture JSON.
- All report sections are visible and scroll smoothly.
- No backend required to demo the app flow.

---

### Task 8 — Share cards and Instagram Stories path

**Objective:** Render beautiful 9:16 result cards and make sharing easy.

**Files:**
- Create: `Views/ShareCardView.swift`
- Create: `Views/ShareOptionsSheet.swift`
- Create: `Services/ShareCardRenderer.swift`
- Create: `Services/InstagramStorySharer.swift`

**Card spec:**

- Size: 1080x1920.
- Full-bleed gradient by theme.
- Large title, concise body.
- Subtle palm-line background illustration or simple procedural line pattern.
- Footer:
  - `BrandConfig.socialHandle`
  - `For entertainment only`
- Optional domain: `BrandConfig.domain`.

**Share CTAs:**

1. Save to Camera Roll
2. Share to Instagram Stories
3. Generic Share

**Instagram implementation:**

Use `UIPasteboard` with `com.instagram.sharedSticker.backgroundImage`, then open `instagram-stories://share?source_application=...`. If Instagram is unavailable, fall back to generic share.

**Acceptance criteria:**

- Preview cards render in app.
- Saved image is vertical and readable.
- Generic share works in simulator/device.
- Instagram path tested on physical device if Instagram installed.
- Share card includes watermark and entertainment-only footer.

---

### Task 9 — Mystical loading screen and local flow wiring

**Objective:** Make the AI wait feel intentional and magical.

**Files:**
- Create: `Views/LoadingReadingView.swift`
- Create: `Resources/mystical-loading-phrases.json`

**Phrases:**

- “Tracing your heart line…”
- “Listening to the mount of Venus…”
- “Reading the season around your hand…”
- “Aligning the lines of fate…”
- “Sensing your current season…”
- “Drawing on ancient palmistry…”
- “Channeling the symbols in your palm…”

**Behavior:**

- Cycle text every 1.5s.
- Show animated rings/palm silhouette.
- Minimum display duration: 8 seconds.
- Maximum wait before visible timeout/retry: ~30 seconds.
- For fixture mode, transition to fixture result after 8 seconds.

**Acceptance criteria:**

- Capture → review → loading → fixture result works locally.
- Loading never flashes instantly.

---

### Task 10 — Cloudflare Worker backend skeleton

**Objective:** Create backend with health endpoint and TypeScript setup.

**Files:**
- Create: `backend/package.json`
- Create: `backend/tsconfig.json`
- Create: `backend/wrangler.toml`
- Create: `backend/api/health.ts`
- Create: `backend/api/read.ts`

**Dependencies:**

```bash
npm install @anthropic-ai/sdk zod @upstash/redis
npm install -D typescript wrangler @cloudflare/workers-types
```

**Env vars:**

```bash
ANTHROPIC_API_KEY=
ANTHROPIC_MODEL=
# Cloudflare KV binding in wrangler.toml:
# RATE_LIMIT_KV
PUBLIC_APP_NAME=PalmAura
PUBLIC_APP_DOMAIN=palmaura.app
PUBLIC_SOCIAL_HANDLE=@PalmAuraApp
```

**Acceptance criteria:**

- `npm run typecheck` passes.
- `/api/health` returns `{ ok: true, version }`.

---

### Task 11 — Backend `/api/read` with schema, rate limit, model call, and non-palm rejection

**Objective:** Generate safe structured readings from palm images.

**Files:**
- Modify: `backend/api/read.ts`

**Implementation requirements:**

- Accept only POST.
- Validate request with Zod.
- Reject oversized base64 payloads.
- Rate limit by `deviceId`: 3/day.
- Call Anthropic with image + onboarding text.
- Use forced tool/schema output if supported by installed SDK/model.
- Validate model output shape before returning.
- If model returns `not_palm` or `bad_image`, return 200 with `status` so app can render a friendly retry screen.
- For upstream errors, return `{ error: 'server_error' }` with 502.

**Rate limit key:**

```text
palmaura:rl:{deviceId}:{YYYY-MM-DD}
```

**Critical no-storage requirements:**

- Do not write image to logs.
- Do not write image to Redis.
- Do not include image in error messages.
- Do not use request body logging middleware.

**Acceptance criteria:**

- `curl /api/read` with valid fixture returns `status: ok` or relevant status.
- Repeated calls over limit return 429.
- Non-palm test image returns `status: not_palm`, not a fake reading.
- Bad/dark palm returns `status: bad_image` or a low-confidence retry message.

---

### Task 12 — iOS API client and live backend wiring

**Objective:** Replace fixture flow with real backend response while keeping fixture fallback for local development.

**Files:**
- Create: `Services/ReadingAPIClient.swift`
- Modify: `AppConfig.swift`
- Modify: `Views/LoadingReadingView.swift`
- Modify: `Views/PalmReviewView.swift`

**Behavior:**

- Build `PalmReadingRequest` with UUID, IDFV, app version, locale, base64 image, onboarding.
- POST to `/api/read`.
- Handle:
  - 200 `status: ok` → result screen
  - 200 `status: not_palm` → friendly retake screen
  - 200 `status: bad_image` → friendly retake screen
  - 429 → daily limit screen
  - network/server → retry screen
- Persist last successful reading only as JSON in UserDefaults for settings/last-reading CTA. Do not store palm image.

**Acceptance criteria:**

- Real end-to-end reading works in simulator using library image.
- Real end-to-end reading works on physical iPhone using camera.
- Rate limit screen is user-friendly.
- Last reading can be reopened without image.

---

### Task 13 — Optional analytics and crash reporting

**Objective:** Track the funnel without blocking the build if keys are missing.

**Files:**
- Create: `Services/Analytics.swift`
- Modify: `PalmAuraApp.swift`

**Events:**

- `app_opened`
- `disclaimer_accepted`
- `onboarding_completed`
- `onboarding_skipped`
- `photo_captured`
- `photo_chosen`
- `reading_requested`
- `reading_completed`
- `reading_rejected_not_palm`
- `reading_rejected_bad_image`
- `reading_failed`
- `share_card_tapped`
- `share_completed`

**Requirements:**

- Do not send image data to analytics.
- Do not send generated full reading text unless explicitly decided later.
- Use IDFV as anonymous distinct ID if PostHog is enabled.
- If PostHog/Sentry keys are blank, methods no-op.

**Acceptance criteria:**

- App builds with blank analytics keys.
- If keys are configured, events appear in PostHog Live View.
- Test crash appears in Sentry if configured.

---

### Task 14 — Settings screen

**Objective:** Provide privacy/legal links and last-reading access.

**Files:**
- Create: `Views/SettingsView.swift`
- Create: `Services/LastReadingStore.swift`

**Settings includes:**

- Last reading, if present.
- Privacy Policy link.
- Terms link.
- Clear last reading.
- App version.
- Entertainment-only footer.

**Acceptance criteria:**

- Links open in Safari.
- Clear last reading removes local JSON.
- No stored image exists.

---

### Task 15 — Landing, privacy, terms, AASA

**Objective:** Provide App Store support URLs and modern landing page.

**Files:**
- Create/modify: `landing/index.html`
- Create: `landing/privacy.html`
- Create: `landing/terms.html`
- Create: `landing/apple-app-site-association`

**Landing page sections:**

- Hero: “Mystical palm readings for self-reflection.”
- CTA: TestFlight/App Store placeholder.
- How it works:
  1. Scan your palm
  2. Choose your focus
  3. Receive your symbolic reading
  4. Share your aura card
- Entertainment-only disclaimer banner.
- Privacy summary.
- Footer links.

**Privacy policy must say:**

- PalmAura does not store palm photos on its servers.
- Images are sent to an AI provider for real-time processing.
- Device IDFV is used for rate limiting and optionally analytics.
- Usage events may be collected.
- No account required.
- No name/email/location/contact data collected by default.
- Contact email for privacy requests.

**Terms must say:**

- Entertainment and self-reflection only.
- No medical, legal, financial, psychological, or life-critical advice.
- No guaranteed outcomes.
- Do not rely on readings for important decisions.

**AASA placeholder:**

Use actual Team ID/bundle ID when available.

**Acceptance criteria:**

- All pages load on mobile.
- Privacy and terms URLs are ready for App Store Connect.
- AASA returns JSON with correct content type when deployed.

---

### Task 16 — App Store copy and review checklist

**Objective:** Prepare defensive App Store submission materials.

**Files:**
- Create: `docs/app-store-review-checklist.md`

**App metadata:**

- Category: Entertainment
- Secondary: Lifestyle
- Age rating: likely 12+
- Price: Free

**Description first lines:**

```text
PalmAura offers symbolic palm readings for entertainment and self-reflection.
It is not medical, legal, financial, psychological, or life-critical advice.
```

**Long description:**

```text
✨ Scan your palm with your camera
✨ Choose what you're seeking clarity on
✨ Receive a mystical reading shaped by your palm and your moment
✨ Share your aura card to Instagram or TikTok

PalmAura is designed as gentle entertainment. Readings are symbolic — they do not predict the future, diagnose health, or guarantee outcomes. Use PalmAura as a tool for reflection, not a substitute for professional advice.
```

**Keywords:**

```text
palm, palmistry, aura, mystical, horoscope, tarot, astrology, fortune, reading, spiritual
```

**Pre-submission grep:**

```bash
rg -i "diagnos|disease|illness|fertility|pregnan|death|will die|lifespan" ios/ landing/ backend/
rg -i "guarantee|will become|destined to|fate is fixed|predict the future" ios/ landing/ backend/
rg -i "medical advice|legal advice|financial advice|psychological advice" ios/ landing/ backend/
```

Expected: matches only in guardrails/disclaimers explaining what the app does not do.

**Acceptance criteria:**

- Screenshots: disclaimer, onboarding, photo capture, result, share card.
- Privacy questionnaire aligns with actual behavior.
- No API keys in app bundle.
- Internal TestFlight uploaded.

---

## Suggested Execution Order

### Day 1 — fixture-driven app

1. Task 1: repo skeleton
2. Task 2: Xcode project + brand config
3. Task 3: models/tests
4. Task 4: disclaimer gate
5. Task 5: onboarding
6. Task 6: photo capture/review/preprocess
7. Task 7: fixture result screen
8. Task 8: share cards
9. Task 9: loading screen

**End of Day 1 demo:** App can run fully offline from photo → loading → fixture reading → share card.

### Day 2 — backend + ship

1. Task 10: Cloudflare Worker backend skeleton
2. Task 11: `/api/read` live model + rate limit
3. Task 12: iOS live backend wiring
4. Task 13: analytics/Sentry optional hooks
5. Task 14: settings
6. Task 15: landing/privacy/terms
7. Task 16: App Store/TestFlight prep

**End of Day 2 demo:** Internal TestFlight candidate can generate real readings and share real cards.

---

## Recovery Plan

| Blocker | Fallback |
|---|---|
| Instagram Stories deep link fails | Ship Save to Camera Roll + generic Share. Add IG direct share in v1.1. |
| Anthropic model/schema/tool use issues | Return strict JSON via text and parse/validate, or switch provider behind `generateReading()`. |
| Cloudflare Worker Anthropic SDK/runtime incompatibility | Use direct Anthropic Messages API `fetch` from the Worker. Keep same API contract. |
| Images too large | Drop to 768px longest edge and JPEG quality 0.6. |
| App Store concern about fortune telling | Strengthen entertainment-only framing, modernize wellness copy, add non-palm rejection screenshots if needed. |
| Backend latency high | Keep 8s min loading but cap at 30s; reduce image size; shorten output tokens. |

---

## Definition of Done

The MVP is done when:

1. Fresh install shows forced entertainment-only disclaimer.
2. User can answer or skip 3 onboarding questions.
3. User can take or select a palm photo.
4. App downsizes/compresses image locally.
5. Loading state lasts at least 8 seconds and feels polished.
6. Backend returns `ok`, `not_palm`, or `bad_image` deterministically.
7. Non-palm images do not receive fake readings.
8. Result screen renders a mystical long report.
9. App renders 3 vertical share cards.
10. User can save/share at least one card.
11. Every card includes watermark and entertainment-only footer.
12. PalmAura does not store palm images.
13. Rate limit blocks more than 3 readings/day/device.
14. Landing/privacy/terms pages are live.
15. PostHog/Sentry are either working or cleanly no-op.
16. No model keys are in the iOS app.
17. App Store risky-claim grep checks pass.
18. Internal TestFlight build is live or ready to submit.

---

## Immediate Next Step

Start Task 1 once the local repo path and manual Xcode project location are known. If Bernard has not created the Xcode project yet, do Task 1 first, then pause for manual Xcode creation under `ios/PalmAura/`.
