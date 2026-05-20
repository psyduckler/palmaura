import { z } from 'zod';

export interface Env {
  ANTHROPIC_API_KEY?: string;
  ANTHROPIC_MODEL?: string;
  PUBLIC_APP_NAME?: string;
  PUBLIC_APP_DOMAIN?: string;
  PUBLIC_APP_HANDLE?: string;
  RATE_LIMIT_KV?: KVNamespace;
  VERSION?: string;
}

const Focus = z.enum(['love', 'career', 'money', 'family', 'self', 'purpose', 'general']);
const ResponseFocus = z.enum(['love', 'career', 'self', 'purpose', 'general']);
const LifeSeason = z.enum(['new_beginning', 'big_decision', 'healing', 'building_momentum', 'feeling_stuck', 'unknown']);
const ReadingStyle = z.enum(['gentle', 'direct', 'mysterious', 'deep_spiritual']);
const Handedness = z.enum(['left', 'right', 'ambidextrous']);
const ScannedHand = z.enum(['left', 'right']);
const Gender = z.enum(['woman', 'man', 'non_binary', 'prefer_not_to_say']);
const BirthDateContextSchema = z.object({
  month: z.number().int().min(1).max(12),
  day: z.number().int().min(1).max(31),
  // Do not compute this with `new Date()` at module/schema creation time.
  // Cloudflare's Worker bundling/runtime can evaluate module-scope dates as the
  // Unix epoch, which turned the max into 1970 and rejected valid birthdays.
  // The iOS client constrains this to the current year; the backend derives no
  // age for implausible future years, but accepts the request instead of making
  // the reading flow fail with "Invalid request.".
  year: z.number().int().min(1900).max(2100),
}).refine((value) => isValidBirthDate(value.month, value.day, value.year), { message: 'Invalid birth date' });
const ReadingPersonalizationSchema = z.object({
  gender: Gender.optional(),
  handedness: Handedness.optional(),
  scannedHand: ScannedHand.optional(),
  birthDate: BirthDateContextSchema.optional(),
  timeZoneIdentifier: z.string().trim().max(80).optional(),
  localeRegionCode: z.string().trim().max(16).optional(),
  locationOverride: z.string().trim().max(80).optional(),
  // Session-only intent from the iOS ask screen. Stored with the reading, not profile.
  question: z.string().trim().max(200).optional(),
});

const RequestSchema = z.object({
  clientRequestId: z.string().uuid(),
  deviceId: z.string().min(1).max(128),
  appVersion: z.string().min(1).max(32),
  locale: z.string().min(1).max(64),
  imageBase64Jpeg: z.string().min(100).max(1_400_000),
  onboarding: z.object({
    focus: Focus,
    lifeSeason: LifeSeason,
    readingStyle: ReadingStyle,
    personalization: ReadingPersonalizationSchema.optional(),
  }),
});

const MAX_INFERRED_HAND_EVIDENCE_CHARS = 500;
const MAX_NEXT_READING_HOOK_CHARS = 240;
const VALID_AURA_COLORS = new Set(['violet', 'gold', 'fire', 'moon', 'water', 'rose']);
const AURA_COLOR_ALIASES: Record<string, string> = {
  earth: 'gold',
  earthy: 'gold',
  sun: 'gold',
  solar: 'gold',
  orange: 'fire',
  red: 'fire',
  flame: 'fire',
  blue: 'water',
  ocean: 'water',
  aqua: 'water',
  pink: 'rose',
  purple: 'violet',
  lavender: 'violet',
  lunar: 'moon',
  silver: 'moon',
};
const VALID_FOCUSES = new Set(['love', 'career', 'money', 'family', 'self', 'purpose', 'general']);
const VALID_NEXT_READING_HOOK_FOCUSES = new Set(['love', 'career', 'self', 'purpose', 'general']);
const FOCUS_ALIASES: Record<string, string> = {
  relationship: 'love',
  relationships: 'love',
  romance: 'love',
  work: 'career',
  // `money` and `family` are now first-class focuses (added 2026-05-19); the
  // previous money→career and family→self aliases are intentionally removed so
  // the prompt can distinguish them. Aliases below remain for typos / synonyms.
  finances: 'money',
  household: 'family',
  identity: 'self',
  personal: 'self',
  meaning: 'purpose',
};
const NEXT_READING_HOOK_FOCUS_ALIASES: Record<string, string> = {
  ...FOCUS_ALIASES,
  // Keep response hooks backward-compatible with shipped iOS clients whose
  // strict ReadingFocus decoder does not know about money/family yet.
  money: 'career',
  finances: 'career',
  family: 'self',
  household: 'self',
};

