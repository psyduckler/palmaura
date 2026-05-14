# PalmAura Specific + Plausible Readings Implementation Plan

> **For Hermes:** Use `subagent-driven-development` to implement this plan task-by-task after product review.

**Goal:** Make PalmAura readings feel materially more specific, plausible, and personally relevant by combining visible palm evidence, lightweight user context, life-stage intelligence, and safer interpretive guardrails.

**Architecture:** Add a small personalization layer around the existing palm reading flow: collect high-ROI onboarding context, extract structured palm features from the image, normalize user context into age/zodiac/life-stage signals, then synthesize readings only from grounded evidence. Keep v1 lean: do not build a giant personality platform before proving that the output quality improves.

**Tech Stack:** SwiftUI iOS app, existing PalmAura models/views, Cloudflare Workers TypeScript backend, Zod/schema validation, Anthropic/Gemini-style vision extraction, local-only photo storage, optional account/profile persistence later.

---

## 1. Product thesis

Palm readings feel generic when the generator only sees a hand photo and is asked to produce a mystical report. They feel specific when the reading repeatedly references:

1. **Visible palm evidence** — line shape, line depth, hand type, finger proportions, mounts, texture.
2. **User-provided context** — birthday, dominant hand, uploaded hand, focus area, relationship/career stage.
3. **Life-stage patterns** — what someone at this age is realistically navigating.
4. **Current intent** — what they are asking about today.
5. **Grounded synthesis** — “because your head line…” / “given your age…” / “since you asked about career…”.

The goal is not to make deterministic claims. The goal is to make readings feel **made for this person** while remaining entertainment-first, safe, and plausible.

---

## 2. Recommended v1 scope

### Ship in v1

Collect these during first successful reading or first app setup:

1. **Date of birth**
   - Enables age band, zodiac sun sign, Chinese zodiac, numerology/life-path, and year-based timing.
   - Ask for birthday rather than age because it has more downstream utility.

2. **Dominant hand**
   - Options: `left`, `right`, `ambidextrous`, `not_sure`.
   - Used for classic palmistry framing: dominant hand = lived/current path; non-dominant = inherited tendencies/potential.

3. **Which hand is uploaded**
   - Options: `left`, `right`, `not_sure`.
   - Enables dominant vs non-dominant interpretation.

4. **Current focus area**
   - Options: `love`, `career`, `money`, `purpose`, `family`, `energy`, `decision`, `general`.
   - Highest ROI for making the report feel relevant.

5. **Current life season**
   - Options: `growing_fast`, `feeling_stuck`, `healing`, `big_decision`, `seeking_love`, `under_pressure`, `ready_for_change`, `just_curious`.
   - Gives the reading a timely hook.

6. **Tone preference**
   - Options: `gentle`, `direct`, `mystical`, `practical`, `romantic`, `career_focused`.
   - Prevents “accuracy” complaints that are really tone mismatches.

### Optional v1 fields if UX can handle one more screen

7. **Relationship status**
   - Options: `single`, `dating`, `partnered`, `married`, `complicated`, `prefer_not_to_say`.
   - Very useful for love-line interpretation.

8. **Career stage**
   - Options: `student`, `early_career`, `building_career`, `manager_leader`, `entrepreneur`, `between_things`, `later_chapter`, `prefer_not_to_say`.
   - Very useful for fate/head-line interpretation.

### Defer / do carefully

- **Birth time + birthplace**
  - Valuable for deeper astrology, but should be optional/premium later.
  - Do not block first reading.

- **Gender inference from hand**
  - Avoid in v1. It is easy to get wrong, can feel creepy, and can push outputs into stereotypes.
  - Better: ask optional pronouns if needed for copy, and infer non-sensitive style cues from the hand/photo.

- **Medical/health inference from palm, nails, skin**
  - Avoid. Keep “energy” phrasing reflective, not diagnostic.

---

## 3. Reading specificity framework

Every generated claim should be grounded in one of four evidence types:

| Evidence type | Examples | Safe phrasing |
|---|---|---|
| Palm feature | long head line, curved heart line, deep life line, many fine lines | “Your head line appears…” |
| User context | birthday, age band, focus area, dominant hand | “Given your age/life stage…” |
| Interpretive system | zodiac, numerology, palmistry archetype | “In the astrology layer…” |
| Combination | palm feature + age + focus | “Because you asked about career, this fate-line pattern reads as…” |

