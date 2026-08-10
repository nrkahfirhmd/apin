---
description: "Run the full loop end to end: Planning → Implementation → Review → Knowledge"
---

Run the full agentic coding loop, pausing at the checkpoints marked below.

1. `/plan` — then **stop** and wait for the user to confirm the engineering plan before continuing.
2. `/tasks` — generate the task graph.
3. For each runnable task, `/implement <task-id>`, respecting dependencies in the task graph
   (run independent tasks in parallel where possible).
4. `/review` — if it reports issues, loop back to step 3 for the flagged tasks before continuing.
5. `/qa` — if it fails, loop back to step 3 (or step 1 if the issue is a planning gap) before continuing.
6. `/remember` — update project memory.
7. Report a cycle summary: what shipped, QA verdict, and what's queued for next cycle.

Never skip step 4, 5, or 6 to save time — that's what keeps the next cycle fast.