const InferredScannedHandSchema = z.object({
  hand: z.enum(['left', 'right', 'unknown']).default('unknown'),
  confidence: z.number().min(0).max(1).default(0),
  role: z.enum(['dominant', 'non_dominant', 'ambidextrous', 'unknown']).default('unknown'),
  evidence: z.string().max(MAX_INFERRED_HAND_EVIDENCE_CHARS).default(''),
});

const inferredScannedHandToolSchema = {
  type: 'object',
  description: 'The visible hand inferred from the image and its role compared with the user-provided dominant hand. Required when status=ok.',
  properties: {
    hand: { type: 'string', enum: ['left', 'right', 'unknown'] },
    confidence: { type: 'number', minimum: 0, maximum: 1 },
    role: { type: 'string', enum: ['dominant', 'non_dominant', 'ambidextrous', 'unknown'] },
    evidence: {
      type: 'string',
      maxLength: MAX_INFERRED_HAND_EVIDENCE_CHARS,
      description: 'One short visual reason, e.g. thumb appears on image-right so this looks like a left palm. Keep under 180 characters when possible.',
    },
  },
  required: ['hand', 'confidence', 'role', 'evidence'],
} as const;

const ReadingSchema = z.object({
  status: z.enum(['ok', 'not_palm', 'bad_image']),
  title: z.string().default(''),
  oneLineSummary: z.string().default(''),
  auraColor: z.enum(['violet', 'gold', 'fire', 'moon', 'water', 'rose']).default('violet'),
  archetype: z.string().default(''),
  inferredScannedHand: InferredScannedHandSchema.optional(),
  report: z.object({
    heartLine: z.string().default(''),
    headLine: z.string().default(''),
    lifeLine: z.string().default(''),
    fateLine: z.string().default(''),
    currentSeason: z.string().default(''),
    guidance: z.string().default(''),
    ritual: z.string().default(''),
  }).default({ heartLine: '', headLine: '', lifeLine: '', fateLine: '', currentSeason: '', guidance: '', ritual: '' }),
  rejectionMessage: z.string().optional(),
  nextReadingHook: z.object({ focus: ResponseFocus, teaser: z.string().max(MAX_NEXT_READING_HOOK_CHARS) }).optional(),
});

type ReadingRequest = z.infer<typeof RequestSchema>;
type Reading = z.infer<typeof ReadingSchema>;

const DAILY_SCAN_LIMIT = 100;

const TOOL = {
  name: 'return_reading',
  description: 'Return the structured PalmAura reading or rejection.',
  input_schema: {
    type: 'object',
    properties: {
      status: { type: 'string', enum: ['ok', 'not_palm', 'bad_image'] },
      title: { type: 'string' },
      oneLineSummary: { type: 'string' },
      auraColor: { type: 'string', enum: ['violet', 'gold', 'fire', 'moon', 'water', 'rose'] },
      archetype: { type: 'string' },
      inferredScannedHand: inferredScannedHandToolSchema,
      report: {
        type: 'object',
        properties: {
          heartLine: { type: 'string' },
          headLine: { type: 'string' },
          lifeLine: { type: 'string' },
          fateLine: { type: 'string' },
          currentSeason: { type: 'string' },
          guidance: { type: 'string' },
          ritual: { type: 'string' },
        },
        required: ['heartLine', 'headLine', 'lifeLine', 'fateLine', 'currentSeason', 'guidance', 'ritual'],
      },
      rejectionMessage: { type: 'string' },
      nextReadingHook: {
        type: 'object',
        properties: {
          focus: { type: 'string', enum: ['love', 'career', 'self', 'purpose', 'general'] },
          teaser: { type: 'string', maxLength: MAX_NEXT_READING_HOOK_CHARS },
        },
        required: ['focus', 'teaser'],
      },
    },
    required: ['status', 'title', 'oneLineSummary', 'auraColor', 'archetype', 'report'],
  },
} as const;

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,HEAD,POST,OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type',
  'Access-Control-Max-Age': '86400',
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers: corsHeaders });

    if ((request.method === 'GET' || request.method === 'HEAD') && url.pathname === '/api/health') {
      return json({
        ok: true,
        service: env.PUBLIC_APP_NAME ?? 'PalmAura',
        version: env.VERSION ?? 'local',
        rateLimit: Boolean(env.RATE_LIMIT_KV),
      }, { status: 200, head: request.method === 'HEAD' });
    }

    if ((request.method === 'GET' || request.method === 'HEAD') && url.pathname === '/api/edge-context') {
      return json(edgeLocationFromRequest(request), { status: 200, head: request.method === 'HEAD' });
    }

    if (request.method === 'POST' && url.pathname === '/api/read') {
      return handleRead(request, env);
    }

    return json({ error: 'not_found', message: 'Route not found.' }, { status: 404 });
  },
};

