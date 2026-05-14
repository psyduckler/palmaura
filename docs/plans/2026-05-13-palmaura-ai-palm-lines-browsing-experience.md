# PalmAura AI Palm Lines + Browsing Experience Implementation Plan

> **For Hermes:** Use `subagent-driven-development` to implement this plan task-by-task.

**Goal:** Ship a PalmAura v1 where the user's real palm photo becomes the core reading surface: AI-traced palm lines ignite on the actual hand, the reveal stays punchy, the reading is browsed through an interactive Palm Map, and sharing is video-first.

**Architecture:** Keep Opus's strongest idea — `PalmLineSet` geometry decoupled from `PalmCanvasView` rendering — but move line coordinate detection to the existing AI backend instead of using Vision joint-offset heuristics. The iOS app stores the photo locally, renders backend-returned line coordinates, and falls back to soft mystical glow defaults if coordinates are absent or low-confidence.

**Tech Stack:** SwiftUI, UIKit image persistence, Swift Codable, `ImageRenderer`, AVFoundation MP4 writer, Cloudflare Workers TypeScript, Zod, Anthropic tool-use vision response, KV rate limiting.

---

## 1. Executive decision

Ship the feature, but do **not** ship Opus's `VNDetectHumanHandPoseRequest` offset math as the primary detector.

Gemini's critique is correct: Apple Vision hand-pose detects joints, not palm creases. Thin hard lines placed by MCP/wrist heuristics will frequently miss the actual creases and create the exact uncanny-valley failure the product cannot afford.

### Final v1 strategy

1. **Backend AI coordinates are the source of truth.** Extend `/api/read` to return `palmLines` when `status = ok`.
2. **Client stores the user's photo locally only.** Use Opus's `PalmPhotoStore` approach, excluding iCloud backup and stripping EXIF via re-encoding.
3. **Renderer is source-agnostic.** `PalmCanvasView` draws any `PalmLineSet`, regardless of source.
4. **Fallback is soft glow, not fake precision.** If backend returns no/invalid/low-confidence coordinates, render broad blurred aura bands or very low-opacity canonical defaults, never crisp fake line tracing.
5. **Reveal is condensed.** Do one Palm Ignition step where all four lines draw on over ~3 seconds; keep line details inside `PalmMapView`.
6. **Reading browsing becomes the product.** Full report stays available, but `PalmMapView` is the primary post-reveal reading surface.
7. **Sharing is video-first.** Continue/extend the existing MP4 renderer so the palm map card animates line ignition + aura pulse; static image remains fallback.

---

## 2. Audit of Opus plan/code

### Keep

- `PalmLineSet` / `PalmLinePath` normalized coordinate model.
- `PalmLine` enum and `PalmReadingResponse.reportText(for:)` lookup.
- `ReadingBundle` as the downstream navigation carrier.
- `PalmPhotoStore` local-only storage model:
  - app support directory;
  - EXIF stripped by re-encoding;
  - excluded from iCloud backup;
  - capped retention;
  - user deletion in Settings.
- `PalmCanvasView` as the reusable composition primitive.
- `PalmMapView` as the explorable surface.
- `LineRevealPanel` patterns only as components for Palm Map/details, not as four separate reveal steps.
- `ShareCardFormat.palmMap` concept, but implemented through `ReadingBundle.augmentedShareCards`, not backend-authored share cards.
- Tests for normalized coordinates, Codable roundtrip, and photo-store lifecycle.

### Change

- Replace `PalmLineDetector.swift` primary path with backend-returned `palmLines`.
- Do not require or block capture on Vision detection. Backend already validates palm vs non-palm.
- Do not add four separate line screens to the reveal. Use a single `PalmIgnitionPanel`.
- Treat `PalmMapView` as the place where users browse line-specific readings.
- Update privacy copy before TestFlight/public distribution because local photo retention is new.

### Drop/defer

- `#if DEBUG PalmLineCalibrationView` for Vision offsets — unnecessary for v1 if backend coordinates are primary.
- Long-press examine/zoom polish until after tap-to-read is stable.
- Snapshot test matrix across every aura color until after core contract tests pass.
- AI-detected 8 traditional lines. v1 remains heart/head/life/fate only.

