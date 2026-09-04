# dotclaude

My personal Claude Code configuration. A two-layer setup that makes Claude a reliable engineering partner across all my projects, not just a code generator.

## How it works

Configuration is split by scope. Rules that hold everywhere live at the global layer. Rules that only make sense inside one codebase live with that codebase.

```
dotclaude/
└── CLAUDE.md        ← global rules (applies everywhere)

your-project/
├── AGENTS.md        ← project-level config (any agent)
├── CLAUDE.md        ← symlink to AGENTS.md
└── .claude/         ← per-project Claude setup
```

### Layer 1: Global (`CLAUDE.md`)

This repo. Defines how Claude should think and communicate regardless of project: mindset, code principles, communication style, safety guardrails, commit format, and tool preferences. It applies to every session across every codebase.

The four-point structure is adopted from Andrej Karpathy's CLAUDE.md, with my own conventions layered on top. The sections are deliberately ordered. Think before coding, then simplicity first, then surgical changes, then goal-driven execution. Each one constrains the next.

### Layer 2: Per-project (`AGENTS.md`)

Lives in the project repo, not here. It layers in what the global rules cannot know: architecture overview, conventions, data layer patterns, env vars, and anything else specific to that codebase. `AGENTS.md` is the tool-agnostic format, so the same file works for Claude Code, Codex, Cursor, and other agents instead of locking project context to one vendor. Whatever Claude-only setup a project needs still goes in its `.claude/` directory, scoped to that project alone.

Claude Code does not read `AGENTS.md` on its own, so the project keeps a `CLAUDE.md` symlink pointing at it: `ln -s AGENTS.md CLAUDE.md`. One source of truth, read by every tool.

## Philosophy

The goal is not to make Claude do more. It is to make Claude predictable. A well-structured config means I can hand off a full feature and trust the output meets the same bar as a senior engineer review, without having to re-explain the architecture every session.

## Author

[Dharma Yudistira](https://dharma-yudistira.com), Frontend and Flutter Engineer based in Sidoarjo, Indonesia.
