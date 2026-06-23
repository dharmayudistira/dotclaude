# dotclaude

My personal Claude Code configuration — a two-layer setup that makes Claude a reliable engineering partner across all my projects, not just a code generator.

## How it works

```
dotclaude/
├── CLAUDE.md                        ← global rules (applies everywhere)
└── truequity/
    ├── CLAUDE.md                    ← project-level config
    └── .claude/
        ├── rules/                   ← per-domain rule files
        ├── agents/                  ← subagent definitions
        └── commands/                ← slash commands
```

### Layer 1: Global (`CLAUDE.md`)

Defines how Claude should think and communicate regardless of project — mindset, code principles, communication style, safety guardrails, commit format, and tool preferences. This applies to every session across every codebase.

### Layer 2: Per-project (e.g. `truequity/`)

Layers in project-specific context: architecture overview, routing conventions, data layer patterns, env vars, and links to domain rule files. Claude reads the relevant rule file before touching anything in that domain — no guessing, no context drift.

## Truequity config

[Truequity](https://github.com/dharmayudistira/truequity) is a solo-built multi-currency wealth tracker for Indonesian retail investors (IDX stocks, US equities, crypto).

### Rule files (`.claude/rules/`)

| File | Covers |
|------|--------|
| `code-conventions.md` | File naming, imports, component structure, strict TS |
| `state-management.md` | TanStack Query patterns, hook quad pattern, context vs local state |
| `database.md` | Migration workflow, RLS policies, naming conventions |
| `error-handling.md` | Result<T,E> via neverthrow, boundary rules, anti-patterns |
| `ui-patterns.md` | shadcn/ui, Tailwind v4, forms with RHF + zod, Recharts |
| `security.md` | Auth gate, three Supabase clients, env var rules, AI endpoint guard |
| `deployment.md` | Two-env setup, CI/CD topology, migration deployment, rollback |

### Subagents (`.claude/agents/`)

| Agent | Role |
|-------|------|
| `feature-builder` | Full vertical slice from roadmap task: migration to types to hook to page |
| `reviewer` | Independent diff review against the rules. Read-only, used before merge |
| `db-architect` | SQL, migrations, RLS, indexes specialist |
| `infra-ops` | CI/CD, GitHub Actions, Edge Functions, Vercel config |

### Slash commands (`.claude/commands/`)

| Command | Does |
|---------|------|
| `/new-feature <task-id>` | Pull roadmap task, branch, scaffold via feature-builder, run gate |
| `/migrate <name>` | Create timestamped migration file with standard template |
| `/types` | Regenerate `database.ts` from local schema |
| `/review [base-branch]` | Run lint + typecheck, invoke reviewer subagent |
| `/check` | Fast local gate: lint + typecheck + build |
| `/deploy` | Preflight checks before merging to main |

## Philosophy

The goal is not to make Claude do more — it is to make Claude predictable. A well-structured config means I can hand off a full feature and trust the output meets the same bar as a senior engineer review, without having to re-explain the architecture every session.

## Author

[Dharma Yudistira](https://dharma-yudistira.com) — Fullstack and Flutter Engineer based in Sidoarjo, Indonesia.
