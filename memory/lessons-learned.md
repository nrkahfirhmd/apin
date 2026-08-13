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

### 2026-08-12 — Sprint 5
- **What happened:** Two related-but-distinct issues surfaced this cycle. (1) T2 added
  `sendStructured(prompt:)` to `AssistantSessionProviding` — a real, necessary protocol change,
  entirely within T2's own scope. But `ApinTests/FakeAssistantSession.swift`, an existing test
  double conforming to that protocol, was outside *both* T2's scope (it's an app-target test file,
  T2 was `ApinCore`-scoped) and T5's scope (T5 touched `ContentView`/`AskView`/`JournalListView`,
  not test doubles) — so neither task-runner updated it, and it silently stopped compiling until
  T5's task-runner happened to run a full `xcodebuild build-for-testing` and caught the break.
  (2) Separately, fixing 7 SwiftLint `identifier_name` violations in `Apin/DesignSystem/ApinFont.swift`/
  `ApinColor.swift` took two failed attempts before landing: a `// swiftlint:disable:next` line
  placed between a `///` doc comment and its declaration breaks `orphaned_doc_comment` (the doc
  comment is no longer adjacent to the declaration); placed *before* the doc comment, `:next`
  silences the doc-comment line instead of the declaration, producing a `superfluous_disable_command`
  warning. Both are now documented as a coding standard — see `memory/coding-standards.md`.
- **Root cause:** (1) A protocol conformance change was scoped narrowly and correctly per its own
  task, but nothing in the task-graph/review process explicitly checks "does any *other* file
  outside every task's own scope also conform to this protocol and now need updating?" — this
  only surfaces if some task's own build verification happens to include the broken file, which
  isn't guaranteed. (2) SwiftLint's `:next` disable-command semantics (silences exactly the next
  line) and `orphaned_doc_comment`'s adjacency requirement were not obvious from the rule names
  alone and had to be discovered by direct trial.
- **Fix applied:** (1) The orchestrator added the missing conformance to `FakeAssistantSession.swift`
  directly (small, mechanical, same shape as the existing `send`/`sendBehavior` pair), re-verified
  by an independent `build-for-testing` run, then by `/review`. (2) Landed on: plain `//`
  description comment(s), then `// swiftlint:disable:next <rule>` immediately above the
  declaration, no `///` doc comment on lines needing a disable directive.
- **Prevent next time:** When a task changes a protocol's requirements, the task-graph or the
  reviewer's ground-truth pass should explicitly grep for *all* conformances to that protocol
  (`grep -rn ": ProtocolName\b"` or similar), not just the conformances the changing task itself
  intends to touch — test doubles in particular are easy to miss since they're often outside any
  single task's stated file scope. Added to `memory/coding-standards.md`'s "Standards added from
  lessons learned" as the SwiftLint disable-command ordering rule; this protocol-conformance-sweep
  practice is recorded here as a process lesson rather than a hard rule, since it didn't cause
  lasting harm this cycle (caught same-day, before `/review` even ran) — worth promoting to a
  standing coding-standards check if it recurs.

