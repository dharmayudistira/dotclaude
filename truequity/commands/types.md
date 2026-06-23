---
description: Regenerate Supabase TypeScript types from the local schema
---

Regenerate `src/types/database.ts` from the current local Supabase schema.

Steps:

1. Confirm local Supabase is running: `supabase status`. If not, instruct the user to run `supabase start` and stop.

2. Generate the typed schema from local:
   ```bash
   supabase gen types typescript --local > src/types/database.generated.ts
   ```

3. **Read both files**: `src/types/database.ts` (hand-curated) and the generated one. The generated one is verbose Postgres-rooted output; we keep our hand-curated `database.ts` as the source consumed by app code.

4. **Diff manually**: identify any drift between the two:
   - New tables in generated but missing in `database.ts` → add them.
   - Column type mismatches → update `database.ts`.
   - Removed tables / columns → remove from `database.ts`.

5. **Update `database.ts`** to reflect the schema. Keep the file's existing shape: named interfaces with `Row | Insert | Update` derived via `Omit`. Do not just dump the generated file in.

6. **Delete the generated file**: `rm src/types/database.generated.ts`. We don't commit it.

7. Run `npx tsc --noEmit` to confirm no type drift in consumers.

If `supabase` CLI is not installed, stop and ask the user to install it (`brew install supabase/tap/supabase`).