The generator should avoid unsupported generic statements like:

> “You are creative, loyal, and intuitive.”

Preferred pattern:

> “Your head line appears long and slightly downward-sloping, which points to imagination, but the stronger life-line curve keeps the reading grounded. This reads less like scattered creativity and more like someone who needs a real-world container — a project, client, deadline, or visible result.”

---

## 4. New data model proposal

### `PalmReadingPersonalization`

Add a lightweight profile/context object passed to `/api/read`.

```ts
type PalmReadingPersonalization = {
  birthDate?: string; // ISO yyyy-mm-dd, no time required
  dominantHand?: 'left' | 'right' | 'ambidextrous' | 'not_sure';
  uploadedHand?: 'left' | 'right' | 'not_sure';
  focusArea?: 'love' | 'career' | 'money' | 'purpose' | 'family' | 'energy' | 'decision' | 'general';
  lifeSeason?: 'growing_fast' | 'feeling_stuck' | 'healing' | 'big_decision' | 'seeking_love' | 'under_pressure' | 'ready_for_change' | 'just_curious';
  tone?: 'gentle' | 'direct' | 'mystical' | 'practical' | 'romantic' | 'career_focused';
  relationshipStatus?: 'single' | 'dating' | 'partnered' | 'married' | 'complicated' | 'prefer_not_to_say';
  careerStage?: 'student' | 'early_career' | 'building_career' | 'manager_leader' | 'entrepreneur' | 'between_things' | 'later_chapter' | 'prefer_not_to_say';
  userQuestion?: string; // optional free text, max 240 chars
};
```

### Derived backend context

The backend should derive, not ask the LLM to calculate ad hoc:

```ts
type DerivedPersonalization = {
  age?: number;
  ageBand?: 'under_18' | '18_24' | '25_34' | '35_44' | '45_54' | '55_plus';
  zodiacSunSign?: string;
  chineseZodiac?: string;
  numerologyLifePath?: number;
  personalYearNumber?: number;
  uploadedHandRole?: 'dominant' | 'non_dominant' | 'unknown';
  lifeStageThemes: string[];
};
```

Do not send raw birthday deeper than needed if a derived object is sufficient for model prompting.

---

## 5. Structured palm feature extraction

Do not ask the model directly for a final reading from an image. First ask for structured observations.

### Proposed `PalmFeatureSet`

```ts
type PalmFeatureSet = {
  imageQuality: 'poor' | 'fair' | 'good' | 'excellent';
  handOrientation: 'left_palm' | 'right_palm' | 'unclear';
  handShape?: 'earth' | 'air' | 'water' | 'fire' | 'mixed' | 'unclear';
  visibleLines: {
    lifeLine?: PalmLineObservation;
    headLine?: PalmLineObservation;
    heartLine?: PalmLineObservation;
    fateLine?: PalmLineObservation;
    sunLine?: PalmLineObservation;
    mercuryLine?: PalmLineObservation;
  };
  mounts?: {
    venus?: MountObservation;
    jupiter?: MountObservation;
    saturn?: MountObservation;
    apollo?: MountObservation;
    mercury?: MountObservation;
    moon?: MountObservation;
    mars?: MountObservation;
  };
  fingerTraits?: {
    fingerLengthRelativeToPalm?: 'short' | 'medium' | 'long' | 'unclear';
    ringVsIndex?: 'ring_longer' | 'index_longer' | 'similar' | 'unclear';
    thumbProminence?: 'low' | 'medium' | 'high' | 'unclear';
    fingerSpacing?: 'close' | 'moderate' | 'wide' | 'unclear';
  };
  texture?: {
    lineDensity?: 'few' | 'moderate' | 'many' | 'unclear';
    lineDepthOverall?: 'light' | 'medium' | 'deep' | 'mixed' | 'unclear';
  };
  notableFeatures: string[];
  confidence: number; // 0-1
};

type PalmLineObservation = {
  visible: boolean;
  depth?: 'light' | 'medium' | 'deep' | 'mixed';
  length?: 'short' | 'medium' | 'long';
  curve?: 'straight' | 'slight_curve' | 'strong_curve' | 'unclear';
  slope?: 'upward' | 'flat' | 'downward' | 'unclear';
  breaks?: 'none_visible' | 'minor' | 'clear' | 'unclear';
  forks?: 'none_visible' | 'start' | 'end' | 'multiple' | 'unclear';
  intersections?: 'few' | 'moderate' | 'many' | 'unclear';
  confidence: number;
};

type MountObservation = {
  prominence: 'low' | 'medium' | 'high' | 'unclear';
  confidence: number;
};
```

