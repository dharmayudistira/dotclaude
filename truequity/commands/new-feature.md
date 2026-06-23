---
description: Start a new feature from a roadmap task ID
argument-hint: <task-id>
---

Implement task `$ARGUMENTS` from `docs/product-roadmap.md` end-to-end.

Steps you must follow in order:

1. **Locate the task**: open `docs/product-roadmap.md` and find the task whose ID matches `$ARGUMENTS` (e.g. `TASK-061`). Read its description, file list, and notes. If you can't find it, stop and ask.

2. **Check git state**: confirm a clean working tree on `main` (or a permitted starting branch). If dirty, stop and ask whether to stash, commit, or abort.

3. **Create a branch**: `git checkout -b <phase-slug>/<task-id>-<short-slug>`. Phase slug comes from the section header (e.g. `phase-2/task-024-onboarding-read-summary`).

4. **Read context**:
   - The Phase header's "Reference sections" — read those subsections of `docs/prd.md` and `docs/product-vision.md`.
   - All `.claude/rules/*.md` files relevant to the task surface.
   - The canonical existing example for the slice you're building.

5. **Delegate to `feature-builder`**: invoke the `feature-builder` subagent with the full task description, the Reference sections you read, and the rules files. Let it scaffold the slice.

6. **Self-review**: run `npm run lint && npx tsc --noEmit`. Fix anything that fails.

7. **Verify locally**: start `npm run dev` and exercise the feature in the browser per the task's "Verify" notes. If you can't (e.g. you're in a non-interactive context), say so explicitly.

8. **Update the roadmap**: flip the task's `[ ]` to `[x]` in `docs/product-roadmap.md`.

9. **Commit**: `prefix(scope): concise message` per the global commit rules. Use a HEREDOC. No AI attribution.

10. **Report**: branch name, files changed, what was verified, what was not, open follow-ups. Stop. Do not push or open a PR unless the user asks.

If the task is ambiguous or contradicts an existing rule, stop at step 4 and ask one focused question.
