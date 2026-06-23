# Database Rules

Source of truth: `supabase/schema.sql`. Migrations append to it via files in `supabase/migrations/`.

## Migration workflow

1. **Create a migration file**: `supabase/migrations/YYYYMMDD_short_description.sql`. Match the existing date-prefix convention (e.g. `20260424_ai_summaries.sql`). Use `/migrate` slash command for the boilerplate.
2. **Test locally**: `supabase db reset` to wipe + replay all migrations against the local stack (OrbStack + Supabase CLI). Do not skip this step.
3. **Update `src/types/database.ts`** to reflect any new tables, columns, or enums. Keep the row interface 1:1 with SQL columns.
4. **Update `supabase/schema.sql`** so it stays a flat snapshot of the current schema (this is the doc, not the source of replays).
5. Commit the migration file, the schema snapshot, and the type update **together**.
6. On merge to `main`, CI applies the migration to prod via `supabase db push`. See `deployment.md`.

## RLS policy template

Every per-user table must have RLS enabled and a policy filtering by `auth.uid()`:

```sql
ALTER TABLE my_table ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can read own rows"
  ON my_table FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own rows"
  ON my_table FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own rows"
  ON my_table FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own rows"
  ON my_table FOR DELETE
  USING (auth.uid() = user_id);
```

Per-user tables today: `investment_records`, `cash_transactions`, `user_preferences`, `ai_summaries` (read-only for users; service-role inserts only).

Shared tables: `exchange_rates` (public read), `benchmark_history` (auth read). Writes via service role / Edge Functions only.

## Triggers we rely on

- `handle_new_user()` — auto-creates a `user_preferences` row on `auth.users` insert. If you add a column to `user_preferences` with no default, update this trigger.
- `update_updated_at_column()` — auto-bumps `updated_at` on UPDATE. Apply to every mutable user table.

## Naming

- Tables: snake_case, plural (`investment_records`, `cash_transactions`).
- Columns: snake_case (`user_id`, `transaction_date`).
- Primary key: `id uuid default gen_random_uuid()`.
- Foreign key to user: always `user_id uuid references auth.users(id) on delete cascade`.
- Timestamps: `created_at timestamptz default now()`, `updated_at timestamptz default now()`.

## Constraints

- Money columns: `numeric` (never `float`).
- Currency: `text check (currency in ('USD','IDR'))`.
- Asset type: `text check (asset_type in ('crypto','us_stock','idn_stock'))`.
- Indonesian stock tickers stored without `.JK` suffix; `.JK` is appended at Yahoo Finance call time.

## Anti-patterns

- **Never edit an applied migration file.** Once it's in `main`, write a new migration instead. The PreToolUse hook blocks edits to migration files older than 24h.
- **Never add a column without RLS check implications.** A new column on a per-user table is fine; a new table needs full RLS policies before merge.
- **Never use the admin client (service role) just to skip RLS.** If you need to bypass RLS, write the reason in the comment above the import.
- **Never run `supabase db push` against prod manually.** That's CI's job.
