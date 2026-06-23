# Deployment

## Environments

We run **two**:

1. **Local dev** — Supabase CLI on OrbStack + `next dev`. Stack started via `supabase start`. Creds in `.env.local`.
2. **Production** — hosted Supabase project + Vercel prod. Single source of truth for "real."

No staging/preview Supabase project today. Vercel preview deployments hit prod Supabase **read-only-by-context** (the user has to sign in; you shouldn't run destructive ops from a preview branch — convention, not enforcement).

If we ever add staging, it lands as a third Supabase project + a `staging` branch in CI. Until then, every PR's preview points at prod data.

## Local setup

```bash
# Once
brew install supabase/tap/supabase
supabase login

# In repo
supabase start              # boots local Postgres + Studio in OrbStack
cp .env.local.example .env.local   # if not already populated
npm install
npm run dev
```

Local creds (anon, service role, URL) come from `supabase start` output. Paste them into `.env.local`.

## Pre-commit hook

Managed by [husky](https://typicode.github.io/husky/) — `.husky/pre-commit` runs `npx lint-staged`, which runs `eslint --fix` on staged `*.{ts,tsx}` files. Husky is installed via the `prepare` script on `npm install`.

In an emdash worktree (`.git` is a pointer file, not a directory), husky still works correctly because it relies on `git config core.hooksPath .husky/_` rather than writing to `.git/hooks/` directly.

## CI/CD topology

GitHub Actions does the gating. Vercel handles app deploy via its own GitHub integration (no Vercel step in workflows).

- **`pr.yml`** — runs on every PR to `main`:
  - lint
  - typecheck (`tsc --noEmit`)
  - build (`next build`)
  - (later) migration SQL validate

- **`deploy.yml`** — runs on push to `main`:
  - lint, typecheck, build (gate)
  - `supabase db push` — applies any new migrations to prod
  - `supabase functions deploy <each>` — redeploys edge functions if changed

Vercel sees the merge to `main` independently and deploys the app.

## Required GitHub Actions secrets

- `SUPABASE_ACCESS_TOKEN` — personal access token (`supabase login --token`).
- `SUPABASE_DB_PASSWORD` — prod DB password (Supabase dashboard → Project Settings → Database).
- `SUPABASE_PROJECT_REF` — the unique project ID (the subdomain of your Supabase URL).

Optional (for edge function deploys with secrets):
- `SUPABASE_FUNCTION_<NAME>_SECRET` — per-function env vars, set via `supabase secrets set` in the workflow.

## Migration deployment

Migrations run **only via CI**. Never `supabase db push` against prod from your laptop.

The deploy workflow runs:

```bash
supabase link --project-ref "$SUPABASE_PROJECT_REF"
supabase db push
```

If a migration fails: deploy halts, prod is unchanged, you fix on a new branch + PR. Never edit the failing migration in place — write a corrective migration on top.

## Edge function deploy

```bash
supabase functions deploy sync-benchmarks --project-ref "$SUPABASE_PROJECT_REF"
supabase functions deploy update-exchange-rate --project-ref "$SUPABASE_PROJECT_REF"
```

Cron schedules and function secrets are configured in Supabase dashboard, not in code. Document changes in `supabase/functions/<name>/README.md` if non-obvious.

## One-time setup steps

The first prod deploy needs a baseline-migration reconciliation. Existing prod schema was applied via SQL Editor before migrations existed, so the baseline migration (`20260101000000_initial_schema.sql`) must be marked already-applied before CI's `supabase db push` runs against prod.

See `docs/deploy-runbook.md` § "First-time prod deploy" for the exact `supabase migration repair` commands.

## Rollback

App: Vercel "Promote previous deployment" button.
Migrations: write a forward migration that reverses the bad one. Don't try to delete the migration row in `supabase_migrations.schema_migrations` — it leaves the schema in a half-state.

## Anti-patterns

- Don't push to `main` unless CI is green.
- Don't bypass CI by running `supabase db push` locally with prod creds. There's no audit trail and no rollback.
- Don't store prod secrets in `.env.local` "just to test something against prod." Use a separate `.env.production.local` scoped to one shell session, then delete it.
- Don't delete migration files. Once committed, they're history. Write corrective migrations.
- Don't merge a PR with failing migration validation, even if "the SQL looks fine."
