---
description: Implementation phase (setup) — turn the engineering plan into a task graph
---

Run the task-graph step of the Implementation phase.

1. Read `planning/engineering-plan.md`. If it doesn't exist, tell the user to run `/plan` first.
2. Break the sprint backlog into discrete, independently-implementable tasks. Each task should
   be small enough for one `task-runner` run and map back to a backlog item.
3. Identify real dependencies between tasks (shared files/interfaces, ordering requirements) —
   don't invent dependencies that aren't there; the point is to maximize what can run in parallel.
4. Write `tasks/task-graph.md` following `tasks/task-graph-template.md`: a summary table plus
   one `### T<n> — title` section per task with scope, dependencies, and acceptance criteria.
5. Report which tasks are immediately runnable (no unfinished dependencies) vs. blocked.

Do not start implementing tasks — that happens via `/implement <task-id>`.
