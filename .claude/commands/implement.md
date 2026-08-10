---
description: "Implementation phase — implement one task. Usage: /implement <task-id>"
argument-hint: <task-id>
---

Implement task $ARGUMENTS from `tasks/task-graph.md`.

1. Look up task $ARGUMENTS in `tasks/task-graph.md`. If any of its dependencies are not
   `done`, stop and report the block instead of proceeding.
2. Mark the task `in-progress` in the task graph.
3. Dispatch to the `task-runner` subagent with: the task's section from the task graph, the
   relevant slice of `planning/engineering-plan.md`, and `memory/coding-standards.md` /
   `memory/implementation-patterns.md` for conventions to follow.
4. The task-runner implements the task's scope only — it must not touch files outside that
   scope without flagging it first.
5. On completion, mark the task `in-review` in the task graph and summarize what changed.

Multiple independent tasks (no shared unfinished dependency) may be run this way in parallel,
each in its own pass.
