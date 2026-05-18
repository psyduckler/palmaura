# PalmAura Phone/TestFlight Demo Handoff

Current demo target: get PalmAura installable on a physical iPhone and ready for internal TestFlight once Apple signing is available.

## Current build config

- Project: `ios/PalmAura/PalmAura.xcodeproj`
- Scheme: `PalmAura`
- Bundle ID: `com.zonted.palmaura`
- Version: `0.1.0`
- Build: `2`
- Backend: `https://palmaura.app/api/*` via `https://palmaura.app` app base URL
- Cloudflare routes:
  - `GET /api/health`
  - `GET /api/edge-context`
  - `POST /api/read`
- Workers.dev fallback: disabled intentionally for internal-only testing (`workers_dev = false`).
- Backend rate limit: Cloudflare KV, 3 readings/day/device.
- Privacy posture: PalmAura does not store palm photos; images are sent to Anthropic for real-time processing.

## Fastest physical iPhone install path

Prereqs:

1. Open Xcode on this Mac.
2. Sign into Apple Developer account: `Xcode → Settings → Accounts`.
3. Plug in iPhone, unlock it, tap Trust This Computer if prompted.
4. In Xcode, open:
   ```bash
   open /Users/psy/projects/palm-aura/ios/PalmAura/PalmAura.xcodeproj
   ```
5. Select target `PalmAura` → `Signing & Capabilities`.
6. Select your Apple Developer Team.
7. Confirm bundle ID remains `com.zonted.palmaura` unless you intentionally change it.
8. Select your iPhone as the run destination.
9. Press Run (`Cmd+R`).

Expected first-run QA:

- App opens to PalmAura disclaimer screen.
- Tap `I understand — begin`.
- Complete 3 onboarding questions.
- Use `Take Photo` on device camera.
- Submit a clear palm photo.
- Confirm mystical loading lasts at least ~8 seconds.
- Confirm response returns either:
  - a full `ok` reading with 3 share cards, or
  - friendly `not_palm` / `bad_image` rejection.
- Confirm share sheet works from result/share card screen.
- If Instagram is installed, test Instagram Stories path.

## Internal TestFlight path

1. In Apple Developer / App Store Connect, create/register app with bundle ID:
   ```text
   com.zonted.palmaura
   ```
2. In Xcode, select Apple Developer Team for target `PalmAura`.
3. Product → Archive.
4. Organizer opens → Distribute App.
5. Choose App Store Connect → Upload.
6. Once processing completes, add internal testers in App Store Connect → TestFlight.

If using CLI after signing is configured:

```bash
cd /Users/psy/projects/palm-aura/ios/PalmAura
xcodebuild -project PalmAura.xcodeproj \
  -scheme PalmAura \
  -destination 'generic/platform=iOS' \
  -configuration Release \
  -archivePath /tmp/PalmAura.xcarchive \
  -allowProvisioningUpdates \
  archive
```

Then upload from Xcode Organizer, or export/upload with your App Store Connect API key once configured.

## Known current blocker

This Mac currently has no local code-signing identity and no physical iPhone attached:

```text
0 valid identities found
No devices found
```

The app compiles for physical iOS unsigned, but signed archive/upload requires selecting an Apple Developer Team in Xcode.

## Verified gates

- Cloudflare Worker deployed and live on branded routes only.
- `https://palmaura.app/api` returns Worker JSON 404, not marketing HTML.
- `GET https://palmaura.app/api/health` returns 200 JSON.
- `GET https://palmaura.app/api/edge-context` returns 200 JSON.
- Invalid `POST https://palmaura.app/api/read` returns 400 JSON without calling Anthropic.
- `https://palmaura-api.psyduckler.workers.dev/api/health` no longer serves PalmAura JSON.
- `POST /api/read` with non-palm smoke image returns structured `status: not_palm` over the branded route.
- Simulator install/launch succeeds with bundle ID `com.zonted.palmaura`.
- Simulator screenshot captured at `/tmp/palmaura-api-migration-simulator-launch.png`.
- Simulator tests pass: 4 tests, 0 failures.
- Generic physical iOS build passes with `CODE_SIGNING_ALLOWED=NO`.
- Signed archive currently fails only because no Apple Developer Team is selected.

## Before public launch

- Rotate the Anthropic API key because it was shared through Slack.
- Re-check branded API route behavior before public launch if Cloudflare routing changes.
- Re-check App Privacy nutrition labels against actual data processing.