### 2026-08-11 — Sprint 3
- **What happened:** At the start of this cycle, the orchestrating session found
  `Apin.xcodeproj/project.pbxproj`, `Apin/Apin.entitlements`, `Apin/ApinApp.swift`,
  `ApinTests/ApinAppModelConfigurationTests.swift`, `ApinWidget/ApinWidget.entitlements`,
  `ApinWidget/JournalWidgetStore.swift`, and `ApinWidgetTests/JournalWidgetStoreTests.swift`
  showing as modified in `git status`. It assumed — based on `memory/technical-debt.md`'s "App
  Group / iCloud container identifier drift" entry narrating this exact file set as "resolved
  (Cycle 2, ...)" — that this uncommitted working-tree diff represented cycle 2's already-verified
  fix, and committed it directly (`042452c`, message: "fix: correct App Group/iCloud container
  identifier drift (com.kv.apin -> com.apin.app)") without reading the actual diff content first.
  The diff ran exactly backwards: `project.yml` had always been correct
  (`group.com.apin.app`/`iCloud.com.apin.app`), and the previously-committed `0daefc7` already had
  the correct values in both Swift-source literals. The uncommitted diff actually *reverted*
  `ApinApp.swift`/`JournalWidgetStore.swift` and their two pinned regression tests back to the old,
  broken `group.com.kv.apin`, and also reverted `project.pbxproj`/entitlements to an
  older-generated shape (missing `DEVELOPMENT_TEAM`, wrong widget product naming
  `ApinWidgetExtension.appex` vs. `ApinWidget.appex`, array-vs-string `UIBackgroundModes` plist
  formatting). This went undetected through `/plan`, `/tasks`, `/implement` (T1–T4), and the first
  `/review` pass (which correctly scoped itself to only T1–T4's diffs and had no reason to audit an
  already-committed, unrelated commit). It was caught by the first `/qa` pass, which ran the full
  `xcodebuild test -only-testing:ApinTests -only-testing:ApinWidgetTests` suite independently and
  hit the exact `fatalError: "App Group container 'group.com.kv.apin' is not reachable..."` crash
  that `memory/technical-debt.md` had documented as this bug class's symptom before (0/26
  `ApinTests`, launch crash). The orchestrating session then fixed it directly (not via a
  task-runner, since it wasn't task-graph scope) by editing the 4 Swift-source spots back to
  `group.com.apin.app`/`iCloud.com.apin.app`, regenerating `project.pbxproj`/entitlements via
  `xcodegen generate` (never hand-editing them), and committing the fix as `b7c1536`. A second,
  independent `/qa` pass then re-verified everything from scratch (re-read all 4 files directly,
  re-ran the exact test invocation that had crashed, re-ran install+launch+alive-check on the same
  simulator UDID) and confirmed 131/131 tests passing.
- **Root cause:** A stale, uncommitted working-tree snapshot (plausibly an iCloud Drive sync
  artifact, per `b7c1536`'s own commit message's plausible-cause note) sat in the repo across a
  session boundary. It was committed on the strength of what a memory file's narrative said the
  diff *should* contain ("this matches cycle 2's already-resolved App Group fix"), not on what the
  diff actually contained. No test run gated the commit before it landed.
- **Fix applied:** `b7c1536` — a byte-for-byte inverse of `042452c` across the same 7 files,
  independently re-verified (not trusted from either commit's message) by direct source reads, a
  full `xcodebuild test` re-run of the exact invocation that had crashed, and a fresh
  `simctl install`/`launch` on the same device. 131/131 tests confirmed passing.
- **Prevent next time:** Before staging or committing any pre-existing uncommitted diff that
  wasn't personally authored this session, `git diff` (or equivalent) and read the actual content
  of every hunk — don't infer what it contains from what a `memory/` file's narrative says was
  already fixed, and don't trust a commit message's own stated direction (X → Y) without
  confirming the diff runs that direction. This applies with extra weight to security/identity-
  sensitive literals (App Group IDs, bundle IDs, iCloud container IDs) and to any file class with a
  history of drift — this exact file set has now drifted twice (the original Sprint-1-adjacent
  drift documented in the 2026-08-11 Sprint 2 entry below, and now this). Promoted to a standing
  rule in `memory/coding-standards.md`.
- **How this differs from the Sprint 2 entry below:** that entry is about a *rename* (`com.kv.apin`
  → `com.apin.app`) missing two Swift-source literals during an edit. This incident is about
  committing a *pre-existing, unread* working-tree diff that happened to run the rename backwards —
  a distinct trigger (commit hygiene on inherited state, not an edit that missed a call site), even
  though both incidents involve the same literal and the same file set. Also distinct from the
  Sprint 1 iCloud-Drive-parallelism entry further below: that one is about *parallel* `task-runner`
  agents producing sync-layer "conflicted copy" duplicates; this incident involved one agent acting
  alone, at a normal pace, committing a stale/inverted snapshot without reading it first — same
  underlying "repo lives under iCloud Drive" risk factor, different mechanism.

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
