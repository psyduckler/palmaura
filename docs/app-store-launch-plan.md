# PalmAura App Store Launch Plan

Single source of truth for the App Store Connect submission. Pair this with
`docs/app-store-review-checklist.md` (the high-level positioning checklist) and
`docs/phone-testflight-handoff.md` (the build / signing / TestFlight path).

This document is intentionally written so you can keep it open in one window
and copy-paste straight into App Store Connect. Every field below has its
character limit annotated; the copy is pre-trimmed to fit.

---

## 1. App Information

Settings ▸ App Information in App Store Connect.

| Field | Value |
|-------|-------|
| **Name** (30 char max) | `PalmAura` |
| **Subtitle** (30 char max) | `Palm reading for entertainment` (30) |
| **Primary Category** | Entertainment |
| **Secondary Category** | Lifestyle |
| **Bundle ID** | `com.zonted.palmaura` |
| **SKU** | `palmaura-ios-001` |
| **Content Rights** | Does not contain, show, or access third-party content |

### Privacy Policy URL

```
https://palmaura.app/privacy.html
```

Live and reachable. Verify before submission with `curl -I https://palmaura.app/privacy.html`.

### Marketing URL (optional)

```
https://palmaura.app
```

### Support URL

```
https://palmaura.app/support.html
```

If `support.html` does not yet exist, point Support URL at `https://palmaura.app` and add a `mailto:hello@palmaura.app` link there. Apple rejects submissions whose Support URL 404s.

---

## 2. Pricing & Availability

| Field | Value |
|-------|-------|
| **Price** | Free (Tier 0) |
| **Availability** | All territories |
| **App Store Distribution** | Available on the App Store |
| **Educational Discount** | Off |

---

## 3. Version Information (this submission)

App Store Connect ▸ App Store ▸ iOS App ▸ 0.1.0 (or current `MARKETING_VERSION`).

### Promotional Text (170 char max — editable post-release without review)

```
Open your palm. Receive a symbolic reading shaped by the moon, the season, and the question on your mind. For entertainment and self-reflection only.
```

(149 chars.)

### Description (4000 char max)

Paste exactly as written. Blank lines are intentional — App Store Connect renders them as paragraph breaks.

```
Symbolic palm readings — for entertainment only.

Open your palm. PalmAura translates the lines you carry into a calm, narrative reading shaped by the moment you ask: the moon overhead, the season around you, and the one question on your mind.

This is not divination. PalmAura is a journaling and self-reflection tool framed in the symbolic language of palmistry — a way to slow down and look at what you're carrying.

WHAT TO EXPECT

• Ask one question. Choose a focus (heart, work, season, self) and bring the one thing you want the palm to look into.

• Photograph your open palm. Fingers spread, soft even light. No account, no sign-up.

• Receive a private reading. Heart line, head line, life line, fate line — plus a palm-map keepsake and a personal archetype.

• Keep or share. Save the reading to your private library, or send a beautiful share card to a friend. Your raw question stays on-device.

PRIVATE BY DESIGN

PalmAura does not require an account. We do not sell your data. We do not track you across other apps or websites. Your palm photos and the readings derived from them stay associated with your device.

FOR ENTERTAINMENT ONLY

PalmAura readings are symbolic entertainment and self-reflection only. They are not medical, legal, financial, psychological, or life-critical advice. If you need professional help, please reach out to a qualified human.

QUESTIONS

Support: hello@palmaura.app
Web: palmaura.app
```

(Approx. 1,540 chars. Plenty of headroom under the 4,000 cap.)

### Keywords (100 char max — comma-separated, no spaces after commas)

```
palmistry,fortune,astrology,zodiac,mystical,oracle,horoscope,divination,tarot,spiritual,reading,aura
```

(Exactly 100 chars. Don't repeat "palm" — it's already in the app name and counts there.)

### What's New in This Version (4000 char max)

For the **0.1.0 launch submission**:

