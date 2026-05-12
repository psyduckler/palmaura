import Anthropic from '@anthropic-ai/sdk';
import { Redis } from '@upstash/redis';
import { z } from 'zod';

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
    aura: z.string().default(''), heartLine: z.string().default(''), headLine: z.string().default(''), lifeLine: z.string().default(''), fateLine: z.string().default(''), currentSeason: z.string().default(''), guidance: z.string().default(''), ritual: z.string().default(''),
  }).default({ aura: '', heartLine: '', headLine: '', lifeLine: '', fateLine: '', currentSeason: '', guidance: '', ritual: '' }),
  rejectionMessage: z.string().optional(),
  nextReadingHook: z.object({ focus: Focus, teaser: z.string() }).optional(),
});

type ReadingRequest = z.infer<typeof RequestSchema>;

const APP_NAME = process.env.PUBLIC_APP_NAME ?? 'PalmAura';
const APP_DOMAIN = process.env.PUBLIC_APP_DOMAIN ?? 'palmaura.app';
const MODEL = process.env.ANTHROPIC_MODEL ?? 'claude-sonnet-4-5-20250929';

const SYSTEM_PROMPT = `You are ${APP_NAME}, a polished mystical palm-reading guide for symbolic entertainment and self-reflection ONLY.

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

const TOOL: Anthropic.Messages.Tool = {
  name: 'return_reading',
  description: 'Return the structured PalmAura reading or rejection.',
  input_schema: {
    type: 'object',
    properties: {
      status: { type: 'string', enum: ['ok', 'not_palm', 'bad_image'] },
      title: { type: 'string' }, oneLineSummary: { type: 'string' }, auraColor: { type: 'string', enum: ['violet', 'gold', 'fire', 'moon', 'water', 'rose'] }, archetype: { type: 'string' },
      shareCards: { type: 'array', minItems: 0, maxItems: 3, items: { type: 'object', properties: { format: { type: 'string', enum: ['aura', 'archetype', 'thirty_day'] }, title: { type: 'string' }, body: { type: 'string' }, accentColor: { type: 'string' }, theme: { type: 'string', enum: ['moon', 'fire', 'water', 'gold', 'violet', 'rose'] } }, required: ['format', 'title', 'body', 'accentColor', 'theme'] } },
      report: { type: 'object', properties: { aura: { type: 'string' }, heartLine: { type: 'string' }, headLine: { type: 'string' }, lifeLine: { type: 'string' }, fateLine: { type: 'string' }, currentSeason: { type: 'string' }, guidance: { type: 'string' }, ritual: { type: 'string' } }, required: ['aura', 'heartLine', 'headLine', 'lifeLine', 'fateLine', 'currentSeason', 'guidance', 'ritual'] },
      rejectionMessage: { type: 'string' },
      nextReadingHook: { type: 'object', properties: { focus: { type: 'string', enum: ['love', 'career', 'self', 'purpose', 'general'] }, teaser: { type: 'string' } }, required: ['focus', 'teaser'] }
    },
    required: ['status', 'title', 'oneLineSummary', 'auraColor', 'archetype', 'shareCards', 'report']
  }
};

export default async function handler(req: Request): Promise<Response> {
  if (req.method !== 'POST') return Response.json({ error: 'invalid_request', message: 'Method not allowed.' }, { status: 405 });
  const body = await req.json().catch(() => null);
  const parsed = RequestSchema.safeParse(body);
  if (!parsed.success) return Response.json({ error: 'invalid_request', message: 'Invalid request.' }, { status: 400 });

  const rate = await checkRateLimit(parsed.data.deviceId);
  if (!rate.allowed) return Response.json({ error: 'rate_limited', retryAfterSeconds: rate.retryAfterSeconds, message: "You've used your free readings today. Come back tomorrow ✨" }, { status: 429 });

  try {
    const reading = await generateReading(parsed.data);
    return Response.json({ readingId: crypto.randomUUID(), ...reading, entertainmentDisclaimer: `${APP_NAME} readings are symbolic entertainment and self-reflection only.`, createdAt: new Date().toISOString() });
  } catch (error) {
    console.error('reading_failed', error instanceof Error ? error.message : String(error));
    return Response.json({ error: 'server_error', message: 'The reading was interrupted. Try again.' }, { status: 502 });
  }
}

async function checkRateLimit(deviceId: string): Promise<{ allowed: boolean; retryAfterSeconds: number }> {
  if (!process.env.UPSTASH_REDIS_REST_URL || !process.env.UPSTASH_REDIS_REST_TOKEN) return { allowed: true, retryAfterSeconds: 0 };
  const redis = new Redis({ url: process.env.UPSTASH_REDIS_REST_URL, token: process.env.UPSTASH_REDIS_REST_TOKEN });
  const day = new Date().toISOString().slice(0, 10);
  const key = `palmaura:rl:${deviceId}:${day}`;
  const count = await redis.incr(key);
  if (count === 1) await redis.expire(key, 86400);
  return { allowed: count <= 3, retryAfterSeconds: 86400 };
}

function buildUserPrompt(data: ReadingRequest): string {
  return `Onboarding context:\n- Seeking clarity on: ${data.onboarding.focus}\n- Current season: ${data.onboarding.lifeSeason}\n- Reading style: ${data.onboarding.readingStyle}\n\nRead this palm if it is a clear human palm. If not, return the appropriate status and rejection message. The app domain is ${APP_DOMAIN}.`;
}

async function generateReading(data: ReadingRequest): Promise<z.infer<typeof ReadingSchema>> {
  if (!process.env.ANTHROPIC_API_KEY) throw new Error('ANTHROPIC_API_KEY missing');
  const client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
  const result = await client.messages.create({
    model: MODEL,
    max_tokens: 1800,
    system: SYSTEM_PROMPT,
    tools: [TOOL],
    tool_choice: { type: 'tool', name: 'return_reading' },
    messages: [{ role: 'user', content: [
      { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: data.imageBase64Jpeg } },
      { type: 'text', text: buildUserPrompt(data) }
    ] }]
  });
  const toolUse = result.content.find((c) => c.type === 'tool_use');
  if (!toolUse || toolUse.type !== 'tool_use') throw new Error('No tool_use returned');
  const reading = ReadingSchema.parse(toolUse.input);
  if (reading.status === 'ok' && reading.shareCards.length !== 3) throw new Error('Expected exactly 3 share cards');
  return reading;
}