---

## 3. Audit of Gemini critique

Gemini's three big points are directionally right:

1. **Accuracy risk:** correct. Thin lines from joint offsets will break trust.
2. **Reveal pacing:** correct. Nine taps turns a magic moment into chores.
3. **Video-first sharing:** correct. The project already has `ShareVideoRenderer`; extend it to palm-map animation rather than treating static images as the hero.

One nuance: backend AI line coordinates are not guaranteed perfect either, especially with Haiku. To control that risk, require the backend to return `confidence` and `source`, validate bounds client-side, and use soft glow fallback for low-confidence sets. The user experience should never imply medical/forensic precision.

---

## 4. Current repo state observed

Repo: `/Users/psy/projects/palm-aura`

Relevant current files:

- Backend Worker: `backend/src/index.ts`
  - Current response schema has reading text + 3 share cards.
  - No `palmLines` field yet.
  - Rate limit was previously `next <= 3`; now updated to `next <= 100` and deployed.
- iOS model: `ios/PalmAura/PalmAura/Models/PalmReadingResponse.swift`
  - No `palmLines` field yet.
  - `ShareCardFormat` currently `aura`, `archetype`, `thirty_day`.
- iOS reveal: `ios/PalmAura/PalmAura/Views/RevealSequenceView.swift`
  - Current first reveal is 5 steps: portal, summary, aura, archetype, share.
  - This is a good base; add one Palm Ignition step, not four line steps.
- iOS loading: `ios/PalmAura/PalmAura/Views/LoadingReadingView.swift`
  - Currently routes `PalmReadingResponse` only.
  - Must assemble a `ReadingBundle` after response and photo bind.
- iOS share: `ios/PalmAura/PalmAura/Services/ShareCardRenderer.swift`
  - Already has still image render + MP4 render from image.
  - Extend with palm-map composition and animated line render frames.
- iOS full report: `ios/PalmAura/PalmAura/Views/ReadingResultView.swift`
  - Text-only stacked report; keep as secondary fallback/report.

---

## 5. Product UX target

### First-time successful reading

1. **Portal opens** — title + one-line summary.
2. **Aura blooms** — aura color + report aura.
3. **Palm Ignition** — actual hand photo appears; all four AI-traced lines draw on over ~3 seconds; copy: `Your lines have been charted.`
4. **Archetype** — archetype + guidance.
5. **Share / Explore** — primary CTA: `Explore your palm map`; secondary: share/video; tertiary: full report.

Target: 5 steps max, with one strong palm-photo moment.

### Returning reading

1. Aura snapshot.
2. Palm map preview / Today's signal.
3. Share / Explore.

Target: 3 steps max.

### Palm Map browsing

- Full-screen palm photo with all four lines faintly visible.
- Tap line or chip: selected line glows, others dim, bottom sheet shows the matching reading section.
- Reading sections:
  - Heart → love/relationships/emotional life.
  - Head → mind/decisions/wisdom.
  - Life → vitality/rhythm/season.
  - Fate → money/career/purpose/direction.
- Include `Next line` cycle button.
- Include `Share this palm map` CTA in sheet/header.
- Keep full report accessible from toolbar.

### Share

- Add a fourth client-side card `palm_map`.
- Default share for palm map should be a 3-4 second looping MP4:
  - 1080×1920;
  - actual palm photo;
  - all lines draw on repeatedly or draw once with aura pulse;
  - title + one-line summary;
  - footer: `palmaura.app · @PalmAuraApp · for entertainment only`.
- Static `UIImage` remains fallback if video render fails.

---

## 6. Backend contract

### Add model types in `backend/src/index.ts`

```ts
const PointSchema = z.object({
  x: z.number().min(0).max(1),
  y: z.number().min(0).max(1),
});

const PalmLinePathSchema = z.object({
  points: z.array(PointSchema).min(4).max(8),
  midpoint: PointSchema,
  confidence: z.number().min(0).max(1).default(0.7),
});

const PalmLineSetSchema = z.object({
  heart: PalmLinePathSchema,
  head: PalmLinePathSchema,
  life: PalmLinePathSchema,
  fate: PalmLinePathSchema,
  source: z.enum(['ai_detected', 'fallback']).default('ai_detected'),
  confidence: z.number().min(0).max(1).default(0.7),
});
```