```
Welcome to PalmAura — symbolic palm readings for entertainment and self-reflection.

This first release brings:
• Private, account-free palm readings shaped by your question and the current season
• A palm-map keepsake of your reading
• A library of your past readings
• Beautiful 9:16 share cards you can save or send

We'd love your feedback: hello@palmaura.app.
```

For **subsequent maintenance releases**, follow this template:

```
• [user-facing change one]
• [user-facing change two]
• Stability and performance improvements
```

Skip "Stability and performance improvements" if you have nothing real to say there — Apple is increasingly rejecting filler release notes.

---

## 4. App Privacy ("Nutrition Label")

App Store Connect ▸ App Privacy. This is the most error-prone part of submission. Match the answers below exactly to what the app actually does as of 0.1.0.

### Data collection summary

> **Do you or your third-party partners collect data from this app?**
> **Yes.**

### Data types collected

| Data type | Linked to user? | Used for tracking? | Purposes |
|---|---|---|---|
| **Device ID** | No (not linked) | No | Analytics, App Functionality (rate limiting) |
| **Product Interaction** (usage data) | No (not linked) | No | Analytics |
| **Crash Data** | No (not linked) | No | App Functionality |
| **Performance Data** | No (not linked) | No | App Functionality |
| **Photos** (palm image) | No (not linked) | No | App Functionality |

### Data types NOT collected (declare these as "No")

- Contact Info (name, email, phone, address, other user contact info)
- Health & Fitness
- Financial Info
- Location (precise or coarse) — PalmAura asks for an optional textual region but never device GPS
- Sensitive Info
- Contacts
- User Content other than photos
- Search History
- Browsing History
- Identifiers other than Device ID
- Purchases
- Audio Data
- Customer Support
- Other Data Types

### Critical sub-questions

- **Photos** ▸ "Are photos linked to the user's identity?" → **No.** PalmAura has no user identity. Photos are bound to a device-generated ID only.
- **Photos** ▸ "Are photos used for tracking?" → **No.**
- **Photos** ▸ "Used for ad targeting?" → **No.**
- **Photos** ▸ "Used for product personalization?" → **No** for 0.1.0. (Reconsider if you ever pin readings to a saved profile vector.)
- **Tracking** declaration → **No.** PalmAura does not call `ATTrackingManager.requestTrackingAuthorization` and ships no IDFA-using SDKs.

### Privacy summary preview

After filling the questionnaire, App Store Connect will produce a preview. It should read:

> **Data Not Linked to You**
> The following data may be collected but it is not linked to your identity:
> Identifiers · Usage Data · Diagnostics · User Content

If anything appears under "Data Linked to You", **stop and recheck** — that would mean we accidentally said something is linked to identity, which isn't true for 0.1.0.

---

## 5. Age Rating Questionnaire

App Store Connect ▸ Age Rating. **Expected outcome: 12+.** Palm reading / mystical content puts us at 12+ because of the "Frequent/Intense Mature/Suggestive Themes ▸ Horoscopes/Tarot" category, even though the rest of the questionnaire is clean.

Answer the questionnaire as follows:

| Category | Answer |
|---|---|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Prolonged Graphic or Sadistic Realistic Violence | None |
| Profanity or Crude Humor | None |
| Mature/Suggestive Themes | None |
| **Horoscopes/Tarot** | **Infrequent/Mild** |
| Simulated Gambling | None |
| Sexual Content and Nudity | None |
| Graphic Sexual Content and Nudity | None |
| Alcohol, Tobacco, or Drug Use or References | None |
| Medical/Treatment Information | None |
| Unrestricted Web Access | No |
| Gambling and Contests | No |

> **Important**: do **not** answer "Yes" to *Medical/Treatment Information*. PalmAura explicitly disclaims medical, legal, financial, and psychological advice in-app and in store copy. The "Horoscopes/Tarot" category is where palmistry lives and is enough to trigger 12+.

---

## 6. Screenshots

App Store Connect ▸ App Store ▸ Screenshots.

### Required device set

For new apps as of 2026, Apple accepts a **single 6.7" iPhone screenshot set** that scales down to all smaller devices. Capture only this size unless you already have iPad screenshots ready (we don't ship an iPad-optimized layout).

