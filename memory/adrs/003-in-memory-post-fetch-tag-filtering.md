# 003. Tag filtering on `JournalEntry.tags` is applied in-memory, post-fetch — never via `#Predicate`

Status: Accepted
Date: 2026-08-11
Sprint: Sprint 2 (see memory/sprint-summary.md)

## Context

T11 added tag entry/edit UI and a tag filter to journal search, extending `JournalQuery` with a
`tagFilter`/`tag` parameter to AND-combine with the existing keyword/date-range filtering. The
natural first approach was to fold the tag condition into the same SwiftData `#Predicate` already
used for keyword/date-range filtering, so all filtering happens in a single database fetch.

That approach was directly attempted and directly reproduced as broken, not assumed to be
broken: `JournalEntry.tags` is a `[String]` (a transformable/non-relationship Core Data
attribute in the underlying SQL store), and:
- `entry.tags.contains("someTag")` inside a `#Predicate` **segfaults the process at fetch time**.
- `entry.tags.contains(where: { $0 == "someTag" })` inside a `#Predicate` **throws
  `NSInvalidArgumentException: "Can't have a non-relationship collection element in a
  subquery"`**.

Both are confirmed, reproducible SwiftData/Core Data limitations on this exact storage shape —
not a bug in this codebase's predicate-building logic, and not something a different predicate
phrasing works around (both the direct-membership and closure-membership forms fail, in two
different ways). This is a real constraint on how `JournalQuery` can filter `tags` for as long as
the property remains a plain `[String]` on a SwiftData `@Model`, not an implementation detail
scoped to T11 alone.

## Decision

`JournalQuery.tagFilter` is applied as a **separate, in-memory, post-fetch filter**
(`JournalQuery.applyTagFilter(to:)`), never folded into the `#Predicate` used for the
keyword/date-range portion of the query. The SwiftData fetch runs first (keyword + date-range
only, via `#Predicate`, unchanged from before T11), and the tag condition is applied afterward as
a plain Swift `Array` filter over the fetched results. This exact function
(`JournalQuery.applyTagFilter(to:)`) is called identically at every call site that reads
tag-filterable data — currently `SwiftDataJournalRepository.fetch(matching:)` (after the SwiftData
fetch) and `JournalListView.JournalEntryListContent.entries` (a computed property over the
`@Query`-fetched array) — specifically so the two call sites can't drift into applying the tag
rule differently.

## Alternatives considered

- **Fold tag matching into the `#Predicate` directly** (`entry.tags.contains(tag)` or
  `.contains(where:)`) — rejected: directly reproduced as broken (segfault or
  `NSInvalidArgumentException`), not a style preference.
- **Change `JournalEntry.tags`'s storage shape** (e.g. a relationship to a separate `Tag` model,
  or a single delimited `String` with app-level split/join) to make `#Predicate`-based filtering
  possible — rejected for this cycle: `tags: [String]` is an existing, already-shipped schema
  field (T6, Sprint 1) with CloudKit-mirroring implications already accounted for
  (`memory/database-schema.md`'s inline-default note); migrating its storage shape is a real
  schema change with CloudKit-mirroring risk of its own, out of scope for what was meant to be a
  small Nice-to-have tagging feature. Worth reconsidering only if a future cycle needs
  database-level tag filtering (e.g. for performance at very large journal sizes).
- **Fetch all entries and always filter entirely in memory, dropping `#Predicate` for
  keyword/date-range too** — rejected: keyword/date-range filtering via `#Predicate` works fine
  today and pushing that filtering into the database is strictly better for scale; there's no
  reason to regress that path just because `tags` can't join it.

## Consequences

- Establishes a load-bearing fact for any future SwiftData work in this codebase: **`[String]`
  (transformable-attribute) properties on a `@Model` cannot be filtered via `#Predicate`'s
  `.contains(_:)`/`.contains(where:)` — any future array-typed property that needs query-level
  filtering will hit the same wall** and should plan for the same in-memory-post-fetch pattern
  (or a relationship-based schema redesign) from the start rather than rediscovering this by
  reproducing a segfault again.
- Means `JournalQuery`'s tag filtering does not scale down fetch size the way keyword/date-range
  filtering does — every keyword/date-range-matching entry is fetched from SwiftData before the
  tag filter narrows it further in memory. Acceptable at this app's expected journal sizes
  (personal study journal, not a multi-tenant dataset); would need revisiting if journal size
  assumptions change materially in a future cycle.
- Creates a two-call-site consistency requirement (`SwiftDataJournalRepository.fetch(matching:)`
  and `JournalListView.JournalEntryListContent.entries`) that isn't enforced by the type system —
  currently mitigated by both call sites routing through the exact same
  `JournalQuery.applyTagFilter(to:)` function (a "single function, called everywhere" pattern
  rather than "same logic reimplemented twice"), verified by `/review`'s ground-truth diff read.
  A future third call site must route through the same function, not reimplement the filter.
- `memory/database-schema.md`'s `tags` column Notes cell documents this constraint alongside the
  schema itself, so the "why in-memory" reasoning stays visible next to the field it constrains,
  not just in this ADR.
