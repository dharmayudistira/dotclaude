# UI Patterns

## Stack

- shadcn/ui (style `base-nova`, neutral base color). Components in `src/components/ui/`.
- Tailwind v4 (PostCSS plugin in `postcss.config.mjs`, theme tokens in `src/app/globals.css`).
- Lucide icons. Recharts for charts. Sonner for toasts.
- Dark theme is hardcoded on `<html className="dark">`. Don't introduce a light-theme branch unless the product asks for it.
- Animations: Framer Motion for layout/page transitions; Tailwind transitions for hover/focus.
- Coachmark / in-app tour: **driver.js 1.4.0 (pinned)**. See `dashboard-tour.tsx`. Do not switch this to Base UI Popover or any other lib.

## Component composition

- Reach for shadcn primitives first (`Button`, `Input`, `Dialog`, `Sheet`, `DropdownMenu`, etc.). Don't rebuild these.
- Compose, don't copy. New feature components belong in `src/components/<feature>/`.
- One feature folder per top-level route or product surface (`dashboard/`, `onboarding/`, `landing/`, `records/`, `charts/`, `layout/`).

## Styling

- Tailwind utility-first. No CSS modules, no styled-components.
- `cn()` from `@/lib/utils` to merge class names with conditional bits. Don't string-concat.
- Use design tokens from `globals.css` (`bg-background`, `text-muted-foreground`, etc.). Don't hardcode hex colors in components.
- Spacing/sizing scale follows Tailwind defaults — stick to it.

## Forms

**Standard stack**: react-hook-form + zod resolver. No exceptions for new forms.

```ts
'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';

const FormSchema = z.object({
  ticker: z.string().min(1).max(10).toUpperCase(),
  quantity: z.coerce.number().positive(),
  currency: z.enum(['USD', 'IDR']),
});

type FormValues = z.infer<typeof FormSchema>;

export function MyForm() {
  const form = useForm<FormValues>({
    resolver: zodResolver(FormSchema),
    defaultValues: { currency: 'USD' },
  });

  const onSubmit = form.handleSubmit(async (values) => {
    // values is fully typed via z.infer
    await mutation.mutateAsync(values);
  });

  return <form onSubmit={onSubmit}>...</form>;
}
```

- Schemas live next to the form file or in `src/lib/schemas/<entity>.ts` if shared with a route handler.
- Error display: shadcn's `<Form>`, `<FormField>`, `<FormMessage>` components.
- Submit handler is `async`. Disable submit button on `isSubmitting`. Toast success / error.

## Server actions vs route handlers

- **Server actions** for form mutations from app pages. Use when the only consumer is the form itself.
- **Route handlers** for: external integrations (`/api/extract-transaction`), webhooks (Stripe), cron, public APIs.
- Both validate input with the same zod schema. Boundary returns `Response.json` for handlers, throws/returns for server actions.

## Loading & empty states

- Every list/dashboard component has a skeleton state (`<XxxSkeleton />`) with the same shape. Match dimensions to avoid layout jitter.
- Empty states are first-class: explain what the user should do next, not "no data found."
- Errors at the component level: render an inline retry, don't blow up the page.

## Toasts (Sonner)

- Success toasts: short, past-tense ("Transaction added").
- Error toasts: actionable if possible ("Couldn't save — try again").
- Info: only for non-blocking async work the user kicked off (background imports, summary regeneration).
- Don't toast on initial load. Don't double-toast on retry.

## Charts (Recharts)

- All series use the design-token colors via Tailwind utility classes on the wrapping div, then read CSS vars in Recharts config.
- Lazy-import Recharts in dashboard components — it's heavy. See `next/dynamic`.

## Accessibility (baseline)

- Every icon-only button has an `aria-label`.
- Focus indicators must be visible on dark backgrounds (use `focus-visible:ring-2 focus-visible:ring-ring`).
- Color contrast: never rely on color alone for state. Pair color with icon or text.
- Lighthouse a11y target: ≥ 95 on dashboard and onboarding (see TASK-052).

## Anti-patterns

- Don't add a new UI lib. We have shadcn + driver.js. That's the budget.
- Don't reach into shadcn component internals to override styles — wrap and pass `className`.
- Don't write `useEffect` to sync form state. RHF handles that.
- Don't render server data in JSX without a loading state.
