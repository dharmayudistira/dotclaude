#!/usr/bin/env bash
# PreToolUse hook for Edit/Write. Blocks edits to migration files already merged into main.

set -euo pipefail

input=$(cat)
file=$(printf '%s' "$input" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('tool_input',{}).get('file_path',''))" 2>/dev/null || true)

[ -z "$file" ] && exit 0

case "$file" in
  *"/supabase/migrations/"*.sql) ;;
  *) exit 0 ;;
esac

# If the file exists in main, block. Write a new migration instead.
basename_file=$(basename "$file")
if git ls-tree -r main --name-only 2>/dev/null | grep -qE "supabase/migrations/${basename_file}$"; then
  echo "BLOCKED by hook: $basename_file is already in main." >&2
  echo "Don't edit applied migrations. Write a corrective migration on top." >&2
  echo "See .claude/rules/database.md." >&2
  exit 2
fi

exit 0
