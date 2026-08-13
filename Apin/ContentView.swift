// ContentView.swift
// Apin
//
// Root view (T5, Cycle 5). Replaces the previous "just render AskView" placeholder (its own
// header used to flag this explicitly as not a final root-navigation composition) with the
// app's real Ask <-> Journal composition: a two-tab `TabView`. Each tab keeps its own
// `NavigationStack` (`AskView`'s, `JournalListView`'s) — they're siblings under the `TabView`,
// never nested inside one another, so this resolves both views' own header comments asking
// "whichever task composes root navigation should decide whether to flatten these stacks"
// without actually needing to flatten them.
//
// The Journal tab carries a live entry count badge (via `.badge(_:)`, driven by `ContentView`'s
// own `@Query`), satisfying the handoff's "journal button ... live entry count" requirement
// (`planning/engineering-plan.md` backlog item #7) as a tab-bar affordance reachable from the Ask
// screen, rather than a second in-screen button — Stage B (a follow-up cycle) owns matching the
// handoff's exact visual header-button treatment; this task only needs the composition to be
// structurally correct. `.badge(_:)` must be applied to the tab's page content itself (a sibling
// of `.tabItem`), not to anything inside the `tabItem` closure — SwiftUI's `TabView` only reads
// that modifier off the tab's content view when deciding what to draw on the tab bar item.
//
// `WeeklyDigestView`'s entry point (formerly an `AskView` toolbar button, T12) now lives on
// `JournalListView`'s toolbar instead — see that file's header and `memory/decisions.md`'s
// 2026-08-12 "WeeklyDigestView's entry point folds into the recreated Journal header" decision.
//
// `AskDeepLinkCoordinator`'s Spotlight/Siri deep-link prefill-and-submit flow
// (`AskView.swift`'s `applyPendingDeepLinkQueryIfNeeded()`) is unaffected by this composition
// change: `AskView`'s own `.onAppear`/`.onChange(of: AskDeepLinkCoordinator.shared.pendingQuery)`
// wiring is untouched, and `TabView` renders the initially-selected tab's content (Ask, the
// default/first tab here) immediately, so `AskView.onAppear` still fires on launch exactly as it
// did when `AskView` was the entire root view.
//
// T8 hands `AskView` (and, as of T5, `JournalListView`'s digest sheet) a
// `SwiftDataJournalRepository` built from `ApinApp`'s shared `ModelContainer`, so both have a
// real repository to read/write through. One shared instance is constructed per `body`
// evaluation (matching the pre-T5 pattern for `AskView`) rather than stored as a `@State`
// property — `SwiftDataJournalRepository` itself owns a `ModelContext` pointed at the same
// `ModelContainer` either way, and `AskView`/`JournalListView`'s own `@State`-backed storage
// (their view model, their `@Query`s) is only initialized once per view identity by SwiftUI
// regardless of how many times `ContentView.body` re-evaluates.

import ApinCore
import SwiftData
import SwiftUI

struct ContentView: View {
    let modelContainer: ModelContainer

    /// Live entry count for the Journal tab's badge — SwiftData has no count-only fetch API, so
    /// this fetches the same array `JournalRepository.fetchAll()` would and reads `.count`;
    /// identical live-reactivity pattern to `JournalListView.swift`'s own `@Query` (see that
    /// file's header).
    @Query private var journalEntries: [JournalEntry]

    var body: some View {
        let journalRepository = SwiftDataJournalRepository(modelContainer: modelContainer)

        TabView {
            AskView(journalRepository: journalRepository)
                .tabItem {
                    Label("Ask", systemImage: "bubble.left.and.text.bubble.right")
                }

            JournalListView(journalRepository: journalRepository)
                .badge(journalEntries.count)
                .tabItem {
                    Label("Journal", systemImage: "book.closed")
                }
        }
    }
}

#Preview {
    // Preview-only in-memory store, so this never touches a real on-disk journal.
    let container = try! ModelContainer( // swiftlint:disable:this force_try
        for: JournalEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ContentView(modelContainer: container)
        .modelContainer(container)
}
