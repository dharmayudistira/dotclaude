# CLAUDE.md

Guidance for Claude Code working in this repository. Keep this file under ~300 lines. Detailed conventions live in `[.claude/rules/](.claude/rules/)` — link, don't duplicate.

## Mindset

- **Partner, not executor.** Discuss, challenge, suggest. Disagree openly when something is wrong. Correctness over agreement.
- **Solo dev, production bar.** This is a side-project shipped to real users (network beta first, then public). Treat every change like a senior engineer will review it before merge.
- **Read before write.** No edits without reading the surrounding code, the relevant rule file, and at least one canonical example.
- **No scope creep.** A bug fix doesn't refactor. A feature doesn't redesign. Three similar lines beats premature abstraction.
- **No defensive code.** Don't validate what can't fail, don't catch what won't throw, don't comment what naming already says.
- **Stop and confirm** before destructive ops, large refactors, or anything irreversible. Hooks block the worst of these automatically — see below.

## Commands

```bash
npm run dev            # Next dev server (http://localhost:3000)
npm run build          # Next build (uses --webpack flag, NOT turbopack)
npm run start          # Production server
npm run lint           # ESLint (eslint-config-next, core-web-vitals + typescript)
npm run typecheck      # tsc --noEmit
npm run check          # lint + typecheck + build (local pre-merge gate)
```

Local Supabase stack:

```bash
supabase start         # Boot local Postgres + Studio (OrbStack)
supabase db reset      # Wipe + replay all migrations against local
supabase status        # Show local stack URLs + keys
```

## Required env (`.env.local`)