async function handleRead(request: Request, env: Env): Promise<Response> {
  const body = await request.json().catch(() => null);
  const parsed = RequestSchema.safeParse(body);
  if (!parsed.success) {
    return json({ error: 'invalid_request', message: 'Invalid request.' }, { status: 400 });
  }

  const rate = await checkRateLimit(env, parsed.data.deviceId);
  if (!rate.allowed) {
    return json({
      error: 'rate_limited',
      retryAfterSeconds: rate.retryAfterSeconds,
      message: "You've used your free readings today. Come back tomorrow ✨",
    }, { status: 429, headers: { 'Retry-After': String(rate.retryAfterSeconds) } });
  }

  try {
    const reading = await generateReading(env, parsed.data, edgeLocationFromRequest(request));
    const appName = env.PUBLIC_APP_NAME ?? 'PalmAura';
    return json({
      readingId: crypto.randomUUID(),
      ...reading,
      entertainmentDisclaimer: `${appName} readings are symbolic entertainment and self-reflection only.`,
      createdAt: new Date().toISOString(),
    }, { status: 200 });
  } catch (error) {
    console.error('reading_failed', error instanceof Error ? error.message : String(error));
    return json({ error: 'server_error', message: 'The reading was interrupted. Try again.' }, { status: 502 });
  }
}

function edgeLocationFromRequest(request: Request): EdgeLocationContext {
  const cf = (request as Request & { cf?: Record<string, unknown> }).cf ?? {};
  return {
    city: cleanString(cf.city),
    region: cleanString(cf.region) ?? cleanString(cf.regionCode),
    country: cleanString(cf.country),
    timezone: cleanString(cf.timezone),
  };
}

function cleanString(value: unknown): string | undefined {
  if (typeof value !== 'string') return undefined;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : undefined;
}

async function checkRateLimit(env: Env, deviceId: string): Promise<{ allowed: boolean; retryAfterSeconds: number }> {
  if (!env.RATE_LIMIT_KV) return { allowed: true, retryAfterSeconds: 0 };

  const day = new Date().toISOString().slice(0, 10);
  const key = `palmaura:rl:${hashDeviceId(deviceId)}:${day}`;
  const existing = Number(await env.RATE_LIMIT_KV.get(key) ?? '0');
  const next = existing + 1;
  await env.RATE_LIMIT_KV.put(key, String(next), { expirationTtl: 90_000 });
  return { allowed: next <= DAILY_SCAN_LIMIT, retryAfterSeconds: 86_400 };
}

function hashDeviceId(deviceId: string): string {
  // Lightweight non-cryptographic minimization so raw IDFV/device IDs are not stored as KV keys.
  let hash = 2166136261;
  for (let i = 0; i < deviceId.length; i += 1) {
    hash ^= deviceId.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0).toString(16).padStart(8, '0');
}

type ReadingPersonalization = z.infer<typeof ReadingPersonalizationSchema>;
type EdgeLocationContext = {
  city?: string;
  region?: string;
  country?: string;
  timezone?: string;
};
type DerivedContext = {
  sunSign?: string;
  age?: number;
  ageBand?: 'under_25' | '25_34' | '35_44' | '45_54' | '55_plus';
  handRole?: 'dominant' | 'non_dominant';
  handPhrase?: string;
  palmistryFrame?: string;
  genderPhrase?: string;
};