### Extraction rules

- If the image is too blurry, mark `imageQuality = poor` and avoid over-specific palm claims.
- Never infer medical conditions.
- Never infer ethnicity, sexuality, pregnancy, wealth, or trauma history.
- If gender/pronouns are not provided, write without gendered assumptions.
- If hand orientation inferred from image conflicts with user-selected uploaded hand, ask for confirmation in-app or use `unclear`.

---

## 6. Reading output structure

The final report should be sectioned and evidence-backed.

### Proposed report sections

1. **Your palm at a glance**
   - 2-3 sentences summarizing visible palm signals.

2. **Core pattern**
   - Personality/behavioral interpretation grounded in palm features.

3. **Life-stage lens**
   - Age-band interpretation using derived context.

4. **Focus-area reading**
   - Tailored to love/career/money/purpose/etc.

5. **Astrology + numerology layer**
   - Birthday-derived layer; keep it concise and integrated.

6. **Pattern to watch**
   - A plausible friction point.

7. **Next useful move**
   - One concrete, low-risk action.

8. **Near-term timing**
   - Soft time window, not a guaranteed prediction.

### Example generated style

> Because your head line appears long and slightly downward-sloping, your reading leans toward imaginative problem-solving rather than purely linear planning. Given your age band, this does not read as “finding yourself” in a vague way — it reads as choosing which ambitions deserve your energy and which ones were inherited from old expectations.

---

## 7. Prompting contract

### System instruction for synthesis

The reading synthesis prompt should require:

- Cite at least 6 concrete inputs across the report.
- Each major claim must map to `palm_features`, `derived_context`, `user_context`, or `interpretive_layer`.
- Use uncertainty language for low-confidence visual observations.
- Do not say “I can see you are…” for inferred psychological claims. Use “this suggests,” “this reads as,” “the pattern points toward.”
- Do not make medical, legal, financial, death, pregnancy, fertility, or guaranteed relationship predictions.
- Do not infer or mention gender unless the user explicitly provided pronouns/gender context.

### Anti-generic checklist

Before returning, the backend should reject/regenerate if the response:

- Could apply to almost anyone.
- Does not mention the uploaded hand/dominant hand role when known.
- Does not mention the focus area when provided.
- Does not mention at least 3 specific palm features.
- Uses empty adjectives without evidence: “creative,” “loyal,” “intuitive,” “resilient,” “sensitive.”
- Makes a brittle factual prediction.

---

## 8. UX flow

### First reading flow

1. User uploads/captures palm.
2. App asks a short “make this personal” screen:
   - Date of birth
   - Which hand is this?
   - Dominant hand
   - What do you want insight on?
3. Optional accordion: “Tune the reading”
   - Current life season
   - Tone
   - Relationship/career stage
4. Backend extracts palm features.
5. Backend derives age/zodiac/numerology/life-stage context.
6. Backend generates grounded reading.
7. App shows reveal + palm map + full report.

### Returning reading flow

Ask only:

> “What changed since your last reading?”

Options:

- Love
- Career
- Energy
- Big decision
- Nothing, just curious

Then reuse saved birthday/dominant hand/preferences.

---

## 9. Privacy and trust rules

1. Birthday is sensitive enough to explain why it is collected.
   - Copy: “Used to personalize age-stage, astrology, and numerology layers.”

2. Store minimum necessary profile fields.
   - Prefer storing DOB locally in v1 if accounts are not required.
   - If backend persistence exists, store derived fields where possible.

3. Do not train on user palm images by default.

4. Keep entertainment disclaimer available in onboarding/settings.

5. Avoid sensitive inference categories:
   - gender unless provided;
   - ethnicity;
   - sexuality;
   - pregnancy/fertility;
   - health diagnosis;
   - income/class;
   - trauma history.

6. Use soft prediction language:
   - “the next few weeks favor…” not “you will…”

