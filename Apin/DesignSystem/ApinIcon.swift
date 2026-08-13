// ApinIcon.swift
// Apin
//
// T1 — icon token layer. `design_handoff_apin/README.md`'s "Assets" section names three
// Phosphor icons, regular weight: `book-open-text`, `bookmark-simple`, `arrow-up`, and
// explicitly allows either "the Phosphor SwiftUI package or export SF Symbol equivalents."
// This project has zero external SPM dependencies today (`project.yml`'s `packages:`
// section names only the local `ApinCore` path) -- three icons don't justify introducing
// the first one, so every constant below is an SF Symbol name string, unchanged in
// `project.yml`.
//
// Mappings (each confirmed to exist in the installed SF Symbols catalog this session --
// `/Applications/SF Symbols.app/Contents/Resources/Metadata/name_availability.plist` --
// well below this project's iOS 26 deployment floor):
//
// - `book-open-text` -> `book.pages` (introduced 2023 / SF Symbols 5, iOS 17+): an open
//   book with visible pages, the closest built-in match to Phosphor's open-book-with-text
//   glyph. Plain `book`/`book.fill` (closed book, no pages) read visually flatter than the
//   handoff's open-book reference; `book.pages` is also the exact family
//   `planning/engineering-plan.md`'s Architecture Decisions section names as the intended
//   match ("book.pages/book family for book-open-text").
// - `bookmark-simple` -> `bookmark` (introduced 2019, iOS 13+): SF Symbols' plain,
//   unfilled bookmark ribbon outline -- Phosphor's "regular" (outline) weight is what the
//   handoff asks for ("regular weight" icons throughout), so the unfilled `bookmark`
//   variant is the closer match to "simple" than `bookmark.fill`.
// - `arrow-up` -> `arrow.up` (introduced 2019, iOS 13+): direct 1:1 name/shape match, no
//   judgment call needed.
//
// Visual fit against the handoff's Phosphor reference is a documented judgment call per
// T1's scope, not a formal/automated test -- confirm again once these are actually applied
// to a view (a later cycle; nothing under `Features/*` consumes these constants yet).

/// Namespace for Apin's design-token SF Symbol names, mapped from the handoff's Phosphor
/// icon set. No cases -- `case`-less enum used purely as an uninstantiable constant
/// namespace (see `ApinColor.swift` for the same pattern/rationale).
enum ApinIcon {

    /// Phosphor `book-open-text` -> SF Symbol `book.pages`. Used by the Ask header's
    /// journal button in the handoff.
    static let journal = "book.pages"

    /// Phosphor `bookmark-simple` -> SF Symbol `bookmark`. Used by the Ask answer meta
    /// row's "saved" indicator in the handoff.
    static let saved = "bookmark"

    /// Phosphor `arrow-up` -> SF Symbol `arrow.up`. Used by the Ask composer's circular
    /// send button in the handoff.
    static let send = "arrow.up"
}
