---
description: Knowledge phase — update project memory from this cycle's outcomes
---

Run the Knowledge phase.

1. Read `review/review-report.md`, `review/qa-report.md`, `tasks/task-graph.md`, and
   `planning/engineering-plan.md` for this cycle.
2. Dispatch to the `memory-keeper` subagent to update, as applicable:
   - `memory/adrs/` — new ADR for any decision with lasting architectural impact
   - `memory/decisions.md` — lighter-weight decisions
   - `memory/lessons-learned.md` — what broke and what prevents it next time
   - `memory/sprint-summary.md` — one entry for this cycle
   - `memory/coding-standards.md` — new rules distilled from lessons learned
   - `memory/apis.md` / `memory/database-schema.md` — any interface/schema changes
   - `memory/glossary.md` — new terms introduced
   - `memory/technical-debt.md` — new debt opened, or existing debt resolved
   - `memory/implementation-patterns.md` — reusable patterns worth repeating
3. Append-only for logs (decisions, lessons, sprint summary) — never rewrite history.
4. Report a short diff of what memory was updated, so the user can sanity-check it before the
   next `/plan` picks it up.
