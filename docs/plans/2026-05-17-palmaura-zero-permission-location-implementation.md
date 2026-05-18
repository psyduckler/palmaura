# PalmAura Zero-Permission Location Personalization Implementation Plan

> **For Hermes:** Implement Path A from the Opus/Gemini review. Do not add CoreLocation, GPS permission prompts, background location, latitude/longitude fields, or Info.plist location usage strings.

**Goal:** Add place/time personalization to PalmAura readings without creating an iOS permission prompt or conversion cliff.

**Architecture:** The iOS app sends only zero-permission device context (`TimeZone.current.identifier`, `Locale.current.region?.identifier`) and an optional user-entered location override. The Cloudflare Worker reads coarse IP geo from `request.cf` and combines it with the client context when building the reading prompt. Onboarding shows an optional editable location field, passively prefilled/displayed from `/api/edge-context` if it returns quickly, but the screen never blocks on that network call.

**Tech Stack:** SwiftUI, UserDefaults/Codable, URLSession, Cloudflare Workers `request.cf`, Zod, XcodeGen.

---

## Final decision

Use **zero-permission location personalization**.

Rejected for v0:

- `CoreLocation`
- `requestWhenInUseAuthorization()`
- “Allow Once” system prompt
- reverse geocoding
- GPS coordinates
- background location

Why: a palm-reading app asking for GPS has bad vibes. IP city + timezone is exactly enough for “local timing/place atmosphere,” and the user can override it manually.

---

## Data contract

Extend `ReadingPersonalization` with:

```swift
var timeZoneIdentifier: String?
var localeRegionCode: String?
var locationOverride: String?
```

Backend Zod accepts the same optional fields.

Precedence in the backend prompt:

1. `locationOverride` if user typed one.
2. Cloudflare edge geo from `request.cf.city/region/country`.
3. Client `localeRegionCode` + `timeZoneIdentifier`.
4. No location context.

---

## UX

### Onboarding

Add an optional fourth section:

```text
IV. FOR PLACE & SEASON
Where are you located?
[ Austin, TX __________________ ]
Optional. Used only for local timing and atmosphere.
```

Behavior:

- On appear, fire a non-blocking `/api/edge-context` request.
- If it returns within ~1.5s, show/fill the placeholder as `Auto · Austin, TX`.
- If it fails or is slow, show no detected text and continue normally.
- User can type `Tokyo`, `Brooklyn`, `Austin, TX`, etc.
- Empty field means “use automatic network/timezone hints.”

### Settings

Add a read-only summary row under `PERSONALIZATION`:

- `Location — Tokyo` when override exists.
- `Location — Auto · America/Chicago` when no override exists.

Existing `Edit profile` opens `OnboardingView`, so that is the v0 edit path. No separate sheet.

---

## Backend prompt rule

Add location context block to `buildUserPrompt`:

```text
Location context:
- Place hint: Austin, Texas, US
- Timezone: America/Chicago
- Source: network place hint
- Rule: use only for local season, time-of-day, and place atmosphere. Never claim it improves palm-line detection. Never imply continuous tracking.
```

Also update system prompt specificity rules so location can only support atmosphere/timing, not palm analysis.

---

## Tasks

### Task 1 — Update Swift model + encoding test

Files:

- `ios/PalmAura/PalmAura/Models/OnboardingAnswers.swift`
- `ios/PalmAura/PalmAuraTests/ContractEncodingTests.swift`

Acceptance:

- `timeZoneIdentifier`, `localeRegionCode`, and `locationOverride` encode under `onboarding.personalization`.
- `withoutQuestion` preserves the location fields.
- Empty profile logic treats location as optional but saved if present.

### Task 2 — Add passive edge context client

Files:

- Create `ios/PalmAura/PalmAura/Services/EdgeContextService.swift`

Acceptance:

- Fetches `GET /api/edge-context`.
- Returns optional city/region/country/timezone.
- Has a 1.5s timeout helper for onboarding use.
- Failure returns nil in the UI path.

### Task 3 — Add onboarding location field

Files:

- `ios/PalmAura/PalmAura/Views/OnboardingView.swift`

Acceptance:

- Adds optional Section IV.
- Does not block Save Profile.
- Saves `locationOverride` only if non-empty.
- Saves current `TimeZone.current.identifier` and `Locale.current.region?.identifier`.

### Task 4 — Add settings summary

Files:

- `ios/PalmAura/PalmAura/Views/SettingsView.swift`

Acceptance:

- Shows `Location` row.
- Reset Profile clears override/device context.
- Clear Reading History does not clear location.

### Task 5 — Ensure every reading sends fresh device context

Files:

- `ios/PalmAura/PalmAura/Views/ReadingQuestionView.swift`

Acceptance:

- `buildAnswers()` refreshes `timeZoneIdentifier` and `localeRegionCode` right before capture.
- The per-reading question still does not persist to profile.

### Task 6 — Backend edge geo + prompt

Files:

- `backend/src/index.ts`

Acceptance:

- `GET /api/edge-context` returns `{ city, region, country, timezone }` where available.
- `/api/read` passes edge context into prompt generation.
- Prompt uses override > edge geo > client locale/timezone.
- Prompt explicitly bans palm-line accuracy claims from location.

### Task 7 — Verify and package

Commands:

```bash
cd /Users/psy/projects/palm-aura/backend
npm run typecheck
npm run deploy
curl -fsS https://palmaura-api.psyduckler.workers.dev/api/health
curl -fsS https://palmaura-api.psyduckler.workers.dev/api/edge-context

cd /Users/psy/projects/palm-aura/ios/PalmAura
xcodegen generate
xcodebuild -project PalmAura.xcodeproj -scheme PalmAura -destination 'platform=iOS Simulator,name=iPhone 17' test
xcodebuild -project PalmAura.xcodeproj -scheme PalmAura -destination 'generic/platform=iOS' build CODE_SIGNING_ALLOWED=NO
```

Package clean Xcode project zip excluding `.git`, `node_modules`, `.wrangler`, DerivedData/build outputs, and transient user state.

---

## Acceptance criteria

- No iOS location permission prompt.
- No `CoreLocation` usage.
- Onboarding has optional editable place field.
- Backend uses Cloudflare edge geo and client timezone/region for prompt context.
- User override wins when provided.
- Backend deployed and smoke-tested.
- iOS simulator tests and generic device build pass.
- Clean Xcode project zip is attached for review.