`NEXT_PUBLIC_SUPABASE_URL`, `NEXT_PUBLIC_SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `ANTHROPIC_API_KEY`.

Optional (only when an Edge Function or scheduled task gates against it): `EDGE_FUNCTION_SECRET`.

`NEXT_PUBLIC_*` ships to the browser — treat as public. Everything else is server-only. See `[.claude/rules/security.md](.claude/rules/security.md)`.

## Architecture (condensed)

Next.js 16 App Router + React 19 + Supabase. Strict TS. Path alias `@/*` → `./src/*`. Dark theme hardcoded on `<html className="dark">`.

### Routing

- `src/app/(protected)/` — auth-required route group. Layout wraps with `CurrencyContext` and renders `TopNav`. The onboarding subroute opts out of `TopNav`.
- `src/app/auth/` — login, signup, callback, reset-password (public).
- `src/app/api/` — route handlers: `extract-transaction`, `prices`, `historical`, `search`, `exchange-rate`, `delete-account`.
- Public paths: `/`, `/privacy`, `/terms`, `/auth/*`.

### Auth gate

`src/lib/supabase/proxy.ts` `updateSession()` is the source of truth (Next 16 renamed `middleware.ts` to `proxy.ts`; the runtime proxy lives at `src/proxy.ts`):

- Unauth + non-public → `/auth/login`
- Auth + on `/auth/*` → `/dashboard`
- Auth + `user_preferences.onboarding_completed_at IS NULL` → `/onboarding`

The `(protected)` layout's `isOnboarding` branch must agree. Touch both together. The proxy must always carry refreshed Supabase cookies onto redirect responses; bare `NextResponse.redirect(url)` drops them and causes session loss. See `[.claude/rules/security.md](.claude/rules/security.md)`.

### Three Supabase clients (do not mix)


| Client  | File                    | Use in                              | Bypasses RLS |
| ------- | ----------------------- | ----------------------------------- | ------------ |
| Browser | `@/lib/supabase/client` | Client components, hooks            | No           |
| Server  | `@/lib/supabase/server` | RSC, route handlers, server actions | No           |
| Admin   | `@/lib/supabase/admin`  | Server-only, bypass-RLS writes      | **Yes**      |


Admin client throws if imported in a browser bundle. Use only when there's no other way (`exchange_rates` seeding, `ai_summaries` insert, e2e cleanup) and comment the reason.

### Data layer

Client-side reads use TanStack Query (`staleTime: 60s`, `refetchOnWindowFocus: false`, configured in `src/components/providers.tsx`). Per-domain hooks in `src/hooks/use-<entity>.ts` follow a `useEntities() / useCreateEntity() / useUpdateEntity() / useDeleteEntity()` quad pattern. `use-investments.ts` is the canonical example. Match exactly when adding new entities. See `[.claude/rules/state-management.md](.claude/rules/state-management.md)`.

### Database

Schema in `supabase/schema.sql`. Migrations in `supabase/migrations/` named `YYYYMMDD_<description>.sql`.

- Per-user tables (RLS by `auth.uid() = user_id`): `investment_records`, `cash_transactions`, `user_preferences`, `ai_summaries` (read-only for users).
- Shared: `exchange_rates` (public read), `benchmark_history` (auth read). Writes via service role / Edge Functions.
- `handle_new_user()` trigger auto-creates `user_preferences` on `auth.users` insert.
- `update_updated_at_column()` trigger on every mutable user table.

Asset types: `crypto | us_stock | idn_stock`. IDX tickers stored without `.JK`; suffix appended at Yahoo Finance call. See `[.claude/rules/database.md](.claude/rules/database.md)`.

### Multi-currency

Transactions store original currency (`USD` or `IDR`). Display currency lives in `user_preferences.display_currency`, mirrored into `CurrencyContext`. USD/IDR rate cached in `exchange_rates`; `FALLBACK_USDIDR_RATE` in `@/lib/constants` is the last-resort fallback. `/api/exchange-rate` reads + seeds via `supabaseAdmin`.

### External pricing

- Crypto: CoinGecko (`/simple/price`, `/coins/{id}/market_chart`, `/search`). Tickers stored as CoinGecko coin IDs (`bitcoin`).
- Stocks: `yahoo-finance2` via `@/lib/yahoo-finance`. IDX gets `.JK` at call time.
- Pre-cached benchmark series for `bitcoin`, `^GSPC`, `^JKSE` in `benchmark_history` (synced by `sync-benchmarks` Edge Function). `/api/historical` reads DB; falls back to live fetch only if empty.

### Edge Functions (Deno)

`supabase/functions/sync-benchmarks` and `update-exchange-rate`. Imports use `jsr:` / `https://esm.sh/`, not the `@/*` alias. Excluded from the TS project (`tsconfig.json`). See `[.claude/rules/deployment.md](.claude/rules/deployment.md)`.

### AI integration

`/api/extract-transaction` — broker/exchange screenshot → JSON transaction via Anthropic SDK (`claude-haiku-4-5-20251001`). Auth-required (don't remove this gate — it prevents budget burn). 5 MB max, JPG/PNG/WebP/GIF only. The extraction prompt encodes Indonesian-broker quirks (Lot→shares ×100, "Beli"/"Jual"), partial fills, and `unsupported_asset` / `no_transaction` error envelopes.

### UI

shadcn/ui (style `base-nova`, neutral). Tailwind v4 (theme tokens in `src/app/globals.css`). Lucide icons. Recharts. Sonner toasts. Framer Motion for layout transitions.

Coachmark / in-app tour: **driver.js 1.4.0 (pinned)**. See `dashboard-tour.tsx`. Do not switch this to Base UI Popover. See `[.claude/rules/ui-patterns.md](.claude/rules/ui-patterns.md)`.

### Security headers

`next.config.ts` sets `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`, `Referrer-Policy: strict-origin-when-cross-origin`, `Permissions-Policy` blocking camera/mic/geolocation/payment globally. CSP + HSTS land in TASK-055.

## Conventions (link map)

Each link below points to the full rule. CLAUDE.md only carries the headline.

- **Code conventions** — kebab-case files, `use-<entity>.ts` hooks, named-export functions, no `any`. Path alias `@/*`. Strict TS, no Prettier. → `[.claude/rules/code-conventions.md](.claude/rules/code-conventions.md)`
- **State management** — TanStack Query for server state, URL state for shareables, Context for cross-component UI flags, `useState` for local. Hook quad pattern is mandatory. → `[.claude/rules/state-management.md](.claude/rules/state-management.md)`
- **Database** — migration template, RLS for every per-user table (4 policies), update `database.ts` + `schema.sql` alongside the migration. Never edit applied migrations. → `[.claude/rules/database.md](.claude/rules/database.md)`
- **Error handling** — `Result<T, E>` (neverthrow) in `src/lib/`. Throw at framework boundaries (route handlers, server actions, `mutationFn`). Discriminated-union error types keyed on `kind`. → `[.claude/rules/error-handling.md](.claude/rules/error-handling.md)`
- **UI patterns** — shadcn first, RHF + zod for every form, Tailwind utility-first, design tokens not hex. No new UI libs. → `[.claude/rules/ui-patterns.md](.claude/rules/ui-patterns.md)`
- **Security** — auth gate is single source of truth. Three Supabase clients, strict separation. RLS non-negotiable. Never log secrets/PII. → `[.claude/rules/security.md](.claude/rules/security.md)`
- **Deployment** — two envs (local + prod). CI on PR (lint/typecheck/build) + on main (migrations + edge functions). Vercel deploys app via its own integration. Never `supabase db push` against prod manually. → `[.claude/rules/deployment.md](.claude/rules/deployment.md)`

## Subagents

Located in `[.claude/agents/](.claude/agents/)`. Invoke via the Agent tool with `subagent_type`.

- `**feature-builder`** — full vertical slice from a roadmap task: migration → types → hook → form → page. Use for PRD tasks, not bug fixes.
- `**reviewer**` — independent diff review against the rules. Read-only. Use before merge or after a feature-builder pass.
- `**db-architect**` — SQL/migrations/RLS specialist. Use for schema design, performance, indexes.
- `**infra-ops**` — CI/CD, GitHub Actions, Edge Functions, Vercel config, env wiring.

Skip subagents for simple edits or tasks under ~3 tool calls. Use them when you want a fresh perspective, narrow domain focus, or to keep the main context clean.

## Slash commands

Located in `[.claude/commands/](.claude/commands/)`. Invoke as `/command [args]`.

- `/new-feature <task-id>` — pull a roadmap task, branch, scaffold via feature-builder, run gate.
- `/migrate <name>` — create a timestamped migration file with the standard template.
- `/types` — regenerate `src/types/database.ts` from local schema.
- `/review [base-branch]` — run lint + typecheck, invoke reviewer subagent.
- `/check` — fast local gate (lint + typecheck + build). No remote calls.
- `/deploy` — preflight checks before merging to main. Read-only; does not deploy.

## Hooks (what they block)

Defined in `[.claude/settings.json](.claude/settings.json)` with scripts in `[.claude/hooks/](.claude/hooks/)`.

- **PreToolUse Bash** — blocks `rm -rf` with broad targets, `git push --force / -f`, `git reset --hard`, `git clean -fd`, `git branch -D`, `supabase db push`, raw `DROP TABLE / TRUNCATE`, writes to `.env`*.
- **PreToolUse Edit/Write** — blocks edits to migration files already in `main`. Write a corrective migration on top instead.
- **SessionStart** — prints current branch, active phase, next 3 unstarted roadmap tasks.

If a hook blocks something you genuinely need, ask the user to run it themselves with the `!` prefix in the prompt.

## Top anti-patterns (the ones that bite)

1. Importing `@/lib/supabase/admin` in a `'use client'` file or under `src/components/`. Runtime crash.
2. Adding a new per-user table without 4 RLS policies in the same migration. Data leak.
3. Editing an applied migration. Schema drift between envs.
4. Storing server data in `useState` instead of TanStack Query. Stale UI on refetch.
5. Throwing inside a function that returns `Result<T, E>`. Defeats the type.
6. `try/catch` swallowing errors silently in lib code. Bug becomes invisible.
7. Hardcoded hex colors in components. Breaks design tokens.
8. Comments that explain WHAT (rename instead of comment). Rot magnet.
9. Disabling lint or `tsc` rules to make a build pass. Fix the underlying issue.
10. Bypassing middleware by adding a "temporary" public path. The auth gate is the only gate.

## Product context

Truequity is a multi-currency wealth tracker for Indonesian retail investors covering IDX stocks, US stocks, and crypto across local/global brokers. Long-form docs in `docs/`:

- `docs/product-vision.md` — vision, personas, principles, brand strategy.
- `docs/prd.md` — product requirements.
- `docs/product-roadmap.md` — phased roadmap. **Source of truth for what's shipped vs. planned.** Treat every TASK-XXX reference in a PR as a pointer here.