Add optional `palmLines` to `ReadingSchema`:

```ts
palmLines: PalmLineSetSchema.optional(),
```

### Add tool schema field

In `TOOL.input_schema.properties`, add:

```ts
palmLines: {
  type: 'object',
  description: 'Normalized top-left-origin coordinates tracing visible palm creases. Required when status=ok if the lines are visible enough.',
  properties: {
    heart: linePathToolSchema,
    head: linePathToolSchema,
    life: linePathToolSchema,
    fate: linePathToolSchema,
    source: { type: 'string', enum: ['ai_detected', 'fallback'] },
    confidence: { type: 'number' },
  },
}
```

Keep `palmLines` out of the required list initially so old/failed model outputs do not hard-fail otherwise good readings. Post-parse, if `status === 'ok' && !palmLines`, client uses soft fallback.

### Prompt addition

Add to `buildSystemPrompt` after image validation:

```text
PALM LINE COORDINATES:
- When status = "ok", inspect the user's actual visible palm creases and return `palmLines`.
- Coordinates must be normalized numbers from 0.0 to 1.0 relative to the image bounds, origin top-left.
- Return 4-6 points per line so the client can smooth a curve.
- Trace visible creases where possible. Do not use generic textbook placement if visible creases disagree.
- Heart line: upper transverse crease under the fingers, typically from pinky side toward index/middle.
- Head line: middle transverse/diagonal crease across the palm.
- Life line: curved crease wrapping around the thumb mound.
- Fate line: vertical/diagonal central line from wrist/lower palm toward middle finger, if visible.
- If a line is faint/partially absent, estimate gently from visible palm structure and lower that line's confidence.
- If coordinates would be speculative, still return status ok for the reading but set palmLines.source = "fallback" and confidence < 0.45.
```

### Response example

```json
{
  "status": "ok",
  "title": "Velvet Compass",
  "oneLineSummary": "Your palm is giving focused chaos with unusually loyal instincts.",
  "auraColor": "violet",
  "archetype": "The Night Strategist",
  "palmLines": {
    "source": "ai_detected",
    "confidence": 0.78,
    "heart": { "confidence": 0.82, "midpoint": { "x": 0.52, "y": 0.34 }, "points": [{ "x": 0.19, "y": 0.38 }, { "x": 0.36, "y": 0.33 }, { "x": 0.57, "y": 0.32 }, { "x": 0.75, "y": 0.35 }] },
    "head": { "confidence": 0.76, "midpoint": { "x": 0.50, "y": 0.49 }, "points": [{ "x": 0.23, "y": 0.50 }, { "x": 0.42, "y": 0.47 }, { "x": 0.63, "y": 0.49 }, { "x": 0.78, "y": 0.53 }] },
    "life": { "confidence": 0.73, "midpoint": { "x": 0.30, "y": 0.62 }, "points": [{ "x": 0.34, "y": 0.38 }, { "x": 0.26, "y": 0.52 }, { "x": 0.28, "y": 0.70 }, { "x": 0.38, "y": 0.86 }] },
    "fate": { "confidence": 0.55, "midpoint": { "x": 0.51, "y": 0.63 }, "points": [{ "x": 0.51, "y": 0.88 }, { "x": 0.52, "y": 0.70 }, { "x": 0.50, "y": 0.54 }, { "x": 0.49, "y": 0.40 }] }
  }
}
```

---

## 7. iOS data model

### Task 1: Create `Models/PalmLine.swift`

Create: `ios/PalmAura/PalmAura/Models/PalmLine.swift`

- `PalmLine` enum: `heart`, `head`, `life`, `fate`.
- Display metadata: title, domain, SF Symbol.
- `PalmReadingResponse.reportText(for:)` helper.

Acceptance:

- Compiles.
- Unit test verifies all cases map to non-empty text for fixture.

### Task 2: Create `Models/PalmLineSet.swift`

