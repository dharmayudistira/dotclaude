---
description: Review the current branch's diff against project rules
argument-hint: [base-branch]
---

Review the current branch's diff against project rules. Default base is `main`. If `$ARGUMENTS` is provided, use that as the base branch.

Steps:

1. Run `git status` and `git diff <base>...HEAD --stat` to confirm scope.

2. Run `npm run lint` and `npx tsc --noEmit`. Capture any failures.

3. Invoke the `reviewer` subagent with:
   - The diff scope (`<base>...HEAD`).
   - The lint and typecheck results.
   - Instructions to read all `.claude/rules/*.md` before reviewing.

4. Print the reviewer's report verbatim, then add a one-paragraph summary at the top:
   - Verdict: `READY` / `NEEDS WORK` / `BLOCKED`
   - Top must-fix item if any
   - Recommended next action

Do not modify any files. This command is read-only.