function isValidBirthDate(month: number, day: number, year?: number): boolean {
  const safeYear = year ?? 2024; // leap year so Feb 29 is valid without collecting a year.
  const date = new Date(Date.UTC(safeYear, month - 1, day));
  return date.getUTCFullYear() === safeYear && date.getUTCMonth() === month - 1 && date.getUTCDate() === day;
}

function deriveSunSign(month: number, day: number): string | undefined {
  const md = month * 100 + day;
  if (md >= 321 && md <= 419) return 'aries';
  if (md >= 420 && md <= 520) return 'taurus';
  if (md >= 521 && md <= 620) return 'gemini';
  if (md >= 621 && md <= 722) return 'cancer';
  if (md >= 723 && md <= 822) return 'leo';
  if (md >= 823 && md <= 922) return 'virgo';
  if (md >= 923 && md <= 1022) return 'libra';
  if (md >= 1023 && md <= 1121) return 'scorpio';
  if (md >= 1122 && md <= 1221) return 'sagittarius';
  if (md >= 1222 || md <= 119) return 'capricorn';
  if (md >= 120 && md <= 218) return 'aquarius';
  if (md >= 219 && md <= 320) return 'pisces';
  return undefined;
}

function deriveAge(year: number, month: number, day: number, now = new Date()): number | undefined {
  if (!isValidBirthDate(month, day, year)) return undefined;
  let age = now.getUTCFullYear() - year;
  const birthdayThisYear = Date.UTC(now.getUTCFullYear(), month - 1, day);
  const today = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
  if (today < birthdayThisYear) age -= 1;
  return age >= 0 && age <= 125 ? age : undefined;
}

function deriveAgeBand(age?: number): DerivedContext['ageBand'] | undefined {
  if (age === undefined) return undefined;
  if (age < 25) return 'under_25';
  if (age <= 34) return '25_34';
  if (age <= 44) return '35_44';
  if (age <= 54) return '45_54';
  return '55_plus';
}

function buildDerivedContext(personalization?: ReadingPersonalization): DerivedContext {
  const derived: DerivedContext = {};
  if (personalization?.birthDate) {
    const { month, day, year } = personalization.birthDate;
    derived.sunSign = deriveSunSign(month, day);
    derived.age = deriveAge(year, month, day);
    derived.ageBand = deriveAgeBand(derived.age);
  }
  if (personalization?.gender) {
    derived.genderPhrase = personalization.gender === 'prefer_not_to_say' ? 'prefer not to say' : personalization.gender.replace('_', '-');
  }
  if (personalization?.handedness) {
    if (personalization.scannedHand && personalization.handedness !== 'ambidextrous') {
      derived.handRole = personalization.handedness === personalization.scannedHand ? 'dominant' : 'non_dominant';
      derived.handPhrase = `${derived.handRole === 'dominant' ? 'dominant' : 'non-dominant'} ${personalization.scannedHand} hand`;
      derived.palmistryFrame = derived.handRole === 'dominant'
        ? 'current choices, active path, and what the user is doing with their potential'
        : 'inherited tendencies, inner pattern, past, and potential';
    } else {
      derived.handPhrase = personalization.handedness === 'ambidextrous' ? 'ambidextrous dominant hands' : `${personalization.handedness} dominant hand`;
      derived.palmistryFrame = 'dominant-hand context: current choices, active path, and what the user is doing with their potential';
    }
  }
  return derived;
}

function ageBandGuidance(ageBand?: DerivedContext['ageBand']): string {
  switch (ageBand) {
    case 'under_25': return 'identity, first big choices, independence, and direction';
    case '25_34': return 'momentum, career/love filtering, ambition versus burnout';
    case '35_44': return 'leadership, family or legacy pressure, and reinvention';
    case '45_54': return 'recalibration, second-act energy, and obligations versus freedom';
    case '55_plus': return 'wisdom, simplification, legacy, and self-authorship';
    default: return 'not provided';
  }
}

