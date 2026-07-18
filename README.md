# dotclaude

My personal Claude Code configuration. A two-layer setup that makes Claude a reliable engineering partner across all my projects, not just a code generator.

## How it works

Configuration is split by scope. Rules that hold everywhere live at the global layer. Rules that only make sense inside one codebase live with that codebase.

```
dotclaude/
└── CLAUDE.md        ← global rules (applies everywhere)

your-project/
├── CLAUDE.md        ← project-level config
└── .claude/         ← per-project Claude setup
```

### Layer 1: Global (`CLAUDE.md`)

This repo. Defines how Claude should think and communicate regardless of project: mindset, code principles, communication style, safety guardrails, commit format, and tool preferences. It applies to every session across every codebase.

The four-point structure is adopted from Andrej Karpathy's CLAUDE.md, with my own conventions layered on top. The sections are deliberately ordered. Think before coding, then simplicity first, then surgical changes, then goal-driven execution. Each one constrains the next.

### Layer 2: Per-project

Lives in the project repo, not here. It layers in what the global rules cannot know: architecture overview, conventions, data layer patterns, env vars, and anything else specific to that codebase. Whatever Claude setup a project needs goes in its `.claude/` directory, scoped to that project alone.

## Workflow

How a product actually moves from idea to production. The pipeline runs on [BuilderOS](https://github.com/BuildGreatProducts/builder-os). Its skills share a `docs/` folder, so each stage hands a written artifact to the next and intent survives across sessions instead of living in one chat.

```mermaid
flowchart LR
    A[Ideate] --> B[Plan and design] --> C[Build] --> D[Launch]
```

### 1. Ideate

`/idea-generator` mines what I already know or do for a product idea. `/idea-validator` pressure-tests it before I invest in building: finds the core assumption, ranks fatal flaws, maps real competition.

### 2. Plan and design

`/product-planner` runs a vision intake conversation, then writes strategy, technical specs, and a phased build plan with task checkboxes. That plan is what the build stage consumes.

`/design-system` turns screenshots, mockups, or Figma URLs into a design system in Google's open `design.md` format. Hi-fi screens come from Claude Design and Stitch, before any code exists.

### 3. Build

`/build-mvp` works the roadmap end to end, implementing, testing, and verifying each task before moving on. `/build-loop-claude-code` for a single pass with review gates, so nothing ships on "it compiles."

Frontend, backend, and testing move together rather than in sequence, so a change on one side is reconciled against the others immediately. Testing covers both unit and E2E. `/design-better` is the craft layer for generating or reviewing UI that is designed, not just functional.

### 4. Launch

`/launch-checklist` audits the codebase (stack, services, env vars, payments, deploy config) and writes a plain-English, step-by-step path to ship.

## Philosophy

The goal is not to make Claude do more. It is to make Claude predictable. A well-structured config means I can hand off a full feature and trust the output meets the same bar as a senior engineer review, without having to re-explain the architecture every session.

## Author

[Dharma Yudistira](https://dharma-yudistira.com), Fullstack and Flutter Engineer based in Sidoarjo, Indonesia.