| Device | Resolution (portrait) |
|---|---|
| 6.7" iPhone (iPhone 17 Pro Max / 16 Pro Max / 15 Pro Max / 14 Pro Max) | 1290 × 2796 |

Upload 3–10 screenshots. **Order matters** — the first three appear in search results. Lead with the most aspirational, not the most utilitarian.

### Capture instructions

```bash
# Boot the right simulator
xcrun simctl boot "iPhone 17 Pro Max"
open -a Simulator

# Build & run the app
/Applications/Xcode.app/Contents/Developer/usr/bin/xcodebuild \
  -scheme PalmAura \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -configuration Release build
xcrun simctl install booted /path/to/PalmAura.app
xcrun simctl launch booted com.zonted.palmaura

# Capture: drive the app to each hero screen, then snap
xcrun simctl io booted screenshot ~/Desktop/palmaura-screen-01-home.png
# (repeat for each screen)
```

If your Xcode is at a different path, swap accordingly. The simulator must be in **light/dark parity with your design** — PalmAura is dark-mode-only, so no setting change needed.

### Hero screen list (recommended order)

| # | Screen | Suggested caption (under 24 char) | Why |
|---|---|---|---|
| 1 | Home / Constellation hero with "What answer are you seeking?" headline | `Ask one question.` | Sets emotional tone in search results |
| 2 | Reading question step (chip selection + question field) | `Bring what you carry.` | Shows the journaling angle |
| 3 | Reading reveal — first ceremony panel ("The answer begins") | `Receive your answer.` | The product's central moment |
| 4 | Palm map (PalmCanvasView with aura glow on user's photo) | `A keepsake palm map.` | Visual differentiation from text-only competitors |
| 5 | Full report — chapters scrolled to Heart Line | `Heart, head, life, fate.` | Communicates depth |
| 6 | Share sheet — ShareCardView preview | `Share. Privately.` | Shows the new share asset |
| 7 | Settings — Library of readings | `Your private library.` | Reassures power users |

Caption text goes in your screenshot artwork (Figma / Sketch overlay), not in App Store Connect — App Store Connect does not have a per-screenshot caption field. Captions on the image itself drive ~2x more impression-to-tap.

### Caption design rules

- Use Cormorant Garamond (the in-app display font) for caption text — keeps brand continuity.
- Caption colour: `#F3DDA8` (gold cream) over the dark sky background that already exists in the screen.
- Caption position: bottom 12% of the screen, never overlapping the user's palm or the primary CTA.
- Caption text: under 24 characters per line, maximum 2 lines.

### Fixture data for screenshots

Set `AppConfig.useFixtureReadings = true` (already wired) before capturing — guarantees the reading text is the curated fixture (`Resources/fixture-reading.json`) instead of whatever the live API produces. This makes captures repeatable across releases.

After capturing, set `useFixtureReadings = false` again and **do not commit screenshots taken with the fixture flag flipped to anything else.**

### Screenshot reviewer-safety pass

Before uploading, scan each screenshot for:

- [ ] No real user data (emails, names, locations)
- [ ] No in-progress error states or empty data
- [ ] No internal/debug glyphs
- [ ] Reading title and one-line summary are the fixture's wording (calm, non-claiming)
- [ ] Disclaimer footer is visible on at least one screenshot (Apple specifically rewards this for entertainment-disclaim apps)

---

## 7. App Preview (Video) — optional

Skip for 0.1.0. Adding an App Preview video is the highest-impact post-launch growth lever, but it requires a 15–30s portrait video at 1080×1920 with the same fixture-data discipline as screenshots. Plan for a 0.2.x release.

---

## 8. App Review Information

App Store Connect ▸ App Review Information.

### Sign-in required?

**No.** PalmAura ships with no account system. Tell the reviewer this explicitly in Notes (below) so they don't expect a login screen.

### Demo account

Leave blank.

### Contact info

| Field | Value |
|---|---|
| **First name** | Bernard |
| **Last name** | Huang |
| **Phone number** | _(your contact phone)_ |
| **Email address** | hello@palmaura.app |

### Notes for the Apple reviewer

Paste exactly. This is the field where palm-reading apps live or die — be explicit about the entertainment framing, the photo flow, and the rate limit.

```
PalmAura is a symbolic palm-reading app framed entirely as entertainment and self-reflection. The app does not provide medical, legal, financial, or psychological advice and disclaims this in three places (onboarding disclaimer screen, full report footer, and share card footer).

How to test:
1. Launch the app. Tap "I understand — begin" on the disclaimer.
2. Complete the 3 onboarding questions (birthday, energy, dominant hand). Use any values — they only personalize copy.
3. Tap "Ask the Palm" on the home screen.
4. Choose a focus chip (e.g. "Heart") and optionally type a question.
5. Tap "Take Photo" — point the simulator camera at the included sample palm image, or use any palm-like photo from the simulator's photo library via the "Choose from Library" option.
6. The app validates the image. A clear palm produces a full reading in ~8–15 seconds. A non-palm photo produces a friendly rejection ("The oracle needs a clearer palm…") rather than a fake reading.
7. The reading view includes 7 chapters (heart/head/life/fate lines, current season, guidance, ritual) and a palm-map keepsake. Tap "Share this reading" to see the share card and Save-to-Photos flow.
8. Settings ▸ Library of readings shows the on-device history (saved locally only — never uploaded).

Privacy: PalmAura does not require an account, does not sell data, does not track across apps, and does not request location or contacts. The only network call is a single POST to https://palmaura.app/api/read which sends the palm image to our Cloudflare Worker for processing. Photos are not retained server-side after the reading is generated.

Rate limit: 3 readings per device per day. After the third, the API returns a friendly "rest" message — please test this if needed.

Disclaimer placement: see the disclaimer screen (first launch), the entertainment disclaimer footer at the bottom of every reading, and the "FOR ENTERTAINMENT ONLY" line on every share card.
```

### Attachment

Optional: attach a 5–10 second screen recording of the happy-path flow if you have one. Not required.

---

## 9. Build Selection

App Store Connect ▸ App Store ▸ Build.

Select the build uploaded via Xcode Organizer (or `xcodebuild -archivePath ...` + Transporter). Match:

- **Marketing Version**: `0.1.0` (from `project.yml ▸ settings.base.MARKETING_VERSION`)
- **Build Number**: monotonically increasing each TestFlight upload. If 0.1.0 build 1 was already used for TestFlight, use build 2 for App Store submission.
- **Export Compliance**: `ITSAppUsesNonExemptEncryption = false` is in the Info.plist (added in PR #16). This auto-passes the export-compliance step.

---

## 10. Final Submission Checklist

Run before tapping **Submit for Review**.

### Blocking

- [ ] Required Info.plist privacy/export-compliance keys present:
  - [ ] `NSCameraUsageDescription`
  - [ ] `NSPhotoLibraryUsageDescription`
  - [ ] `NSPhotoLibraryAddUsageDescription`
  - [ ] `ITSAppUsesNonExemptEncryption = false`
- [ ] Privacy policy URL returns 200: `curl -I https://palmaura.app/privacy.html`
- [ ] Support URL returns 200
- [ ] App Privacy questionnaire submitted and matches Section 4 above
- [ ] Age Rating questionnaire submitted with 12+ outcome
- [ ] All required screenshot slots filled (minimum 3 at 6.7" iPhone size)
- [ ] App Review Notes (Section 8) pasted in
- [ ] Build archived, uploaded, processed (green check next to build in App Store Connect)
- [ ] No `TODO` / `FIXME` / "DEBUG" strings visible in any screenshot

### Risk scan (run from repo root before archiving)

```bash
rg -i "diagnos|disease|illness|fertility|pregnan|death|will die|lifespan" ios/ landing/ backend/
rg -i "guarantee|will become|destined to|fate is fixed|predict the future" ios/ landing/ backend/
rg -i "medical advice|legal advice|financial advice|psychological advice" ios/ landing/ backend/
```

Expected: matches **only** in `copy-guardrails.md`, `BrandConfig.entertainmentDisclaimer`, and similar disclaimer surfaces. Any match in user-facing copy is a blocker — Apple will reject.

### Pre-flight build sanity

- [ ] `xcodegen generate` produces no diff against committed `Info.plist` / `project.pbxproj`
- [ ] `xcodebuild -scheme PalmAura -destination 'platform=iOS Simulator,name=iPhone 17' build` succeeds with no warnings
- [ ] `xcodebuild test -scheme PalmAura -destination 'platform=iOS Simulator,name=iPhone 17'` passes
- [ ] Manual smoke on simulator: complete one happy-path reading end-to-end, then one rejected-image flow
- [ ] Manual smoke on physical device (TestFlight build): same two flows, plus the Save-to-Photos permission prompt

### Nice-to-have

- [ ] At least one internal TestFlight tester has used the app on their own device within the last 7 days
- [ ] Latest 25 analytics events reviewed for any `reading_failed` / `share_save_failed` clusters
- [ ] Cloudflare Worker rate-limit and rejection flows verified live (see `phone-testflight-handoff.md`)

---

## 11. Post-submission Watch

Expected review time: 24–48 hours for a new app in the Entertainment / Lifestyle space. Palm-reading and astrology apps are higher-scrutiny — budget for one round of review feedback.

### Common rejection reasons for apps in this category

| Rejection reason | How we mitigate | Where to look |
|---|---|---|
| "Implies medical/health advice" | Triple disclaimer + copy guardrails | `BrandConfig.entertainmentDisclaimer`, onboarding disclaimer screen, share card footer |
| "Misleading or inaccurate" | "Symbolic" / "for entertainment" framing on every reading | `ReadingResultView`, `ShareCardView`, store description |
| "Privacy practices don't match declaration" | App Privacy nutrition matches actual data flow | Section 4 above + `phone-testflight-handoff.md` |
| "Crashes or significant bugs" | xcodebuild + smoke tests pass before archive | Section 10 build sanity |
| "Insufficient functionality" | 7 reading chapters + palm map + share + library — well above "minimum viable" | Manual smoke test |

If rejected, **do not** argue with App Review on first contact. Read the rejection notice carefully, address the specific finding, attach a concise "what changed" note, and resubmit. Most palm-reading-app rejections are about disclaimer placement and are solved in one re-submission.

---

## 12. Day-of-Launch Checklist

- [ ] App is marked "Available" in App Store Connect (not in Hold for Developer Release)
- [ ] Cloudflare Worker rate limit dashboard open in another tab; watch for unexpected spikes
- [ ] Analytics events flowing (run app from a device that's never opened it, confirm `app_opened` fires)
- [ ] `palmaura.app` homepage shows the App Store badge / link
- [ ] `palmaura.app/privacy.html` reachable
- [ ] `hello@palmaura.app` inbox checked
- [ ] First 24h: respond to any 1-star review within 2 hours (Apple weights early reviews heavily)

---

## Appendix A: Character counts cheat sheet

| Field | Limit | Current copy length |
|---|---|---|
| Name | 30 | 8 (`PalmAura`) |
| Subtitle | 30 | 30 (`Palm reading for entertainment`) |
| Promotional Text | 170 | 149 |
| Description | 4000 | ~1,540 |
| What's New | 4000 | ~340 |
| Keywords | 100 | 100 |

## Appendix B: Where copy lives in the repo

| Surface | Source of truth |
|---|---|
| In-app disclaimer | `BrandConfig.entertainmentDisclaimer` |
| In-app short disclaimer | `BrandConfig.shortDisclaimer` |
| Share card footer | `Components/ShareCardView.swift` |
| App description / keywords / subtitle | **This document.** App Store Connect is the publication surface, not the source of truth. |

When updating store copy:

1. Edit this document first.
2. Get it reviewed.
3. Paste into App Store Connect as the final step.

Never edit App Store Connect copy without updating this document — it desyncs fast and you lose history.