function buildSystemPrompt(env: Env): string {
  const appName = env.PUBLIC_APP_NAME ?? 'PalmAura';
  return `You are ${appName}, a cheeky mystical palm oracle for symbolic entertainment ONLY. Sound like a sharp, glamorous friend reading the room: playful, specific, a little cosmic, never clinical.

ABSOLUTE SAFETY RULES:
- Never provide medical, legal, financial, psychological, fertility, pregnancy, lifespan, death, diagnosis, or life-critical advice.
- Never predict illness, death, fertility, pregnancy, guaranteed wealth, legal outcomes, or unavoidable future events.
- Never claim certainty. Use language like "suggests," "symbolizes," "hints," "gives," and "points to."
- Never say a person's fate is fixed.
- Do not mention being an AI model.
- Avoid therapy-speak and generic wellness phrasing: do not say "hold space," "inner child," "nervous system," "trauma," "healing journey," "do the work," or "set boundaries" unless the user explicitly asked for that framing.

IMAGE VALIDATION:
- If the image is not clearly a human palm/open hand, return status = "not_palm" and a short friendly rejectionMessage. Do not generate a reading.
- If the image is a palm but too dark, blurry, cropped, or unclear to read, return status = "bad_image" and a short friendly rejectionMessage. Do not fake detailed line observations.
- Only generate status = "ok" when the image appears to contain a human palm/open hand.

HAND INFERENCE:
- When status = "ok", infer whether the visible palm is the user's left hand, right hand, or unknown. Return inferredScannedHand.
- Use anatomy cues from the image as presented: thumb side, pinky side, finger order, thenar/thumb mound, and wrist orientation. Do not guess from camera/device metadata.
- If mirroring, cropping, rotation, or pose makes left/right uncertain, set hand = "unknown", confidence < 0.55, role = "unknown", and do not build the reading around hand role.
- Combine the inferred hand with the provided dominant hand. If dominant hand is left/right and inferred hand matches it, role = "dominant". If it differs, role = "non_dominant". If dominant hand is ambidextrous, role = "ambidextrous". If dominant hand is missing or inference is unknown, role = "unknown".
- If role is dominant, frame the reading as current choices, active path, and what the user is doing with their potential. If role is non_dominant, frame it as inherited tendencies, inner pattern, past, and potential. If role is ambidextrous, frame it as both currents/current-use energy.
- Use a high-confidence inferred role in at least two report sections. If confidence is low, say less — do not pretend.

ORACLE VOICE:
- Be cheeky, concrete, and memorable. Prefer crisp observations over soft reassurance.
- Tie claims to visible palm cues when possible: line depth, curve, spacing, mounts, finger shape, thumb angle, or overall hand energy.
- Use lively specifics ("main-character stamina," "calendar chaos," "velvet hammer honesty") instead of vague advice.
- Keep it symbolic and entertainment-only; no diagnoses, certainty, or real-world guarantees.
- Avoid bland phrases like "embrace your journey," "trust the process," "practice self-care," and "you are enough."

READING STYLE:
- gentle: warm, witty, encouraging, never saccharine
- direct: clear, confident, mystical but no-nonsense
- mysterious: poetic, evocative, layered metaphor, still understandable
- deep_spiritual: sacred, archetypal, transformational, not therapy-ish

SPECIFICITY RULES:
1. Evidence-grounding rule: every meaningful claim must be tied to at least one of: a visible palm feature from the image; line depth/curve/spacing seen in the photo; focus/lifeSeason/readingStyle; dominant-hand context; saved birthday-derived sun sign or age band; saved gender context if relevant; or coarse location/timezone context for timing/place atmosphere if provided. If a claim cannot be grounded, do not make it.
2. Dominant/scanned hand rule: if the client provides scannedHand, use it. If not, infer the visible hand from the image, compare it with the dominant hand, and use the inferred role when confidence >= 0.55. Use known hand role in at least two report sections; if role is unknown/low-confidence, rely on dominant-hand context only and avoid pretending the photo is dominant.
3. Sun sign rule: if sunSign is provided, reference it exactly once across the whole report, preferably in currentSeason or guidance. Do not turn the reading into a horoscope.
4. Age-band rule: if ageBand is provided, adapt life-stage assumptions without over-explaining the age. under_25 = identity/first big choices; 25_34 = momentum/filtering/ambition vs burnout; 35_44 = leadership/reinvention; 45_54 = recalibration/second-act energy; 55_plus = wisdom/simplification/legacy.
5. Gender context rule: do not stereotype or infer pronouns. Use saved gender only lightly when it helps phrasing; if prefer_not_to_say, avoid gendered framing entirely.
6. Banned standalone adjectives: never use creative, intuitive, loyal, sensitive, resilient, or ambitious as freestanding descriptors. You may use one only when the same sentence explains the palm or context evidence behind it.
7. Rule of softness: use "this season favors," "this pattern suggests," "your hand points toward," and "a useful move would be." Never use "you will," "you are destined to," or "this proves."
8. Location context rule: if location context is provided, use it only for local season, time-of-day, and grounded place atmosphere. Never claim it improves visual palm accuracy, never mention precise location, and never imply continuous tracking.

SECTION INTENT:
- heartLine: ground in the visible heart line and the user's focus when relevant.
- headLine: ground in the head line and how the user approaches decisions.
- lifeLine: ground in the life line plus lifeSeason and ageBand when available.
- fateLine: ground in the fate line plus focus/career/purpose when relevant.
- currentSeason: ground in lifeSeason, handRole, and ageBand when available.
- guidance: this is "The Hand's Answer." Give a grounded synthesis with three concrete reasons when natural.
- ritual: this is "Next Useful Move." Give one tiny, doable action for today. Make it concrete, not generic.

GROUNDING:
- Ground observations in visible palm features and/or the user's onboarding answers.
- It is okay to be symbolic, but do not invent concrete facts about the person's real life.
- Make each report section feel distinct; do not repeat the same advice in different outfits.
- Write in second person: "you" and "your hand." Do not infer gender and do not ask for pronouns.

SESSION QUESTION:
- If a session question is provided, the reading must answer it first and directly.
- Use visible hand and palm features as evidence for the answer, not decoration.
- Keep durable profile context secondary: it calibrates the voice and lens, but the session question drives the output.
- Do not generate share/export/social-card copy; this MVP is private by default.`;
}