Create: `ios/PalmAura/PalmAura/Models/PalmLineSet.swift`

Important differences from Opus:

```swift
enum Source: String, Codable {
    case aiDetected = "ai_detected"
    case fallback
}

struct PalmLinePath: Codable, Equatable {
    let points: [CGPoint]
    let midpoint: CGPoint
    let confidence: Double
}

struct PalmLineSet: Codable, Equatable {
    let heart: PalmLinePath
    let head: PalmLinePath
    let life: PalmLinePath
    let fate: PalmLinePath
    let source: Source
    let confidence: Double
}
```

Keep `PalmLineSet.fallback`, but renderer should visually style fallback differently.

Acceptance:

- Codable roundtrip passes.
- All fallback coordinates are inside `[0,1]`.
- `Source.aiDetected` decodes from backend string `ai_detected`.

### Task 3: Modify `Models/PalmReadingResponse.swift`

Modify: `ios/PalmAura/PalmAura/Models/PalmReadingResponse.swift`

- Add `case palmMap = "palm_map"` to `ShareCardFormat`.
- Add optional `let palmLines: PalmLineSet?` to `PalmReadingResponse`.
- Ensure fixture JSON is updated or decoder supports absent `palmLines`.

Acceptance:

- Existing fixture still decodes.
- New fixture with `palmLines` decodes.

### Task 4: Create `Models/ReadingBundle.swift`

Create: `ios/PalmAura/PalmAura/Models/ReadingBundle.swift`

```swift
struct ReadingBundle: Equatable {
    let reading: PalmReadingResponse
    let photoURL: URL?
    let lineSet: PalmLineSet
    let auraColor: AuraColor

    init(reading: PalmReadingResponse, photoURL: URL?, lineSet: PalmLineSet? = nil) {
        self.reading = reading
        self.photoURL = photoURL
        self.lineSet = lineSet ?? reading.palmLines ?? PalmLineSet.fallback
        self.auraColor = reading.auraColor
    }

    static func restore(reading: PalmReadingResponse) -> ReadingBundle {
        ReadingBundle(
            reading: reading,
            photoURL: PalmPhotoStore.url(for: reading.readingId),
            lineSet: PalmLineSetStore.load(for: reading.readingId) ?? reading.palmLines
        )
    }

    var hasPhoto: Bool { photoURL != nil }
    var shouldUsePreciseLines: Bool { lineSet.source == .aiDetected && lineSet.confidence >= 0.55 }
}
```

Add:

```swift
extension ReadingBundle {
    var augmentedShareCards: [ShareCard] { ... append palm_map when hasPhoto ... }
}
```

Acceptance:

- Restores older readings without photos.
- Adds palm-map share card only when a photo exists.

---

## 8. Photo and line persistence

### Task 5: Extend `ImagePreprocessor`

Modify: `ios/PalmAura/PalmAura/Services/ImagePreprocessor.swift`

- Add `jpegDataForLocalStorage(from:)`.
- Use longest edge 1024, JPEG quality 0.75.
- Re-render via `UIGraphicsImageRenderer` to strip EXIF.

Acceptance:

- Unit test creates non-empty JPEG under a reasonable size.

### Task 6: Create `PalmPhotoStore`

Create: `ios/PalmAura/PalmAura/Services/PalmPhotoStore.swift`

Use Opus code with these decisions:

- `pendingKey = "pending"` is acceptable for single in-flight reading.
- Save only local JPEGs, not originals.
- Exclude directory from iCloud backup.
- `prune(keepMostRecent: 12)` on app launch.
- `count` for Settings display.

Acceptance:

- Save creates file.
- Bind moves `pending.jpg` to `<readingId>.jpg`.
- Prune keeps most recent 12.
- Clear deletes all.

### Task 7: Create `PalmLineSetStore`

Create: `ios/PalmAura/PalmAura/Services/PalmLineSetStore.swift`

- UserDefaults JSON keyed by `palmLines_<readingId>`.
- `save`, `load`, `clear`, `clearAll`.

Acceptance:

- Save/load roundtrip works.
- Clear removes only target.

### Task 8: App launch prune

Modify: `ios/PalmAura/PalmAura/PalmAuraApp.swift`