---

## 10. Implementation tasks

### Task 1: Add personalization model types

**Objective:** Define shared frontend/backend fields for lightweight personalization.

**Files:**
- Modify: `backend/src/index.ts`
- Modify: `ios/PalmAura/PalmAura/Models/PalmReadingResponse.swift` or create `ios/PalmAura/PalmAura/Models/PalmReadingPersonalization.swift`
- Modify: `ios/PalmAura/PalmAura/Services/ReadingAPIClient.swift`

**Acceptance criteria:**
- iOS can encode personalization into the `/api/read` request.
- Backend validates optional fields and ignores unknown values safely.
- Existing reading calls still work with no personalization object.

---

### Task 2: Add first-reading personalization UI

**Objective:** Collect DOB, uploaded hand, dominant hand, and focus area with minimal friction.

**Files:**
- Modify/create around: `ios/PalmAura/PalmAura/Views/OnboardingView.swift`
- Modify/create around: `ios/PalmAura/PalmAura/Views/PalmReviewView.swift`
- Possibly create: `ios/PalmAura/PalmAura/Views/PersonalizationView.swift`

**Acceptance criteria:**
- User can complete a reading without optional fields.
- Required-for-personalization fields are easy to skip.
- Copy explains why birthday is useful.
- No gender inference or gender question in v1.

---

### Task 3: Persist local personalization preferences

**Objective:** Avoid asking the same context every reading.

**Files:**
- Create: `ios/PalmAura/PalmAura/Services/PersonalizationStore.swift`
- Modify: app flow where reading starts.

**Acceptance criteria:**
- Birthday/dominant hand/tone/focus defaults are saved locally.
- User can clear or edit personalization in settings.
- No palm image storage changes beyond existing local photo rules.

---

### Task 4: Add derived context helpers on backend

**Objective:** Convert DOB and hand fields into safer model-ready context.

**Files:**
- Modify: `backend/src/index.ts`
- Optional create: `backend/src/personalization.ts`

**Acceptance criteria:**
- DOB derives age, age band, western zodiac sun sign, Chinese zodiac, numerology life path, and personal year.
- Uploaded/dominant hand derives `uploadedHandRole`.
- Invalid DOB is ignored, not fatal.
- Under-18 handling is conservative and avoids adult relationship/career assumptions.

---

### Task 5: Add structured palm feature extraction

**Objective:** Split image interpretation from final report generation.

**Files:**
- Modify: `backend/src/index.ts`
- Optional create: `backend/src/palmFeatures.ts`

**Acceptance criteria:**
- Backend gets a `PalmFeatureSet` JSON object before final synthesis.
- Feature extraction has confidence fields.
- Low-confidence images generate softer, less specific language.
- Feature set is available for debugging/logging without exposing sensitive data in UI.

---

### Task 6: Rewrite final synthesis prompt

**Objective:** Force readings to cite palm evidence + user context rather than generic personality claims.

**Files:**
- Modify: `backend/src/index.ts`
- Optional create: `backend/src/prompts.ts`

**Acceptance criteria:**
- Prompt requires concrete citations from palm features and user context.
- Prompt includes safety restrictions.
- Prompt includes anti-generic criteria.
- Output mentions focus area and hand role when available.

---

### Task 7: Update response schema for grounded sections

**Objective:** Return structured report sections that the UI can render well.

**Files:**
- Modify: `backend/src/index.ts`
- Modify: `ios/PalmAura/PalmAura/Models/PalmReadingResponse.swift`
- Modify: `ios/PalmAura/PalmAura/Views/ReadingResultView.swift`
- Modify: `ios/PalmAura/PalmAura/Views/PalmMapView.swift` if line-specific copy is affected.

**Acceptance criteria:**
- Existing text report still renders.
- New sections render if present.
- Old backend response does not crash client.

---

### Task 8: Add QA fixtures and before/after evaluation

**Objective:** Verify that outputs are actually less generic.

**Files:**
- Create: `docs/evals/palm-reading-specificity-rubric.md`
- Create: `backend/test/fixtures/personalization/*.json` if backend test setup exists.

**Acceptance criteria:**
- At least 8 fixture personas across different age bands/focus areas.
- Same palm + different context produces meaningfully different readings.
- Different palms + same context cite different visual evidence.
- No fixture output mentions gender unless explicitly provided.

