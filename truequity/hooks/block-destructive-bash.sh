#!/usr/bin/env bash
# PreToolUse hook for Bash. Blocks high-risk commands so Claude has to ask.
# Exit 2 = block with stderr shown to Claude.

set -euo pipefail

input=$(cat)
cmd=$(printf '%s' "$input" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('command',''))" 2>/dev/null || true)

[ -z "$cmd" ] && exit 0

block() {
  echo "BLOCKED by hook: $1" >&2
  echo "Reason: $2" >&2
  echo "If you really mean it, ask the user to run it themselves with the '!' prefix." >&2
  exit 2
}

# rm -rf with catastrophic targets only (allows rm -rf node_modules, .next, /tmp/foo, dist, ~/cache).
# The dangerous targets must end the command (end-of-line) — anything after them means a more specific path.
echo "$cmd" | grep -qE '(^|[^a-zA-Z_/])rm[[:space:]]+(-[rRf]+[[:space:]]+)?(/[[:space:]]*$|/\*[[:space:]]*$|~[[:space:]]*$|~/[[:space:]]*$|\$HOME[[:space:]]*$|\$\{HOME\}[[:space:]]*$|\*[[:space:]]*$|\.[[:space:]]*$|\.\.[[:space:]]*$)' && \
  block "rm with catastrophic target" "Targets root, home, current dir, parent dir, or shell glob."

# Git destructors
echo "$cmd" | grep -qE 'git[[:space:]]+push[[:space:]].*--force([[:space:]]|$)' && \
  block "git push --force" "Overwrites remote history. Use --force-with-lease if truly needed, after user confirm."

echo "$cmd" | grep -qE 'git[[:space:]]+push[[:space:]].*[[:space:]]-f([[:space:]]|$)' && \
  block "git push -f" "Overwrites remote history."

echo "$cmd" | grep -qE 'git[[:space:]]+reset[[:space:]]+--hard' && \
  block "git reset --hard" "Discards uncommitted work."

echo "$cmd" | grep -qE 'git[[:space:]]+branch[[:space:]]+-D[[:space:]]' && \
  block "git branch -D" "Force-deletes a branch even if unmerged."

echo "$cmd" | grep -qE 'git[[:space:]]+clean[[:space:]]+-[a-z]*f[a-z]*d' && \
  block "git clean -fd" "Removes untracked files. Could destroy in-progress work."

echo "$cmd" | grep -qE 'git[[:space:]]+(checkout|restore)[[:space:]]+(\.[[:space:]]*$|--[[:space:]]*\.[[:space:]]*$)' && \
  block "git checkout/restore ." "Discards all local changes."

# Supabase prod ops
echo "$cmd" | grep -qE 'supabase[[:space:]]+db[[:space:]]+push' && \
  block "supabase db push" "Migration deployments must run via CI on main, not manually."

echo "$cmd" | grep -qE 'supabase[[:space:]]+db[[:space:]]+reset[[:space:]]+--linked' && \
  block "supabase db reset --linked" "Wipes the prod database. Never."

# Postgres destructors (raw)
echo "$cmd" | grep -qiE '(drop[[:space:]]+(table|database|schema)|truncate[[:space:]]+table)' && \
  block "raw DROP/TRUNCATE in shell" "Write a migration instead and let CI apply it."

# Env files
echo "$cmd" | grep -qE '(>|>>)[[:space:]]*\.env(\.|$|[[:space:]])' && \
  block "writing to .env*" "Don't pipe into .env files; ask the user to set vars manually."

exit 0
