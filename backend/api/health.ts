export default function handler(): Response {
  return Response.json({ ok: true, version: process.env.VERCEL_GIT_COMMIT_SHA ?? 'local' });
}