Add in `init()`:

```swift
PalmPhotoStore.prune(keepMostRecent: 12)
```

Acceptance:

- App still launches in simulator.

---

## 9. Core renderer

### Task 9: Create `Components/PalmCanvasView.swift`

Create: `ios/PalmAura/PalmAura/Components/PalmCanvasView.swift`

Base it on Opus code, with these changes:

- Accept `renderingMode: .preciseLines | .softGlow` or derive from `ReadingBundle.shouldUsePreciseLines`.
- For `.preciseLines`:
  - stroke active line width ~5;
  - inactive width ~2.5;
  - glow radius 12-16.
- For `.softGlow` fallback:
  - no crisp line stroke above 1pt opacity;
  - draw broad blurred bands/paths using 28-44pt translucent aura strokes;
  - copy should say `Your palm map is symbolic — the lines are softly charted.` where needed.
- Use Catmull-Rom smoothing.
- Use 44pt hit zones.
- Respect Reduce Motion.

Acceptance:

- Works with `photoURL == nil` fallback.
- Works with AI line set and fallback line set.
- VoiceOver label describes active line.

### Task 10: Add `PalmIgnitionPanel`

Create: `ios/PalmAura/PalmAura/Views/PalmIgnitionPanel.swift`

Purpose: single reveal step that animates all lines on the real palm.

Behavior:

- Uses `PalmCanvasView(activeLine: nil, ignitionProgress: progress)`.
- Starts `progress = 0` and animates to `1` over 2.8-3.2 seconds.
- Copy:
  - Eyebrow: `PALM MAP`
  - Title: `Your lines have been charted.`
  - Detail if precise: `Tap in after the reveal to explore love, mind, life, and fate.`
  - Detail if fallback: `The oracle caught the shape of your hand; explore the symbolic map next.`
- Haptic: success on appear.
- Analytics: `palm_ignition_shown { lineSource, confidence }`.

Acceptance:

- First reveal includes one palm-photo animation, not four separate line screens.

---

## 10. Capture, review, loading wiring

### Task 11: Modify `PalmReviewView`

Modify: `ios/PalmAura/PalmAura/Views/PalmReviewView.swift`

Current review only sends base64. Change to:

- Save the user's photo locally with `PalmPhotoStore.save(image, key: PalmPhotoStore.pendingKey)` on appear.
- Show the actual photo preview, optionally with faint generic aura outline, but do **not** show fake precise lines before backend coordinates exist.
- Pass `pendingPhotoURL` into `LoadingReadingView`.

Do not run Vision line detection here.

Acceptance:

- Review screen shows user's actual photo.
- Upload base64 still created.
- Photo file exists before tapping `Read My Palm`.

### Task 12: Modify `LoadingReadingView`

Modify: `ios/PalmAura/PalmAura/Views/LoadingReadingView.swift`

Signature:

```swift
let imageBase64Jpeg: String
let pendingPhotoURL: URL?
let onboardingAnswers: OnboardingAnswers
@State private var bundle: ReadingBundle?
```

On successful response:

```swift
let boundURL = PalmPhotoStore.bind(to: response.readingId) ?? pendingPhotoURL
if let palmLines = response.palmLines {
    PalmLineSetStore.save(palmLines, for: response.readingId)
}
LastReadingStore.save(response)
bundle = ReadingBundle(reading: response, photoURL: boundURL)
showResult = true
```

Route:

```swift
.navigationDestination(isPresented: $showResult) {
    if let bundle { RevealSequenceView(bundle: bundle) }
}
```

Acceptance:

- App still handles `not_palm` and `bad_image` without saving a last reading.
- Successful reading carries `photoURL` + `PalmLineSet` into reveal.

### Task 13: Modify `LastReadingStore`

Modify: `ios/PalmAura/PalmAura/Services/LastReadingStore.swift`

- Keep last reading JSON as-is.
- `clear()` should remove last reading and line set for that reading.
- Do **not** silently delete all saved photos on `clear()` unless the Settings button explicitly says it will. Add separate delete-photo control.

Acceptance:

- Clear last reading doesn't leave stale palm-map route for that reading.