function buildLocationContext(personalization?: ReadingPersonalization, edgeLocation: EdgeLocationContext = {}): string {
  const manualPlace = cleanString(personalization?.locationOverride);
  const edgePlace = [edgeLocation.city, edgeLocation.region, edgeLocation.country].filter(Boolean).join(', ');
  const localeRegion = cleanString(personalization?.localeRegionCode);
  const placeHint = manualPlace ?? (edgePlace || undefined) ?? (localeRegion ? `Country/region: ${localeRegion}` : undefined);
  const timezone = cleanString(personalization?.timeZoneIdentifier) ?? edgeLocation.timezone;

  if (!placeHint && !timezone) return '- Location context: not provided';

  const source = manualPlace
    ? 'user-provided place override'
    : edgePlace
      ? 'network place hint'
      : 'device locale/timezone';

  return `- Place hint: ${placeHint ?? 'not provided'}
- Timezone: ${timezone ?? 'not provided'}
- Source: ${source}
- Location rule: use only for local season, time-of-day, and grounded place atmosphere. Never claim it improves visual palm accuracy, never mention precise location, and never imply continuous tracking.`;
}

function buildUserPrompt(env: Env, data: ReadingRequest, edgeLocation: EdgeLocationContext = {}): string {
  const appDomain = env.PUBLIC_APP_DOMAIN ?? 'palmaura.app';
  const personalization = data.onboarding.personalization;
  const derived = buildDerivedContext(personalization);
  const birthdayContext = personalization?.birthDate
    ? `- Sun sign: ${derived.sunSign ?? 'unknown'}\n- Age band: ${derived.ageBand ?? 'not provided'}\n- Life-stage lens: ${ageBandGuidance(derived.ageBand)}`
    : '- Birthday context: not provided';
  const handContext = personalization?.handedness
    ? personalization.scannedHand
      ? `- Dominant hand: ${personalization.handedness}\n- Client-provided scanned hand: ${personalization.scannedHand}\n- Hand lens: ${derived.handPhrase}\n- Palmistry frame: ${derived.palmistryFrame}`
      : `- Dominant hand: ${personalization.handedness}\n- Client-provided scanned hand: not provided\n- Hand inference task: infer whether the image shows the left or right palm, then compare it with the dominant hand before choosing dominant vs non-dominant framing.\n- Palmistry frame before image inference: ${derived.palmistryFrame}`
    : '- Hand context: not provided; still infer the visible hand from the image when status=ok, but set role = "unknown".';
  const genderContext = personalization?.gender
    ? `- Gender: ${derived.genderPhrase}`
    : '- Gender: not provided';
  const locationContext = buildLocationContext(personalization, edgeLocation);

  const sessionQuestion = personalization?.question?.trim();
  const sessionIntent = sessionQuestion
    ? `- User's question for this reading: ${sessionQuestion}`
    : '- User skipped a custom question; answer through the selected focus only.';

  return `Session intent:\n- Seeking clarity on: ${data.onboarding.focus}\n${sessionIntent}\n- Current season: ${data.onboarding.lifeSeason}\n- Reading style: ${data.onboarding.readingStyle}\n\nSaved profile context:\n${genderContext}\n${handContext}\n\nBirthday context:\n${birthdayContext}\n\nLocation context:\n${locationContext}\n\nPalm evidence:\n- Use the image itself for symbolic palm observations. The client renders a clean photo map.\n\nRead this palm if it is a clear human palm. If not, return the appropriate status and rejection message. The app domain is ${appDomain}.`;
}

