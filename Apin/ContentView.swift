// ContentView.swift
// Apin
//
// Root view. T7 wires in the Ask screen here as a minimal, additive change (the
// smallest edit that makes AskView actually reachable in the running app) — this is
// NOT a final root-navigation composition combining Ask + Journal (no such task
// currently owns that; a future task should feel free to replace this with a
// TabView or similar once Journal navigation needs a home here too).
//
// T8 hands `AskView` a `SwiftDataJournalRepository` built from `ApinApp`'s shared
// `ModelContainer`, so T8's auto-save flow has a real repository to write to.

import ApinCore
import SwiftData
import SwiftUI

struct ContentView: View {
    let modelContainer: ModelContainer

    var body: some View {
        AskView(journalRepository: SwiftDataJournalRepository(modelContainer: modelContainer))
    }
}

#Preview {
    // Preview-only in-memory store, so this never touches a real on-disk journal.
    let container = try! ModelContainer( // swiftlint:disable:this force_try
        for: JournalEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    return ContentView(modelContainer: container)
}
