# Code Conventions

## File & directory naming

- Components: `kebab-case.tsx` (e.g. `dashboard-tour.tsx`, `tutorial-prompt-modal.tsx`).
- Hooks: `use-kebab-case.ts` in `src/hooks/`.
- Routes: Next App Router rules — `page.tsx`, `layout.tsx`, `route.ts`. Folder = URL segment.
- Server-only utilities: under `src/lib/`. Subfolders by domain (e.g. `src/lib/supabase/`).
- Pure types & DB row shapes: `src/types/`.
- Contexts: `src/contexts/<name>-context.tsx`.
- Test files (when added): co-located `*.test.ts(x)` next to source.

## Imports

Path alias `@/*` → `./src/*`. Always use `@/` for cross-folder imports. Never use deep relatives (`../../../`).

Import order:
1. React / Next.
2. Third-party packages.
3. `@/types/*`.
4. `@/lib/*`.
5. `@/hooks/*`.
6. `@/components/*` (UI then feature).
7. Relative imports.
8. CSS / asset imports last.

## Components

- Default to **server components**. Add `'use client'` only when you need state, effects, browser APIs, or event handlers.
- One component per file unless the helper is private and < 30 lines.
- Props as a named `interface ComponentNameProps`. No `React.FC`.
- Children prop typed as `React.ReactNode`.
- Co-locate small subcomponents inside the same file; promote to a sibling file once they are reused or exceed ~80 lines.

## Hooks

- All TanStack Query hooks live in `src/hooks/use-<entity>.ts` and follow the existing pattern (`use-investments.ts` is the canonical example).
- Export a `useXxx()` reader and `useCreateXxx() / useUpdateXxx() / useDeleteXxx()` mutators per entity.
- Query keys: `['<entity>', ...filters]`. Invalidate by `['<entity>']` on mutation.
- See `state-management.md` for full TanStack Query patterns.

## Types

- **Strict TypeScript everywhere.** No `any`. Use `unknown` + narrowing instead.
- Domain row types live in `src/types/database.ts` and mirror the SQL schema 1:1.
- Derive insert/update shapes from row types via `Omit<Row, 'id' | 'created_at' | 'updated_at'>` rather than hand-writing.
- All zod schemas for forms / API bodies live next to the consuming file or in `src/lib/schemas/`.

## Functions

- Prefer pure functions in `src/lib/`. Side effects belong in hooks, route handlers, or server actions.
- Functions that can fail return `Result<T, E>` (neverthrow). See `error-handling.md`.
- Export named functions; default exports only for Next route files (`page`, `layout`, `route`).

## Formatting & lint

- ESLint config: `eslint-config-next` (core-web-vitals + typescript). Don't add Prettier — eslint formatting rules win.
- `npm run lint` must pass before commit (enforced by pre-commit hook).
- `npx tsc --noEmit` must pass before merge (enforced by CI).

## What NOT to do

- Don't disable `eslint` or `tsc` rules to "make it work." Fix the underlying type or pattern.
- Don't write defensive `try/catch` around code that can't throw. Trust the type system.
- Don't add comments that explain WHAT — naming should do that. Reserve comments for non-obvious WHY.
- Don't introduce a new helper, abstraction, or wrapper unless the duplication appears 3+ times.
- Don't mix server and client code in one file. The `'use client'` boundary is meaningful.
