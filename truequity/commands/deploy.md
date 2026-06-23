---
description: Guarded prod deploy preflight (does NOT push to prod)
---

Run preflight checks before merging to `main`. This command **does not deploy** — Vercel + GitHub Actions handle deploy automatically when `main` advances. Its job is to ensure that when `main` does advance, the deploy will succeed.

Steps:

1. **Branch sanity**:
   - Current branch is not `main`. If it is, stop and ask.
   - Working tree clean. If dirty, stop and ask.
   - Branch is up-to-date with origin.

2. **Local gate** (same as `/check`):
   - `npm run lint`
   - `npx tsc --noEmit`
   - `npm run build`

3. **Migration sanity**:
   - List new SQL files in `supabase/migrations/` since branch base.
   - For each, verify it's syntactically parseable: `supabase db reset --local` if local stack is running, otherwise instruct the user to run it.
   - Confirm `supabase/schema.sql` and `src/types/database.ts` were updated alongside.

4. **Edge function sanity**:
   - List changed files under `supabase/functions/`.
   - Confirm each function still imports correctly (Deno-style imports, no `@/*` alias).

5. **Env var diff**:
   - Read `.env.local` keys (not values) and compare against the required list in `.claude/rules/security.md`.
   - Flag any new key the user must add to Vercel + GitHub Actions secrets.

6. **Reviewer pass**:
   - Invoke the `reviewer` subagent on `main...HEAD`.

7. **Report**:
   ```
   ## Preflight summary
   Verdict: READY / BLOCKED
   
   ## Local gate
   - Lint: ...
   - Typecheck: ...
   - Build: ...
   
   ## DB
   - New migrations: <list or "none">
   - schema.sql + types updated: yes/no
   
   ## Edge functions
   - Changed: <list or "none">
   
   ## Env vars
   - New keys to set in Vercel + GH secrets: <list or "none">
   
   ## Reviewer findings
   - Must-fix: <count>
   - Nice-to-fix: <count>
   
   ## When you merge to main
   1. CI will run pr.yml → deploy.yml.
   2. deploy.yml will: lint, typecheck, build, supabase db push, supabase functions deploy.
   3. Vercel will deploy the app independently.
   ```

Never push, force-push, merge a PR, or run `supabase db push` from this command. Read-only and informational.
