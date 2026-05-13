# PalmAura Cloudflare Worker backend

Minimal Cloudflare Worker API for PalmAura.

## Routes

- `GET /api/health` — health/status check.
- `HEAD /api/health` — health/status check for uptime probes.
- `POST /api/read` — accepts a palm JPEG as base64 plus onboarding answers, enforces 3 readings/day/device when KV is bound, calls Anthropic, and returns the structured PalmAura reading contract.

## Local setup

```bash
cd backend
npm install
npm run typecheck
npm run dev
```

## Cloudflare resources

Create KV namespaces for rate limiting:

```bash
cd backend
npx wrangler kv namespace create RATE_LIMIT_KV
npx wrangler kv namespace create RATE_LIMIT_KV --preview
```

Copy the returned `id` and `preview_id` into `wrangler.toml`.

## Secrets

Do not commit secrets. Set the rotated Anthropic key with Wrangler:

```bash
cd backend
npx wrangler secret put ANTHROPIC_API_KEY
```

The model defaults to the `ANTHROPIC_MODEL` var in `wrangler.toml` and can be changed without app changes.

## Deploy

```bash
cd backend
npm run deploy
curl -i https://<worker-url>/api/health
```

## Privacy notes

PalmAura does not store palm photos in this backend. The Worker forwards the base64 JPEG to Anthropic for real-time processing. Rate limiting stores only a date-scoped hashed device counter in Cloudflare KV.