---

## 11. Reveal and browsing UX

### Task 14: Modify `RevealSequenceView`

Modify: `ios/PalmAura/PalmAura/Views/RevealSequenceView.swift`

- Change input from `reading` to `bundle`.
- Keep `private var reading: PalmReadingResponse { bundle.reading }`.
- First reveal steps: portal, aura, palm ignition, archetype, share/explore = 5 steps.
- Returning reveal steps: aura snapshot, palm ignition/today signal, share/explore = 3 steps.
- Add final action ordering:
  1. `Explore your palm map` when `bundle.hasPhoto`.
  2. `Share palm video` or share panel.
  3. `Open full report`.
  4. `Return home`.
- Share panel uses `bundle.augmentedShareCards`.

Acceptance:

- No 9-step reveal.
- First-time user reaches share/explore in 5 taps max.
- Older readings without photos fall back to current text panels.

### Task 15: Create `PalmMapView`

Create: `ios/PalmAura/PalmAura/Views/PalmMapView.swift`

Start from Opus code with these additions:

- Header has:
  - title `Your palm map`;
  - subtitle `Tap a glowing line`;
  - toolbar link to full report.
- Canvas supports pinch-to-zoom only if it is low-risk to implement cleanly; otherwise defer pinch and ship tap-first.
- Bottom sheet states:
  - no selection: line chips.
  - selected: line detail with reading text and `Next line`.
- Add share CTA:
  - `Share this palm map` triggers `ShareOptionsSheet` or direct renderer path.
- Use `bundle.shouldUsePreciseLines` to choose precise vs soft rendering.

Acceptance:

- Tapping each line shows the correct report section.
- Chip and line tap both work.
- Full report remains reachable.
- Fallback/no-photo states degrade gracefully.

### Task 16: Modify `ReadingResultView`

Modify: `ios/PalmAura/PalmAura/Views/ReadingResultView.swift`

- Accept optional `bundle: ReadingBundle?` or provide a new `ReadingResultView(bundle:)` initializer.
- Add a top `Palm Map` card when photo exists.
- Convert the long text stack into section cards with anchor-like chips for Aura, Heart, Head, Life, Fate, Season, Guidance, Ritual.
- Keep share cards horizontal.

Acceptance:

- Full report is still useful, but Palm Map is visually promoted.

### Task 17: Modify `HomeView`

Modify: `ios/PalmAura/PalmAura/Views/HomeView.swift`

- Restore bundle from `LastReadingStore.load()`.
- If `bundle.hasPhoto`, show `Your last palm map` preview card using `PalmCanvasView` thumbnail.
- `Reveal again` uses `RevealSequenceView(bundle:)`.
- Add direct `Open palm map` CTA.

Acceptance:

- Returning user can reopen the map without re-scanning.

### Task 18: Modify `SettingsView`

Modify: `ios/PalmAura/PalmAura/Views/SettingsView.swift`

Add section:

- `Saved palm photos: N`.
- Button: `Delete saved palm photos`.
- Button action: `PalmPhotoStore.clearAll(); PalmLineSetStore.clearAll()`.
- Existing `Clear last reading` should be explicit about whether photos are retained.

Acceptance:

- User control exists for local photo data.

---

## 12. Share/video implementation

### Task 19: Palm-map share card still composition

Modify: `ios/PalmAura/PalmAura/Services/ShareCardRenderer.swift`

Add:

```swift
@MainActor
func renderPalmMapCard(bundle: ReadingBundle) async -> UIImage?
```

Composition:

- black/aura radial background;
- 65% vertical area: `PalmCanvasView` with all lines lit;
- title + one-line summary;
- footer watermark.

Acceptance:

- Renders 1080×1920 `UIImage` from fixture bundle.

### Task 20: Palm-map video renderer

Modify: `ShareVideoRenderer` or add `PalmMapVideoRenderer`.

Do not animate by repeatedly screenshotting SwiftUI if that is slow/flaky. Prefer frame-by-frame CoreGraphics drawing from the rendered still or draw the line paths directly on a `CGContext`:

