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

### 2026-08-11 — Sprint 2
- **What happened:** `Apin/ApinApp.swift` and `ApinWidget/JournalWidgetStore.swift` hardcoded
  `appGroupIdentifier = "group.com.kv.apin"` (plus a stray `iCloud.com.kv.apin` doc comment),
  drifted from `project.yml`'s real, already-updated entitlement value
  (`group.com.apin.app`/`iCloud.com.apin.app`). This drift was invisible for an unknown number of
  cycles because the checked-in, stale `Apin.entitlements`/`ApinWidget.entitlements` files still
  had the old `com.kv.apin` values too — self-consistent with the Swift literals, just
  inconsistent with `project.yml`. It only surfaced when T2's mandatory `xcodegen generate` step
  regenerated the entitlements from `project.yml` (the true source of truth), at which point the
  regenerated entitlement (`group.com.apin.app`) no longer matched the Swift-source literal
  (`group.com.kv.apin`), and the app started `fatalError`-ing at launch
  (`"App Group container 'group.com.kv.apin' is not reachable..."`) — a launch-blocking
  regression discovered and fixed directly by the orchestrating session, not by any task-scoped
  fix, and independently re-verified end-to-end by both `/review` and `/qa`.
- **Root cause:** An identifier rename (`com.kv.apin` → `com.apin.app`) was applied to
  `project.yml` in an earlier cycle but missed two hardcoded Swift-source literals (
  `ApinApp.swift`'s `appGroupIdentifier` + doc comment, `JournalWidgetStore.swift`'s
  `appGroupIdentifier`) and their pinned regression tests. The already-generated, stale
  `.entitlements` files (checked into git, not regenerated since the rename) happened to still
  match the wrong Swift literals, so nothing looked broken until the next `xcodegen generate`
  regenerated them from the real source of truth — a generated artifact silently masked a source
  drift for an indefinite number of cycles.
- **Fix applied:** Both Swift literals and the stray doc-comment reference updated to
  `group.com.apin.app`/`iCloud.com.apin.app`; the two pinned regression tests
  (`ApinAppModelConfigurationTests`, `JournalWidgetStoreTests.test_appGroupIdentifier_...`)
  updated to assert the corrected literal; reconfirmed via a full `xcodebuild test` run (no
  `fatalError` at launch) and logged in `memory/technical-debt.md`'s "App Group / iCloud container
  identifier drift" entry (resolved).
- **Prevent next time:** Any identifier/literal rename (App Group IDs, bundle IDs, iCloud
  container IDs, or any other value mirrored into `.entitlements`/`Info.plist` by XcodeGen) must
  grep across generated-artifact-adjacent Swift sources for the *old* literal in the same change
  that updates `project.yml` — not just update `project.yml` and trust that a stale, already-
  generated artifact will be regenerated soon. A stale generated artifact (entitlements, Info.plist)
  can mask source drift indefinitely because it "looks consistent" with the stale Swift literal
  even though both are wrong relative to the real source of truth. Promoted to a standing check in
  `memory/coding-standards.md`.
- **Related, not promoted to a standing rule:** the stray, git-tracked duplicate
  `Apin 2.xcodeproj` at repo root has now been independently flagged four times across two cycles
  (T3, T11, both Cycle-2 `/review` passes) without ever being cleaned up — a process gap, not a
  code defect: nobody owns repo-root cleanup unless a task explicitly claims it, so a known-dead,
  confirmed-harmless artifact just keeps getting re-discovered instead of removed. Logged as open
  debt (`memory/technical-debt.md`) with an explicit recommendation to schedule a trivial,
  dedicated cleanup task with Kv's go-ahead, rather than relying on it being caught "for free" by
  a future review pass again.

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
