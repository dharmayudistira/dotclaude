# Security Rules

## Auth gate

Next 16 renamed `middleware.ts` to `proxy.ts`. The runtime proxy lives at `src/proxy.ts` and delegates to `src/lib/supabase/proxy.ts`'s `updateSession()` — the source of truth for redirect logic:

- Unauthenticated + non-public path → `/auth/login`
- Authenticated + on `/auth/*` → `/dashboard`
- Authenticated + `user_preferences.onboarding_completed_at IS NULL` → `/onboarding`

The `(protected)` layout has an `isOnboarding` branch that mirrors this. **Both must agree.** When changing one, change the other in the same commit.

**Cookies on redirect.** A bare `NextResponse.redirect(url)` does NOT carry over the cookies that `setAll` wrote to `supabaseResponse`. Token-refresh cookies get lost, the browser keeps stale tokens, and the user is bounced to `/auth/login` on the next request. Every redirect path must clone cookies from the current `supabaseResponse` onto the redirect response. Use the `redirectPreservingCookies` helper.

Public paths: `/`, `/privacy`, `/terms`, `/auth/*`.

## Three Supabase clients (do not mix)

| Client | File | Use in | Bypasses RLS |
|--------|------|--------|--------------|
| Browser | `@/lib/supabase/client` | Client components, hooks | No |
| Server | `@/lib/supabase/server` | RSC, route handlers, server actions | No |
| Admin | `@/lib/supabase/admin` | Server-only, bypass-RLS writes | **Yes** |

The admin client throws if imported in a browser bundle (Next will tree-shake it correctly only if you respect the `'use server'` / route handler boundary).

**Rule**: only use admin when there is no other way. Comment the reason above the import. Today's legitimate uses:
- `exchange_rates` seeding (cron / API).
- `ai_summaries` insert (server-side AI pipeline writes; users only read).
- E2E test cleanup.

If you reach for admin to "skip RLS for convenience," you are doing the wrong thing. Fix the policy instead.

## RLS

Every per-user table has RLS enabled with `auth.uid() = user_id` policies. See `database.md` for the template.

When adding a new per-user table, **the migration must include the RLS policies**. CI's migration validator will eventually catch this; for now, the reviewer subagent and code review are the gates.

## Env vars

Required:
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_ROLE_KEY` (server-only — never expose)
- `ANTHROPIC_API_KEY` (server-only)

Optional:
- `EDGE_FUNCTION_SECRET` (server-only, gates POSTs to `sync-benchmarks` and `update-exchange-rate` Edge Functions)

Browser-callable price/search/historical routes are auth-gated (Supabase session cookie required), not secret-gated — a browser cannot safely send a server-only secret.

Rules:
- Anything starting with `NEXT_PUBLIC_` is shipped to the browser. Treat as public.
- Service role key, Anthropic key, cron secret: server only. Never read in a `'use client'` file.
- `.env.local` is git-ignored. Never commit. Never paste into chat or PR.
- Vercel: set env vars in dashboard, not in code. CI: GitHub Actions secrets.

## Headers

`next.config.ts` sets:
- `X-Frame-Options: DENY`
- `X-Content-Type-Options: nosniff`
- `Referrer-Policy: strict-origin-when-cross-origin`
- `Permissions-Policy` blocks `camera`, `microphone`, `geolocation`, `payment` globally.

CSP and HSTS land in TASK-055 (Phase 5). Don't loosen any of the above without a written reason.

## AI endpoint guard

`/api/extract-transaction` requires an authenticated user. The auth gate exists specifically to prevent unauthenticated traffic from burning Anthropic budget. Don't remove this gate.

Limits in place:
- 5 MB max upload.
- JPG / PNG / WebP / GIF only.
- Free tier quota tracked in `user_preferences.ai_extraction_quota_used` (Phase 6 enforcement).

## Anti-patterns

- **Don't import `@/lib/supabase/admin` in any file under `src/components/` or any file with `'use client'`.** It will break at runtime.
- **Don't trust `NEXT_PUBLIC_*` values for security decisions.** They are public.
- **Don't bypass middleware** by, e.g., adding a route to the public list "just for testing." The auth gate is the only gate.
- **Don't disable RLS** as a debugging shortcut. Re-enable it before commit. Add a check in PR review for `disable row level security`.
- **Don't log request bodies, headers, or cookies.** They contain auth tokens and PII.
- **Don't add a new public path** without confirming the data exposure model.
