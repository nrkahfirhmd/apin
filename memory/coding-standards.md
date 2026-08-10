# Coding Standards

The rules every `task-runner` and `reviewer` agent checks against. Keep this current — it's
the first thing `/review` reads.

Promoted verbatim from `planning/engineering-plan.md`'s "Coding standards proposal" after
holding up cleanly across all 18 tasks in Sprint 1 (0 SwiftLint violations at any point,
`swiftlint lint` still 0 violations across 78 files as of the Sprint 1 `/review`/`/qa` passes).

## Naming

- Swift API Design Guidelines: `UpperCamelCase` for types/protocols, `lowerCamelCase` for
  properties/functions/enum cases.
- One primary type per file, filename matches the type (`JournalEntry.swift`,
  `AskApinIntent.swift`) — see the explicit carve-out under Structure below for small,
  tightly-coupled private helper types.
- View models suffixed `ViewModel` (`AskViewModel`); SwiftData models suffixed nothing extra
  (`JournalEntry`, not `JournalEntryModel`).
- Protocols describing a capability end in `-ing`/`-able` where natural
  (`ModelSessionProviding`, `CapabilityGating`, `AskAndSaveServicing`,
  `LanguageModelSessionProviding`, `OSVersionProviding`); otherwise a plain noun. Named
  event-payload/seam types (e.g. `JournalEntrySaveSideEffect`, `JournalEntryDeleteSideEffect`)
  are a reasonable use of the "otherwise a plain noun" fallback — they describe a role/event,
  not a capability, so `-ing`/`-able` naming is not required for them.

## Structure

- Folder-by-feature at the app-target level (`Features/Ask`, `Features/Journal`,
  `Features/Widgets`).
- Shared non-UI code lives in the `ApinCore` local Swift package, under `Sources/AI`,
  `Sources/Persistence`, `Sources/AppIntents`.
- UI layers (app target, widget extension) may depend on `ApinCore`; **`ApinCore` may never
  import SwiftUI or UIKit** — this keeps the AI/persistence layer reusable from the widget and
  App Intents call sites without pulling in app-target UI code. Verify with
  `grep -rn "^import SwiftUI\|^import UIKit" ApinCore/Sources/` (must return zero matches) —
  use the anchored `^import` pattern, not a bare substring search, since files legitimately
  contain the string "UIKit" inside comments explaining this very rule.
- **Exception to one-primary-type-per-file**: a small, tightly-coupled private helper type may
  share a file with its primary type when it's not reused elsewhere and exists specifically to
  support that primary type (e.g. a view model's own state `enum` colocated with the view
  model class, or a private helper `View` colocated with the screen that's its only caller).
  This is a filing convenience, not license for sprawl — if SwiftLint flags it, or if the
  helper type ever gains a second caller, split it into its own file.
- Exact SDK-boundary exceptions to "shared code lives in `ApinCore`" are recorded as ADRs, not
  silently absorbed into this file — see `memory/adrs/001-app-intents-split-across-apincore-and-app-target.md`
  for the current one (App Intents orchestration split across `ApinCore`/app target for a real,
  verified `AppShortcutsProvider` discovery constraint).

## Style

- SwiftLint, Swift's default rule set plus `line_length: 120` (warning tier, not error).
- Trailing closures preferred.
- `async/await` preferred over completion-handler APIs for all new code. SDK-mandated
  completion-handler signatures (e.g. WidgetKit's `TimelineProvider`) are a documented
  exception — explain in-file why the callback isn't bridged to `Task`/`@MainActor` when this
  applies.
- `// MARK: -` section markers in files over ~150 lines.

## Testing

- New logic in `Core/AI` and `Core/Persistence` (i.e. `ApinCore/Sources/AI`,
  `ApinCore/Sources/Persistence`) requires unit tests in the same task/PR.
- Test files mirror the source path under `Tests/` with a `Tests` suffix
  (`JournalRepositoryTests.swift`, `PortableExportWriterTests.swift`).
- SwiftUI views are not required to have tests unless they contain non-trivial logic (e.g. a
  view model, or a testable query-builder function extracted out of the view).
- AI response *content* is explicitly out of scope for automated tests — it's non-deterministic
  on-device generation. What *is* tested: error-handling paths (timeout, unavailable, refusal)
  via a fake/mock session, and prompt/instruction *structure* (not wording).
- XCUITest is optional/deferred for this project (solo dev, no deadline) — manual `/qa` is the
  primary UI safety net.

## Commit / PR conventions

- Conventional Commits (`feat:`, `fix:`, `chore:`, `docs:`, `refactor:`, `test:`), imperative
  mood subject line.
- Reference the task ID in the commit body when the commit closes a `tasks/task-graph.md` item
  (e.g. `Refs: T6`).
- Branch naming: `feature/<short-desc>` or `fix/<short-desc>`.

## Standards added from lessons learned

- **iCloud Drive parallelism cap (added Sprint 1, see `memory/lessons-learned.md`)**: when the
  repo lives under an iCloud-Drive-synced folder (as this one does, `~/Documents/...`), whoever
  orchestrates `/implement` calls must cap parallel `task-runner` agents at **2 per wave**, keep
  concurrent agents in clearly separate folders/targets, and after every wave run a
  stray-duplicate sweep before trusting a build — at minimum `find . -iname "* [0-9].*"` (catches
  numbered iCloud "conflicted copy" files like ` 2.swift`/` 2.entitlements`) and a check for a
  duplicated `.xcodeproj` bundle (`ls | grep xcodeproj`). Running 3+ agents in parallel in this
  repo has already produced real conflicted-copy duplicates once; treat this as a standing
  constraint, not a one-time cleanup.
- **Repo-wide config files are nobody's task-scope by default (added Sprint 1, see
  `memory/lessons-learned.md`)**: `/review`'s ground-truth verification pass must explicitly
  check repo-wide config (`.gitignore`, linter config, CI config, `project.yml` target-wide
  settings) even though no single task's acceptance criteria names them — Sprint 1's
  `.gitignore` bare `*.md` defect (silently gitignoring all of `planning/`, `tasks/`, `memory/`,
  `review/`, and `README.md`/`CLAUDE.md`) was only caught this way.
