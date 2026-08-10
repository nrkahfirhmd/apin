# Agentic Coding Workflow

This repo runs on a fixed 4-phase loop: **Planning → Implementation → Review → Knowledge**.
Knowledge feeds back into the next Planning cycle. Read this file at the start of every
session — it is your working memory. Full detail lives under `memory/`.

## The loop

1. **Planning** — `planning/spec.md` (source of truth) → `/plan` produces
   `planning/engineering-plan.md` (backlog, architecture decisions, constraints, definition of done).
2. **Implementation** — `/tasks` turns the engineering plan into `tasks/task-graph.md`
   (tasks + dependencies). `/implement <task-id>` runs one task via the `task-runner` subagent.
   Independent tasks may run in parallel; dependent tasks wait.
3. **Review** — `/review` runs the `reviewer` subagent: merges task outputs, flags conflicts,
   checks architecture/API compatibility/naming/coding-standards, writes `review/review-report.md`.
   `/qa` runs the `qa-validator` subagent: runs tests, writes `review/qa-report.md` with a
   pass/fail verdict and release readiness.
4. **Knowledge** — `/remember` runs the `memory-keeper` subagent: updates `memory/` with ADRs,
   decisions, lessons learned, sprint summary, coding standards, APIs, schema, glossary, tech
   debt, and implementation patterns. These update the next cycle's spec/plan.

Run the whole loop with `/cycle`, or drive each phase manually with the commands above.

## Working conventions

- Never skip Review or Knowledge, even under time pressure — QA and memory updates are what
  keep later cycles fast and safe.
- A task is only "done" when it satisfies the Definition of Done in `planning/engineering-plan.md`.
- Before starting new work, check `memory/technical-debt.md` and `memory/decisions.md` so you
  don't relitigate settled questions or ignore known debt.
- Record every non-trivial architectural choice as an ADR in `memory/adrs/`, not just in chat.

## Directory map

- `planning/` — spec and engineering plan (source of truth for the current cycle)
- `tasks/` — task graph and per-task specs
- `review/` — review and QA reports
- `memory/` — persistent project knowledge (survives across cycles)
- `.claude/commands/` — slash commands for each phase
- `.claude/agents/` — subagents for each phase

See `README.md` for the full usage guide.
