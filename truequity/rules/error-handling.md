# Error Handling

We use `neverthrow`'s `Result<T, E>` for fallible operations in the lib/service layer. We **throw** at framework boundaries (route handlers, server actions, TanStack Query mutationFn) because Next and TanStack expect thrown errors.

## The boundary rule

Two zones, one explicit handoff:

| Zone | Convention | Why |
|------|------------|-----|
| `src/lib/**`, `src/lib/services/**`, pure helpers | Return `Result<T, E>` | Forces callers to handle failure paths. No hidden throws. |
| Route handlers, server actions, hooks `mutationFn`, edge functions | Throw `Error` | The framework's contract is throws → 500 / `mutation.error`. |

The boundary is **explicit**: at the boundary, `unwrapOr`, `match`, or `_unsafeUnwrap()` (with comment justifying it) translates Result into throw.

## Lib layer pattern

```ts
import { ok, err, Result } from 'neverthrow';

type ExtractError =
  | { kind: 'unsupported_asset' }
  | { kind: 'no_transaction' }
  | { kind: 'rate_limit' }
  | { kind: 'unknown'; cause: unknown };

export async function extractTransaction(
  image: Buffer,
): Promise<Result<Transaction, ExtractError>> {
  if (image.byteLength > MAX_BYTES) return err({ kind: 'unsupported_asset' });
  try {
    const t = await callAnthropic(image);
    return ok(t);
  } catch (cause) {
    return err({ kind: 'unknown', cause });
  }
}
```

Error types are **discriminated unions** keyed on `kind`. No string error codes. Add new variants over time; TS will fail every `match` site that didn't update.

## Boundary translation pattern

In route handlers:

```ts
export async function POST(req: Request) {
  const result = await extractTransaction(image);
  return result.match(
    (transaction) => Response.json({ ok: true, transaction }),
    (error) => {
      switch (error.kind) {
        case 'unsupported_asset': return Response.json({ ok: false, error: 'unsupported_asset' }, { status: 400 });
        case 'no_transaction':    return Response.json({ ok: false, error: 'no_transaction' }, { status: 400 });
        case 'rate_limit':        return Response.json({ ok: false, error: 'rate_limit' }, { status: 429 });
        case 'unknown':           return Response.json({ ok: false, error: 'internal' }, { status: 500 });
      }
    },
  );
}
```

In TanStack Query `mutationFn`:

```ts
mutationFn: async (input) => {
  const result = await doThing(input);
  if (result.isErr()) throw new ServiceError(result.error);
  return result.value;
}
```

## React UI

- `mutation.error` is the surfaced thrown error. Render via toast (Sonner) or inline form error.
- Never render raw `error.message` for unknown errors — show "Something went wrong" and log the cause.
- For form validation: use zod's resolver with react-hook-form. zod errors never reach this layer.

## Logging

- Lib functions don't `console.error`. They return `err(...)`. The boundary decides whether to log.
- Boundary handlers log unknown errors (`error.kind === 'unknown'`) with `console.error`, then return a generic response. Sentry will hook in here later (TASK-041).
- Never log secrets, raw request bodies, or PII.

## Anti-patterns

- **Don't `try/catch` everywhere.** The lib's job is to convert thrown deps into `Result`. Boundary code rarely catches — it `match`es the Result.
- **Don't return `null` to mean failure.** Return `err(...)`. `null` should mean "absent value," not "operation failed."
- **Don't `throw` from a function that returns `Result`.** That defeats the type. If the throw is from a third-party lib you're wrapping, catch it locally and convert.
- **Don't use `_unsafeUnwrap()` in production code.** Reserve for tests or one-shot scripts. If you need it, write a comment explaining why.