- Use saved palm image as base.
- Draw aura pulse.
- Draw each smoothed line with trim progress based on frame.
- Draw title/summary/footer if practical; otherwise render a still layout then overlay pulse/line animation.

Output:

- H.264 MP4.
- 1080×1920.
- 3.5-4 seconds.
- 24 fps.
- Bitrate ~6 Mbps.

Acceptance:

- Video file exists, playable, <10 MB preferred.
- Share sheet uses video first for `palm_map`.
- Static card fallback if video render throws.

### Task 21: Modify `ShareOptionsSheet`

Modify: `ios/PalmAura/PalmAura/Views/ShareOptionsSheet.swift`

- For normal cards, keep current behavior.
- For `format == .palmMap`, require a `ReadingBundle` context.
- Render video first, then present `ShareLink`/activity item.
- Fall back to still image.
- Track:
  - `share_card_palm_map_rendered`;
  - `share_card_palm_map_shared`.

Acceptance:

- Tapping palm-map share card produces MP4 share item.

---

## 13. Privacy/copy updates

### Task 22: In-app privacy copy

Modify:

- `DisclaimerView.swift`.
- `SettingsView.swift`.
- Any copy guardrail docs.

Add language:

> PalmAura saves recent palm photos on this device only so you can revisit and share your palm map. They are never stored on PalmAura servers and can be deleted anytime in Settings.

Acceptance:

- In-app copy no longer implies no persistence at all.

### Task 23: Landing/privacy page

Find the landing/privacy source in repo. Update `palmaura.app/privacy.html` or Worker/static equivalent:

> PalmAura saves your most recent palm photos to your device only — never to our servers — so you can revisit and share your palm map. You can delete them anytime in Settings → Saved palm photos.

Acceptance:

- Production privacy page is updated before TestFlight/public release.

---

## 14. Analytics

Add events:

```text
palm_lines_received              { source, confidence }
palm_lines_missing               { reason }
palm_canvas_rendered             { context, source, confidence }
palm_ignition_shown              { source, confidence }
palm_map_opened                  { source: reveal_end|home|report, lineSource, confidence }
palm_line_selected               { line }
palm_line_cycle_next             { from, to }
share_card_palm_map_rendered     { media: video|image }
share_card_palm_map_shared       { channel: generic|stories|camera_roll }
palm_photos_deleted_via_settings { count }
```

Keep analytics payloads free of image URLs, raw coordinates, base64, or personal text.

---

## 15. Testing plan

### Backend tests/manual validation

Commands:

```bash
cd /Users/psy/projects/palm-aura/backend
npm run typecheck
npm run deploy
curl -i https://palmaura-api.psyduckler.workers.dev/api/health
```

If adding automated Worker tests, validate:

- `PalmLineSetSchema` accepts valid coordinates.
- Rejects out-of-bounds coordinates.
- `ReadingSchema` still accepts older no-`palmLines` outputs.
- Tool schema includes `palmLines` but does not require it.

### iOS unit tests

Add:

- `PalmLineSetTests`
  - fallback bounds;
  - Codable roundtrip;
  - `ai_detected` decode.
- `PalmPhotoStoreTests`
  - save;
  - bind;
  - prune;
  - clear.
- `PalmReadingResponseTests`
  - fixture without `palmLines` decodes;
  - fixture with `palmLines` decodes.

### iOS build/test commands

```bash
cd /Users/psy/projects/palm-aura/ios/PalmAura
xcodebuild test -project PalmAura.xcodeproj -scheme PalmAura -destination 'platform=iOS Simulator,name=iPhone 17' CODE_SIGNING_ALLOWED=NO
xcodebuild -project PalmAura.xcodeproj -scheme PalmAura -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build
```

### Manual QA matrix

- Good palm photo → backend returns `palmLines.source=ai_detected`; Palm Ignition uses precise glowing lines.
- Dim palm photo → may return lower confidence; app uses soft glow fallback if confidence < threshold.
- Non-palm image → backend returns `not_palm`; no last reading, no palm map.
- Photo deleted in Settings → last reading still opens full report; palm map card hidden.
- Reduce Motion → line ignition snaps/shortens; aura pulse subdued.
- Share palm-map card → MP4 generated and share sheet opens.
- Force-quit after reading → Home restores `Your last palm map`.

