---
description: Planning phase — turn the spec into an engineering plan
---

Run the Planning phase.

1. Read `planning/spec.md` (if it doesn't exist yet, copy `planning/spec-template.md` there
   and stop, asking the user to fill it in first).
2. Read `memory/decisions.md`, `memory/technical-debt.md`, `memory/coding-standards.md`,
   `memory/apis.md`, and `memory/database-schema.md` for context — don't relitigate settled
   decisions or ignore known debt.
3. Dispatch to the `planner` subagent with the spec and memory context.
4. The planner writes `planning/engineering-plan.md` (copy the structure in
   `planning/engineering-plan-template.md`): sprint backlog, architecture decisions,
   constraints, and a definition of done.
5. Print a short summary of the plan and flag any open questions from the spec that still
   need the user's input before implementation starts.

Do not proceed to `/tasks` automatically — stop and let the user review the plan first.