---

### Task 9: Settings and privacy copy

**Objective:** Make personalization feel trustworthy, not creepy.

**Files:**
- Modify: `ios/PalmAura/PalmAura/Views/SettingsView.swift`
- Modify: `ios/PalmAura/PalmAura/Views/DisclaimerView.swift`

**Acceptance criteria:**
- User can see/edit/clear personalization data.
- Birthday usage is explained plainly.
- Entertainment-only disclaimer is visible.
- Safety copy avoids over-apologizing or killing the magic.

---

## 11. Evaluation rubric

Score each generated reading 1-5 on:

1. **Palm grounding** — Does it reference visible palm traits specifically?
2. **Context use** — Does it use DOB/age/focus/hand role naturally?
3. **Plausibility** — Does it avoid wild claims and stereotypes?
4. **Actionability** — Does it give a useful next move?
5. **Tone fit** — Does it match selected tone?
6. **Non-genericness** — Could this apply to anyone?
7. **Safety** — Does it avoid prohibited sensitive claims?

Target for v1: average score >= 4.0 across hand-picked fixtures before shipping.

---

## 12. Example v1 output target

Input context:

- DOB: 1993-11-04
- Age band: 25-34
- Zodiac: Scorpio
- Focus: career
- Life season: under pressure
- Dominant hand: right
- Uploaded hand: right
- Palm features: long slightly downward head line, medium-depth life line with wide curve, light curved heart line, many fine secondary lines.

Output style:

> Your dominant hand is the one shown here, so this reading leans toward who you are actively becoming rather than only what you inherited. The long, slightly downward head line suggests imagination and pattern recognition, but the medium-depth life line keeps the reading practical: you are not just dreaming about a different path, you are trying to make it usable in real life.
>
> Since you asked about career, the many fine secondary lines matter. They point to mental load — not weakness, more like too many open tabs. At your current life stage, this reads less like “find your purpose” and more like “choose which opportunities deserve your intensity.” The Scorpio layer reinforces that: you are better at deep commitment than casual experimentation, so the wrong work drains you faster than it might drain someone else.
>
> Pattern to watch: waiting for total certainty before moving. Your palm suggests clarity arrives after a contained step, not before it.
>
> Next useful move: choose one reversible career experiment you can complete in seven days — a pitch, a portfolio piece, a conversation, or a prototype — and judge from evidence, not rumination.

---

## 13. Do-not-build-yet list

Do not build these until after v1 output quality is proven:

- Full astrology chart with birth time/location.
- Gender inference from hand.
- Social graph / compatibility engine.
- Long personality quiz.
- Medical/health palm modules.
- Paid “expert reader” marketplace.
- Complex account sync unless retention requires it.
- Fine-tuned palmistry model.

---

## 14. Recommended build order

1. Backend schema accepts personalization object.
2. Backend derives DOB-based context.
3. Backend does structured palm feature extraction.
4. Backend synthesis prompt becomes evidence-grounded.
5. iOS sends basic personalization fields.
6. iOS stores fields locally.
7. Report UI renders grounded sections.
8. QA fixtures compare old vs new outputs.
9. Privacy/settings copy ships.

This sequence lets us test the core quality improvement before over-investing in UX polish.

---

## 15. Open product decisions

1. Should DOB be required for first reading, or skippable with a “less personalized” note?
2. Should relationship/career stage be collected upfront or only after a user chooses love/career focus?
3. Should the app save DOB locally only, or does the backend already have account/profile persistence?
4. Should the first version expose the astrology/numerology layer explicitly, or weave it into the report quietly?
5. Should “Ask your palm one question” be v1, or defer until the base report is stronger?

---

## 16. Recommendation

Ship the lean version first:

- DOB
- dominant hand
- uploaded hand
- focus area
- life season
- tone
- structured palm features
- evidence-grounded reading synthesis

Defer gender inference. It adds risk without enough quality upside. If pronouns become necessary for copy, ask explicitly and make it optional.

The biggest unlock is not a longer prompt. It is this pipeline:

```text
Palm image → structured palm features
User profile → age/zodiac/life-stage context
Current intent → focus/question/tone
Reading generator → claims grounded in evidence
QA rubric → reject generic output
```
