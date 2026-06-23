---
description: Fast lint + typecheck + build verification on current state
---

Run the local pre-merge gate. Fast feedback, no external calls.

Steps (in this order; stop at first failure):

1. `npm run lint`
2. `npx tsc --noEmit`
3. `npm run build`

Report at the end:
```
## Check results
- Lint: PASS / FAIL (<N issues>)
- Typecheck: PASS / FAIL (<N errors>)
- Build: PASS / FAIL

## Next action
<concrete next step if any failed; otherwise: "Ready to commit / push.">
```

If a step fails, do not auto-fix. Print the first 30 lines of the failure and stop. The user decides whether to delegate the fix.
