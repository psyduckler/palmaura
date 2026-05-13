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

const Focus = z.enum(['love', 'career', 'self', 'purpose', 'general']);
const LifeSeason = z.enum(['new_beginning', 'big_decision', 'healing', 'building_momentum', 'feeling_stuck', 'unknown']);
const ReadingStyle = z.enum(['gentle', 'direct', 'mysterious', 'deep_spiritual']);

const RequestSchema = z.object({
  clientRequestId: z.string().uuid(),
  deviceId: z.string().min(1).max(128),
  appVersion: z.string().min(1).max(32),
  locale: z.string().min(1).max(64),
  imageBase64Jpeg: z.string().min(100).max(1_400_000),
  onboarding: z.object({ focus: Focus, lifeSeason: LifeSeason, readingStyle: ReadingStyle }),
});

const ShareCardSchema = z.object({
  format: z.enum(['aura', 'archetype', 'thirty_day']),
  title: z.string().min(1).max(40),
  body: z.string().min(1).max(180),
  accentColor: z.string().regex(/^#[0-9A-Fa-f]{6}$/),
  theme: z.enum(['moon', 'fire', 'water', 'gold', 'violet', 'rose']),
});

const ReadingSchema = z.object({
  status: z.enum(['ok', 'not_palm', 'bad_image']),
  title: z.string().default(''),
  oneLineSummary: z.string().default(''),
  auraColor: z.enum(['violet', 'gold', 'fire', 'moon', 'water', 'rose']).default('violet'),
  archetype: z.string().default(''),
  shareCards: z.array(ShareCardSchema).default([]),
  report: z.object({
    aura: z.string().default(''),
    heartLine: z.string().default(''),
    headLine: z.string().default(''),
    lifeLine: z.string().default(''),
    fateLine: z.string().default(''),
    currentSeason: z.string().default(''),
    guidance: z.string().default(''),
    ritual: z.string().default(''),
  }).default({ aura: '', heartLine: '', headLine: '', lifeLine: '', fateLine: '', currentSeason: '', guidance: '', ritual: '' }),
  rejectionMessage: z.string().optional(),
  nextReadingHook: z.object({ focus: Focus, teaser: z.string().max(160) }).optional(),
});

type ReadingRequest = z.infer<typeof RequestSchema>;
type Reading = z.infer<typeof ReadingSchema>;

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
      shareCards: {
        type: 'array',
        minItems: 0,
        maxItems: 3,
        items: {
          type: 'object',
          properties: {
            format: { type: 'string', enum: ['aura', 'archetype', 'thirty_day'] },
            title: { type: 'string' },
            body: { type: 'string' },
            accentColor: { type: 'string' },
            theme: { type: 'string', enum: ['moon', 'fire', 'water', 'gold', 'violet', 'rose'] },
          },
          required: ['format', 'title', 'body', 'accentColor', 'theme'],
        },
      },
      report: {
        type: 'object',
        properties: {
          aura: { type: 'string' },
          heartLine: { type: 'string' },
          headLine: { type: 'string' },
          lifeLine: { type: 'string' },
          fateLine: { type: 'string' },
          currentSeason: { type: 'string' },
          guidance: { type: 'string' },
          ritual: { type: 'string' },
        },
        required: ['aura', 'heartLine', 'headLine', 'lifeLine', 'fateLine', 'currentSeason', 'guidance', 'ritual'],
      },
      rejectionMessage: { type: 'string' },
      nextReadingHook: {
        type: 'object',
        properties: {
          focus: { type: 'string', enum: ['love', 'career', 'self', 'purpose', 'general'] },
          teaser: { type: 'string' },
        },
        required: ['focus', 'teaser'],
      },
    },
    required: ['status', 'title', 'oneLineSummary', 'auraColor', 'archetype', 'shareCards', 'report'],
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

    if (request.method === 'POST' && url.pathname === '/api/read') {
      return handleRead(request, env);
    }

    return json({ error: 'not_found', message: 'Route not found.' }, { status: 404 });
  },
};

async function handleRead(request: Request, env: Env): Promise<Response> {
  const body = await request.json().catch(() => null);
  const parsed = RequestSchema.safeParse(body);
  if (!parsed.success) return json({ error: 'invalid_request', message: 'Invalid request.' }, { status: 400 });

  const rate = await checkRateLimit(env, parsed.data.deviceId);
  if (!rate.allowed) {
    return json({
      error: 'rate_limited',
      retryAfterSeconds: rate.retryAfterSeconds,
      message: "You've used your free readings today. Come back tomorrow ✨",
    }, { status: 429, headers: { 'Retry-After': String(rate.retryAfterSeconds) } });
  }

  try {
    const reading = await generateReading(env, parsed.data);
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

async function checkRateLimit(env: Env, deviceId: string): Promise<{ allowed: boolean; retryAfterSeconds: number }> {
  if (!env.RATE_LIMIT_KV) return { allowed: true, retryAfterSeconds: 0 };

  const day = new Date().toISOString().slice(0, 10);
  const key = `palmaura:rl:${hashDeviceId(deviceId)}:${day}`;
  const existing = Number(await env.RATE_LIMIT_KV.get(key) ?? '0');
  const next = existing + 1;
  await env.RATE_LIMIT_KV.put(key, String(next), { expirationTtl: 90_000 });
  return { allowed: next <= 3, retryAfterSeconds: 86_400 };
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

function buildSystemPrompt(env: Env): string {
  const appName = env.PUBLIC_APP_NAME ?? 'PalmAura';
  return `You are ${appName}, a polished mystical palm-reading guide for symbolic entertainment and self-reflection ONLY.

ABSOLUTE SAFETY RULES:
- Never provide medical, legal, financial, psychological, fertility, pregnancy, lifespan, death, diagnosis, or life-critical advice.
- Never predict illness, death, fertility, pregnancy, guaranteed wealth, legal outcomes, or unavoidable future events.
- Never claim certainty. Use language like "suggests," "symbolizes," "may point to," and "invites you to reflect on."
- Never say a person's fate is fixed.
- Do not mention being an AI model.

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
Generate exactly 3 share cards when status = "ok": aura, archetype, thirty_day. Each title <= 4 words. Each body <= 22 words. Cards should be punchy for Instagram/TikTok sharing.`;
}

function buildUserPrompt(env: Env, data: ReadingRequest): string {
  const appDomain = env.PUBLIC_APP_DOMAIN ?? 'palmaura.app';
  return `Onboarding context:\n- Seeking clarity on: ${data.onboarding.focus}\n- Current season: ${data.onboarding.lifeSeason}\n- Reading style: ${data.onboarding.readingStyle}\n\nRead this palm if it is a clear human palm. If not, return the appropriate status and rejection message. The app domain is ${appDomain}.`;
}

async function generateReading(env: Env, data: ReadingRequest): Promise<Reading> {
  if (!env.ANTHROPIC_API_KEY) throw new Error('ANTHROPIC_API_KEY missing');
  const model = env.ANTHROPIC_MODEL ?? 'claude-sonnet-4-5-20250929';

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
          { type: 'text', text: buildUserPrompt(env, data) },
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

  const reading = ReadingSchema.parse(toolUse.input);
  if (reading.status === 'ok' && reading.shareCards.length !== 3) throw new Error('Expected exactly 3 share cards');
  return reading;
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