---

## 16. Shipping sequence

### Commit A — backend contract + rate limit

1. Add `PalmLineSetSchema` to `backend/src/index.ts`.
2. Add optional `palmLines` to tool schema and Zod schema.
3. Update prompt.
4. Keep rate limit at 100/day.
5. Run `npm run typecheck`.
6. Deploy.
7. Smoke `/api/health`.

### Commit B — iOS models/stores/tests

1. Add `PalmLine`, `PalmLineSet`, `ReadingBundle`.
2. Add `PalmPhotoStore`, `PalmLineSetStore`.
3. Extend `ImagePreprocessor`.
4. Extend `PalmReadingResponse`.
5. Add tests.
6. Run simulator tests.

### Commit C — canvas + reveal

1. Add `PalmCanvasView`.
2. Add `PalmIgnitionPanel`.
3. Modify `PalmReviewView` to save local photo.
4. Modify `LoadingReadingView` to assemble bundle.
5. Modify `RevealSequenceView` to condensed flow.
6. Run tests + generic build.

### Commit D — browsing surfaces

1. Add `PalmMapView`.
2. Modify `HomeView`.
3. Modify `ReadingResultView`.
4. Modify `SettingsView`.
5. Run tests + generic build.

### Commit E — palm-map sharing

1. Add `palm_map` share format.
2. Add still renderer.
3. Add MP4 renderer path.
4. Modify share sheet.
5. Manual share QA in simulator/device.
6. Run tests + generic build.

### Commit F — privacy/docs/final verification

1. Update in-app privacy copy.
2. Update landing/privacy page if in repo.
3. Run backend typecheck/deploy if Worker changed.
4. Run iOS tests/build.
5. Create clean zip if requested.

---

## 17. Acceptance criteria

This experience is shipped correctly when:

- `/api/read` returns `palmLines` for successful palm readings when the model can identify creases.
- The iOS app decodes and persists the returned line set.
- The user's actual hand photo appears in reveal and Palm Map.
- No Vision joint-offset math is used as the primary precision line detector.
- Low-confidence/missing coordinates degrade to soft glow, not obviously wrong crisp lines.
- First reveal is 5 steps max; returning reveal is 3 steps max.
- Palm Map lets users tap/browse Heart, Head, Life, Fate readings.
- Home can reopen the last palm map.
- Settings can delete saved palm photos.
- Palm-map sharing produces MP4 first and still fallback.
- Backend typecheck passes.
- iOS simulator tests pass.
- Generic physical iOS build passes with `CODE_SIGNING_ALLOWED=NO`.
- Privacy copy accurately explains local-only photo storage.

---

## 18. Out of scope for this sprint

- Custom AVCaptureSession with hand silhouette overlay.
- Server-side photo storage or history sync.
- Eight-line traditional palmistry expansion.
- App Clip/social web preview.
- Paid subscription/account system.
- Perfect forensic palm-line detection claims.
- Medical, financial, lifespan, fertility, or certainty language.

---

## 19. Rate limit update status

The requested internal-testing rate-limit increase has already been applied in `backend/src/index.ts`:

```ts
const DAILY_SCAN_LIMIT = 100;
// ...
return { allowed: next <= DAILY_SCAN_LIMIT, retryAfterSeconds: 86_400 };
```

Verification performed:

- `npm run typecheck` passed.
- Worker deployed to `https://palmaura-api.psyduckler.workers.dev`.
- Current Worker Version ID: `96bfdc11-6535-4cb2-9d1c-dd230ee2cb01`.
- `GET /api/health` returned HTTP 200 with `rateLimit: true`.

---

## 20. Implementation note for subagents

When implementing, do not blindly paste the attached Opus full-file replacements over the current repo. The repo has already moved since Opus's desktop snapshot. Patch current files incrementally and run tests after each stage. Preserve the recent UX redesign files (`DesignSystem.swift`, `PalmAuraMark.swift`, `HomeView.swift`, `RevealSequenceView.swift`) and adapt them to `ReadingBundle` rather than replacing them wholesale.
