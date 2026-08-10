# Database Schema

Current schema, kept in sync with migrations by `memory-keeper`. Don't hand-edit around a
migration — update this file in the same task that adds the migration.

## Format

```markdown
### <table_name>
| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | uuid | PK | |

Relations: <foreign keys, one-to-many, etc.>
Added/changed in: sprint / task ID
```

---

<!-- Tables below this line -->

### JournalEntry (SwiftData `@Model`)
| Column | Type | Constraints | Notes |
|---|---|---|---|
| id | UUID | PK (application-level only — **not** DB-enforced-unique as of T18) | `@Attribute(.unique)` was removed in T18 because SwiftData's CloudKit mirroring does not support unique constraints on `@Model` properties. No current code path produces a duplicate `id` (every construction uses a fresh `UUID()`), but this is a real, deliberate trade-off, not a mistake — see `memory/technical-debt.md` ("No DB-level uniqueness guarantee on `JournalEntry.id` post-CloudKit"). |
| question | String | required, inline default (see Notes) | The user's typed/prefilled question. |
| answer | String | required, inline default | The model's generated answer. |
| createdAt | Date | required, inline default | Save timestamp; drives reverse-chronological ordering and day-grouping in the Journal list, and streak/date-grouping logic if T21 is picked up later. |
| tags | [String] | required, inline default (empty array) | Schema field exists as of T6, **unused this cycle** — no UI writes to it. T20 (deferred, Nice-to-have) will consume it if picked up in a future cycle. |

Relations: none (single flat entity, no foreign keys — no other persisted model exists yet).

Store location: shared **App Group container** `group.com.apin.app`, file `ApinJournal.sqlite`.
Both `Apin/ApinApp.swift` (app target) and `ApinWidget/JournalWidgetStore.swift` (widget
extension) construct their own `ModelConfiguration`/`ModelContainer` pointed at this exact
container identifier + filename so the widget can read real app data — see
`memory/adrs/002-shared-app-group-swiftdata-store-for-widget.md`. CloudKit-mirrored via
`ModelConfiguration(cloudKitDatabase: .automatic)` (T18) — sync is structurally wired and unit
tested, but live cross-device sync has never been exercised (no iCloud dev account available
this cycle; see `memory/technical-debt.md`).

Note on property defaults: every stored property (`id`, `question`, `answer`, `createdAt`,
`tags`) carries an inline default value as of T18 — required so Core Data's CloudKit-mirroring
delegate can materialize incoming records without routing through the model's custom `init`.

Added/changed in: T6 (Sprint 1, model + repository), T18 (Sprint 1, `@Attribute(.unique)`
removal + inline defaults + CloudKit `ModelConfiguration`), T16 (Sprint 1, widget-side shared
App Group `ModelConfiguration`, later completed by T18's app-side half).
