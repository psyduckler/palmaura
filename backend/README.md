# PalmAura Backend

Vercel backend for PalmAura.

Endpoints:

- `GET /api/health`
- `POST /api/read`

Safety constraints:

- Do not store palm images.
- Do not log request image payloads.
- Validate all requests/responses.
- Return `not_palm`/`bad_image` instead of fake readings for invalid photos.
- Keep model/API keys server-side only.
