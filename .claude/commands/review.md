---
description: Review phase — merge and integration-check all in-review tasks
---

Run the Review phase.

1. Collect every task in `tasks/task-graph.md` marked `in-review`. If none, say so and stop.
2. Dispatch to the `reviewer` subagent with those tasks' changes plus `memory/adrs/`,
   `memory/apis.md`, `memory/database-schema.md`, and `memory/coding-standards.md`.
3. The reviewer merges the outputs, detects conflicts between tasks, and checks architecture
   consistency, API compatibility, naming, and coding standards across the combined result.
4. Write `review/review-report.md` following `review/review-report-template.md`.
5. For tasks that pass, mark them `done` in the task graph; for tasks needing rework, mark
   them back to `in-progress` with the specific issue noted in the task graph's Notes.
6. State clearly whether the cycle is ready for `/qa`.
