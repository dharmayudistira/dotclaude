#!/usr/bin/env bash
# SessionStart hook. Prints branch, current phase, and next unstarted tasks.
# Output goes to Claude's context as a system message at session start.

set -euo pipefail

cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
roadmap="docs/product-roadmap.md"

# Find the latest "## Phase N" header that has any unchecked tasks below it.
current_phase=""
if [ -f "$roadmap" ]; then
  current_phase=$(awk '
    /^## Phase / { phase = $0 }
    /^- \[ \]/ { if (phase != "") { print phase; exit } }
  ' "$roadmap")
fi

# Next 3 unchecked tasks (any phase).
next_tasks=""
if [ -f "$roadmap" ]; then
  next_tasks=$(grep -E '^- \[ \] \*\*TASK-' "$roadmap" | head -3 | sed 's/^- \[ \] /  /')
fi

echo "## Truequity session context"
echo ""
echo "- Branch: $branch"
echo "- Active phase: ${current_phase:-(none / all complete)}"
echo "- Next tasks:"
if [ -n "$next_tasks" ]; then
  echo "$next_tasks"
else
  echo "  (none queued)"
fi
echo ""
echo "Rules: see CLAUDE.md and .claude/rules/. Subagents: feature-builder, reviewer, db-architect, infra-ops."
