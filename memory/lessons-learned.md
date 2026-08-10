# Lessons Learned

What broke, what surprised us, what we'd do differently. Written by the `memory-keeper`
subagent after `/review` and `/qa` each cycle. Newest first.

## Format

```markdown
### YYYY-MM-DD — Sprint <N>
- **What happened:** short factual description
- **Root cause:** why it happened
- **Fix applied:** what resolved it this time
- **Prevent next time:** rule or check to add (link to coding-standards.md if it becomes a standard)
```

---

<!-- Entries below this line, newest first -->

### 2026-08-10 — Sprint 1
- **What happened:** Running 3+ `task-runner` agents fully in parallel in one wave, in a repo
  that lives under iCloud Drive (`~/Documents/...`), produced real iCloud "conflicted copy"
  duplicate files (` 2.swift`, ` 2.entitlements`) and duplicate `.xcodeproj` bundles during one
  earlier implementation wave. This could have silently corrupted a build (stale/duplicate
  source files picked up by Xcode) if it had gone unnoticed until later in the cycle.
- **Root cause:** iCloud Drive's file-provider sync treats near-simultaneous writes to the same
  or nearby files/directories from multiple processes as conflicting edits and materializes a
  numbered "conflicted copy" instead of merging or failing loudly — this is invisible unless
  someone explicitly looks for it, since the build can still succeed by picking up the
  original file and simply leaving the duplicate inert (until it isn't).
- **Fix applied:** The stray duplicates were found and removed before they caused a build
  break. Parallelism was capped at 2 `task-runner` agents per wave for the rest of the cycle,
  keeping concurrent agents in clearly separate folders/targets, and a duplicate check
  (`find . -iname "*.entitlements"`, `ls | grep xcodeproj`, plus a general
  `find . -iname "* [0-9].*"` sweep) was run after every wave before trusting a build.
- **Prevent next time:** Codified as a process rule in `memory/coding-standards.md` under
  "Standards added from lessons learned" — cap parallel `task-runner` agents at 2 per wave when
  the repo lives under iCloud Drive (or any other sync-managed folder), and run the
  stray-duplicate sweep after every wave, not just when something looks wrong.

### 2026-08-10 — Sprint 1
- **What happened:** `.gitignore`'s bare `*.md` line (line 1, present since T1's scaffolding)
  silently gitignored every Markdown file in the repository — `README.md`, `CLAUDE.md`, and
  everything under `planning/`, `tasks/`, `memory/`, and `review/`. Since this project's entire
  workflow depends on those directories being version-controlled so knowledge persists across
  cycles, this defect would have silently defeated the whole point of `memory/` the first time
  anyone ran `git add`/`git commit` — no individual task's acceptance criteria named
  `.gitignore`'s content, so no task self-report caught it. It was only caught by `/review`'s
  ground-truth verification pass (`git check-ignore -v` against known project docs), and
  confirmed fixed by `/qa`'s independent re-check in the same session.
- **Root cause:** A repo-wide config file (`.gitignore`) is nobody's task-scope by default —
  it's created once during scaffolding and then nobody's acceptance criteria ever revisits it,
  so a single overly-broad line can sit unnoticed indefinitely unless something explicitly
  audits it.
- **Fix applied:** `.gitignore`'s bare `*.md` line was removed (or scoped) before this cycle's
  work was ever committed; `/review` verified the fix and `/qa` independently reconfirmed it
  via `git check-ignore -v` against `README.md`, `CLAUDE.md`, `planning/engineering-plan.md`,
  `memory/apis.md`, `tasks/task-graph.md`, and `review/review-report-template.md` — none
  currently ignored.
- **Prevent next time:** `/review` should keep treating repo-wide config files (`.gitignore`,
  linter configs, CI config, `project.yml` target-wide settings) as in-scope for its own
  ground-truth verification pass even when no single task claims ownership of them — this
  worked as intended this cycle and should stay standard practice, not become a one-off catch.
