---
description: Create a new SQL migration file with the standard template
argument-hint: <short_description>
---

Create a new migration file: `supabase/migrations/YYYYMMDD_$ARGUMENTS.sql` where `YYYYMMDD` is today's date.

The file must use the template from `.claude/rules/database.md`. If the task is creating a per-user table, include all four RLS policies, the `update_updated_at_column` trigger, and an index on `user_id`.

After writing the migration:

1. Update `supabase/schema.sql` so it reflects the new table/column.
2. Update `src/types/database.ts` to mirror the SQL exactly. Add `Row`, derive `Insert` / `Update` via `Omit`.
3. Print the next-step instructions:
   ```
   ## Next steps
   1. Run: supabase db reset
   2. Verify: supabase db diff (should be empty)
   3. Commit migration + schema.sql + types together
   ```

Do NOT run `supabase db push` against prod. That's CI's job.

If `$ARGUMENTS` is unclear or the migration intent is ambiguous, delegate to the `db-architect` subagent with the user's intent, and let it produce the migration.
