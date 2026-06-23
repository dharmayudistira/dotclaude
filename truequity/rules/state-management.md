# State Management Rules

## Layers

1. **Server state** (anything that lives in Supabase): TanStack Query. Configured in `src/components/providers.tsx` with `staleTime: 60s`, `refetchOnWindowFocus: false`.
2. **URL state**: Next router (`useSearchParams`, `useRouter`). Use for filters, modal open state when shareable, current tab.
3. **Cross-component UI state** (display currency, privacy mode): React Context. See `src/contexts/`.
4. **Component-local state**: `useState`, `useReducer`. Default choice when no other layer fits.

Pick the highest level that fits the data. Don't lift state into context just to share it once.

## TanStack Query hook pattern

Canonical example: `src/hooks/use-investments.ts`. Replicate this shape for every new entity.

```ts
'use client';

import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { createClient } from '@/lib/supabase/client';
import type { Entity } from '@/types/database';

export function useEntities(filter?: Filter) {
  const supabase = createClient();
  return useQuery({
    queryKey: ['entities', filter],
    queryFn: async () => {
      const { data, error } = await supabase.from('entities').select('*');
      if (error) throw error;
      return data as Entity[];
    },
    staleTime: 30 * 1000,
    gcTime: 10 * 60 * 1000,
  });
}

export function useCreateEntity() {
  const supabase = createClient();
  const qc = useQueryClient();
  return useMutation({
    mutationFn: async (input: Omit<Entity, 'id' | 'user_id' | 'created_at' | 'updated_at'>) => {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Not authenticated');
      const { data, error } = await supabase.from('entities').insert({ ...input, user_id: user.id }).select().single();
      if (error) throw error;
      return data;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['entities'] }),
  });
}
```

## Query keys

- Format: `['<entity>', ...filters]`. First element is the invalidation root.
- Always invalidate by the root key on mutation success: `qc.invalidateQueries({ queryKey: ['entities'] })`.
- Do not use exact key matching for invalidation; we want all filtered variants to refetch.

## Mutation rules

- Always `select().single()` after insert/update so the hook returns the canonical row (Supabase computes server-side defaults).
- `onSuccess` invalidates. Do not optimistically update unless the latency is user-visible (we don't have that case yet).
- All mutations throw on error. The boundary at the React Query layer turns the throw into `mutation.error` for the UI to render.
- See `error-handling.md` for how `Result<T, E>` from lib code translates at this boundary.

## When NOT to use TanStack Query

- Static data baked into the bundle (use module-level constants).
- One-off RSC fetches that don't need cache invalidation (just `await` in the server component).
- Form state (use react-hook-form). The mutation is the only Query touchpoint there.

## Anti-patterns

- Don't call `useQuery` inside a loop or condition.
- Don't store server data in `useState` — that's what TanStack is for.
- Don't put display state (currency selector, privacy toggle) in TanStack. Use context.
- Don't refetch manually with `fetch()` inside a `useEffect`.