async function generateReading(env: Env, data: ReadingRequest, edgeLocation: EdgeLocationContext = {}): Promise<Reading> {
  if (!env.ANTHROPIC_API_KEY) throw new Error('ANTHROPIC_API_KEY missing');
  const model = env.ANTHROPIC_MODEL ?? 'claude-haiku-4-5-20251001';

  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': env.ANTHROPIC_API_KEY,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model,
      max_tokens: 1800,
      system: buildSystemPrompt(env),
      tools: [TOOL],
      tool_choice: { type: 'tool', name: 'return_reading' },
      messages: [{
        role: 'user',
        content: [
          { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: data.imageBase64Jpeg } },
          { type: 'text', text: buildUserPrompt(env, data, edgeLocation) },
        ],
      }],
    }),
  });

  if (!response.ok) {
    const detail = await response.text().catch(() => '');
    throw new Error(`Anthropic ${response.status}: ${detail.slice(0, 200)}`);
  }

  const result = await response.json() as { content?: Array<{ type: string; input?: unknown }> };
  const toolUse = result.content?.find((item) => item.type === 'tool_use');
  if (!toolUse) throw new Error('No tool_use returned');

  const parsedReading = ReadingSchema.safeParse(normalizeReadingToolInput(toolUse.input));
  if (!parsedReading.success) {
    throw new Error(`Reading schema invalid: ${parsedReading.error.message}`);
  }
  return parsedReading.data;
}

function normalizeReadingToolInput(input: unknown): unknown {
  if (!isRecord(input)) return input;
  const output: Record<string, unknown> = { ...input };

  if (typeof output.auraColor === 'string') {
    output.auraColor = normalizeEnumValue(output.auraColor, VALID_AURA_COLORS, AURA_COLOR_ALIASES, 'violet');
  }

  if (isRecord(output.inferredScannedHand) && typeof output.inferredScannedHand.evidence === 'string') {
    output.inferredScannedHand = {
      ...output.inferredScannedHand,
      evidence: truncateText(output.inferredScannedHand.evidence, MAX_INFERRED_HAND_EVIDENCE_CHARS),
    };
  }

  if (isRecord(output.nextReadingHook)) {
    const focus = typeof output.nextReadingHook.focus === 'string'
      ? normalizeEnumValue(output.nextReadingHook.focus, VALID_NEXT_READING_HOOK_FOCUSES, NEXT_READING_HOOK_FOCUS_ALIASES, 'general')
      : 'general';
    output.nextReadingHook = {
      ...output.nextReadingHook,
      focus,
      teaser: typeof output.nextReadingHook.teaser === 'string'
        ? truncateText(output.nextReadingHook.teaser, MAX_NEXT_READING_HOOK_CHARS)
        : output.nextReadingHook.teaser,
    };
  }

  return output;
}

function normalizeEnumValue(value: string, validValues: Set<string>, aliases: Record<string, string>, fallback: string): string {
  const key = value.trim().toLowerCase().replace(/[\s-]+/g, '_');
  if (validValues.has(key)) return key;
  return aliases[key] ?? fallback;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function truncateText(value: string, maxLength: number): string {
  if (value.length <= maxLength) return value;
  return `${value.slice(0, Math.max(0, maxLength - 1)).trimEnd()}…`;
}

function json(body: unknown, options: { status?: number; headers?: HeadersInit; head?: boolean } = {}): Response {
  return new Response(options.head ? null : JSON.stringify(body, null, 2), {
    status: options.status ?? 200,
    headers: {
      'Content-Type': 'application/json; charset=utf-8',
      ...corsHeaders,
      ...(options.headers ?? {}),
    },
  });
}
