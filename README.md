# Agentic Coding

A Claude Code project scaffold implementing a 4-phase agentic coding loop:

**Planning → Implementation → Review → Knowledge**, with Knowledge feeding back into the next
cycle's Planning.

This mirrors the workflow diagram it's based on: Spec/PRD drives an Engineering Plan, which
becomes a Task Graph of parallel tasks, which get merged and validated in Review, which updates
a persistent Project Memory that informs the next cycle.

## Requirements

Run this with [Claude Code](https://code.claude.com) inside this folder — the slash commands
and subagents in `.claude/` only work there (not in a plain chat session).

## Quick start

1. Copy `planning/spec-template.md` to `planning/spec.md` and fill it in — this is your
   source-of-truth document for the cycle.
2. Open this folder in Claude Code.
3. Run `/plan` to generate `planning/engineering-plan.md`. Review it.
4. Run `/tasks` to generate `tasks/task-graph.md`.
5. Run `/implement <task-id>` for each runnable task (independent tasks can be run in
   parallel — see the task graph's dependency column).
6. Run `/review`, then `/qa`.
7. Run `/remember` to update `memory/` with what this cycle learned.

Or run `/cycle` to drive the whole loop, pausing at the checkpoints it defines.

## Folder layout

| Path | Diagram box | Purpose |
|---|---|---|
| `planning/spec.md` | Spec/PRD | Source of truth for the cycle |
| `planning/engineering-plan.md` | Engineering Plan | Backlog, architecture decisions, constraints, DoD |
| `tasks/task-graph.md` | Task Graph / Task 1..N | Tasks and dependencies |
| `review/review-report.md` | Review & Integration | Merge, conflicts, architecture/API/naming/standards checks |
| `review/qa-report.md` | QA & Validation | Test results, coverage, release verdict |
| `memory/` | Project Memory | ADRs, decisions, lessons learned, sprint summaries, standards, APIs, schema, glossary, tech debt, patterns |
| `.claude/commands/` | — | `/plan /tasks /implement /review /qa /remember /cycle` |
| `.claude/agents/` | — | `planner`, `task-runner`, `reviewer`, `qa-validator`, `memory-keeper` |

## Design notes

- **Templates vs. live files.** `*-template.md` files are references; the commands write to
  the live filename (`spec.md`, `engineering-plan.md`, `task-graph.md`, etc.) which is what
  gets read on subsequent runs.
- **Memory is append-only for logs.** `decisions.md`, `lessons-learned.md`, and
  `sprint-summary.md` grow over time — newest entries on top, nothing deleted. `coding-standards.md`,
  `apis.md`, `database-schema.md`, and `glossary.md` are living documents, edited in place.
- **Don't skip Review or Knowledge.** The loop's value compounds through `memory/` — skipping
  `/remember` means the next `/plan` starts from zero again.
- Everything here is a starting scaffold — edit `CLAUDE.md`, the command files, or the agent
  files directly as this project's actual conventions (language, test runner, standards)
  become clear.
