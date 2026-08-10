// AskView.swift
// Apin
//
// T7 — the Ask screen: input field, submit control, and visibly distinct
// loading/streaming/answered/error states, backed by `AskViewModel`. Composes T2's
// capability gate to choose between this normal ask flow and T3's
// `CapabilityUnavailableView`.
//
// Answers are auto-saved to the journal via T8's `AskAndSaveService`, wired in
// through `AskViewModel.live`. Does NOT wire a real Spotlight/widget deep link
// (T13/T17) — `prefilledQuery` is the seam those tasks hand a query in through
// later.
//
// T13: this view now observes `AskDeepLinkCoordinator.shared` (an `@Observable`
// singleton `AskApinIntent.perform()` writes to — see that type's header) and, on
// seeing a pending query, prefills it via `AskViewModel.prefill(with:)` *and*
// immediately calls `submit()` (only when capability is `.available` — `submit()`
// is unreachable from this view's own UI otherwise, since `askContent` isn't shown).
// Chosen over "prefill only, wait for a manual tap" because a Spotlight/Siri query
// already represents the user's full typed question — requiring one more manual
// tap after the app opens would be a worse "committed baseline" UX for Req 5 than
// this task's acceptance criteria call for ("running it produces an auto-saved
// journal entry ... no duplicated save logic"), while still going through the exact
// same `AskViewModel.submit()` -> `AskAndSaveServicing` path a manual tap would.
//
// T19: the `.idle` and `.failed` cases of `answerSection` now render through the shared
// `StatusMessageView` (Apin/Common) instead of `EmptyView()`/an inline `Label`, so the empty
// and error states look/feel consistent with Journal's empty state. `.loading`/`.streaming`/
// `.answered` are unchanged — they were already visibly distinct per T7's acceptance criteria.
//
// See tasks/task-graph.md T7, T8, T13, T19 and planning/engineering-plan.md item #7 (Req 1, 2)
// and item #18 (Req 1, 4, 7).

import ApinCore
import SwiftData
import SwiftUI

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
struct AskView: View {
    @State private var viewModel: AskViewModel

    #if canImport(FoundationModels)
    /// Production entry point. `prefilledQuery` is the seam T13's Spotlight/Siri
    /// deep link and T17's widget quick-ask will hand a typed query in through.
    /// `journalRepository` (T6) is where T8's auto-save writes every successful
    /// answer.
    init(prefilledQuery: String = "", journalRepository: JournalRepository) {
        _viewModel = State(wrappedValue: .live(prefilledQuery: prefilledQuery, journalRepository: journalRepository))
    }
    #endif

    /// Test/preview entry point — injects an already-constructed view model (e.g.
    /// one wired to a fake capability gate/session).
    init(viewModel: AskViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.capability == .available {
                askContent
            } else {
                CapabilityUnavailableView(result: viewModel.capability)
            }
        }
        .onAppear {
            viewModel.refreshCapability()
            applyPendingDeepLinkQueryIfNeeded()
        }
        .onChange(of: AskDeepLinkCoordinator.shared.pendingQuery) {
            applyPendingDeepLinkQueryIfNeeded()
        }
    }

    /// Consumes `AskDeepLinkCoordinator.shared`'s pending query (if any — a no-op
    /// otherwise), prefills it, and auto-submits when the capability gate allows it.
    /// See the file header for why this auto-submits rather than waiting for a
    /// manual tap. Safe to call redundantly (`.onAppear` and `.onChange` both call
    /// this) — `consumePendingQuery()` returns `nil` on the second call.
    private func applyPendingDeepLinkQueryIfNeeded() {
        guard let pendingQuery = AskDeepLinkCoordinator.shared.consumePendingQuery() else { return }
        viewModel.prefill(with: pendingQuery)
        guard viewModel.capability == .available else { return }
        Task { await viewModel.submit() }
    }

    private var askContent: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                TextField(
                    "Ask Apin something…",
                    text: Binding(get: { viewModel.query }, set: { viewModel.updateQuery($0) }),
                    axis: .vertical
                )
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .accessibilityLabel("Question")

                Button("Ask") {
                    Task { await viewModel.submit() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canSubmit)

                answerSection

                Spacer()
            }
            .padding()
            .navigationTitle("Ask")
        }
    }

    @ViewBuilder
    private var answerSection: some View {
        switch viewModel.phase {
        case .idle:
            StatusMessageView(
                style: .empty,
                systemImage: "bubble.left.and.text.bubble.right",
                title: "Ask Apin Something",
                message: "Type a question above to get a personalized, on-device answer."
            )

        case .loading:
            ProgressView("Thinking…")
                .progressViewStyle(.circular)

        case .streaming(let partial):
            VStack(alignment: .leading, spacing: 8) {
                ProgressView()
                ScrollView {
                    Text(partial)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

        case .answered(let text):
            ScrollView {
                Text(text)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

        case .failed(let error):
            StatusMessageView(
                style: .error,
                systemImage: "exclamationmark.triangle",
                title: "Couldn't Get an Answer",
                message: error.errorDescription ?? "Something went wrong. Try again."
            )
            .accessibilityElement(children: .combine)
        }
    }
}

#if canImport(FoundationModels)
#Preview {
    // Preview-only in-memory store, so this never touches a real on-disk journal.
    let container = try! ModelContainer( // swiftlint:disable:this force_try
        for: JournalEntry.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    AskView(journalRepository: SwiftDataJournalRepository(modelContainer: container))
}
#endif
