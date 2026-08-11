// WeeklyDigestView.swift
// Apin
//
// T12 — weekly digest/streak screen: shows the total questions-asked count and the current
// consecutive-day streak, both computed by ApinCore's `JournalDigest.compute(from:)` (a plain,
// unit-tested function — see `ApinCore/Tests/ApinCoreTests/JournalDigestTests.swift`). This view
// itself contains no streak/count logic of its own; it just loads entries via
// `JournalRepository.fetchAll()`, hands them to `JournalDigest.compute(from:)`, and renders the
// result, per `memory/coding-standards.md`'s "extract non-trivial logic out of the view" rule.
//
// Reachable from `AskView`'s toolbar (a chart-bar button that presents this as a sheet) — see
// that file's header for why that's this cycle's minimal, additive wiring rather than a root
// navigation redesign (no task currently owns composing Ask + Journal + Digest into a shared
// root nav structure; `ContentView`'s header comment already flags that as later work).
//
// See tasks/task-graph.md T12 and planning/engineering-plan.md item #12 (Req 11).

import ApinCore
import SwiftUI

struct WeeklyDigestView: View {
    let journalRepository: JournalRepository

    @State private var digest: JournalDigest?
    @State private var loadErrorMessage: String?

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Weekly Digest")
                .navigationBarTitleDisplayMode(.inline)
                .task { await load() }
        }
    }

    @ViewBuilder
    private var content: some View {
        if let loadErrorMessage {
            StatusMessageView(
                style: .error,
                systemImage: "exclamationmark.triangle",
                title: "Couldn't Load Digest",
                message: loadErrorMessage
            )
        } else if let digest {
            digestContent(digest)
        } else {
            ProgressView("Loading…")
                .progressViewStyle(.circular)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func digestContent(_ digest: JournalDigest) -> some View {
        VStack(spacing: 20) {
            statCard(
                title: "Questions Asked",
                value: "\(digest.questionCount)",
                systemImage: "bubble.left.and.text.bubble.right",
                accessibilityIdentifier: "digest.questionCountValue"
            )
            statCard(
                title: "Day Streak",
                value: "\(digest.currentStreak)",
                systemImage: "flame",
                accessibilityIdentifier: "digest.currentStreakValue"
            )
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func statCard(
        title: String,
        value: String,
        systemImage: String,
        accessibilityIdentifier: String
    ) -> some View {
        VStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 28))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)

            Text(value)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .accessibilityIdentifier(accessibilityIdentifier)

            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine)
    }

    /// Loads every entry via `JournalRepository.fetchAll()` and computes the digest. Errors are
    /// surfaced inline rather than silently showing a zeroed-out digest.
    private func load() async {
        do {
            let entries = try await journalRepository.fetchAll()
            digest = JournalDigest.compute(from: entries)
        } catch {
            loadErrorMessage = error.localizedDescription
        }
    }
}

#Preview {
    WeeklyDigestView(
        journalRepository: PreviewJournalRepository(
            entries: [
                JournalEntry(question: "What is spaced repetition?", answer: "A learning technique.", createdAt: .now),
                JournalEntry(
                    question: "What is the Foundation Models framework?",
                    answer: "Apple's on-device LLM framework.",
                    createdAt: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
                )
            ]
        )
    )
}

/// Preview-only fake `JournalRepository` that returns a fixed set of entries without touching
/// SwiftData, so `WeeklyDigestView`'s preview doesn't need an in-memory `ModelContainer`. Mirrors
/// `ApinTests/FakeJournalRepository.swift`'s shape.
@available(macOS 14, *)
@MainActor
private final class PreviewJournalRepository: JournalRepository {
    let entries: [JournalEntry]

    init(entries: [JournalEntry]) {
        self.entries = entries
    }

    func save(_ entry: JournalEntry) async throws {}
    func fetch(by id: UUID) async throws -> JournalEntry? { entries.first { $0.id == id } }
    func fetch(matching query: JournalQuery) async throws -> [JournalEntry] { entries }
    func delete(id: UUID) async throws {}
}
