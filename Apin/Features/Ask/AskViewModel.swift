// AskViewModel.swift
// Apin
//
// MVVM view model for T7's Ask screen. Composes T2's capability gate (so the view
// can choose between the normal ask flow and T3's `CapabilityUnavailableView`) and
// submits questions through the `AskAndSaveServicing` seam (T8's
// `AskAndSaveService`, which itself wraps T4's `AssistantSessionService`, or a
// fake in tests), tracking a distinct idle/loading/streaming/answered/failed state
// for the view to render.
//
// Personality instructions (T5's `PersonalitySystemInstructionBuilder`) are baked
// into the session once, at construction (see `AskViewModel.live`), so every prompt
// sent through that session automatically carries them — this view model does not
// rebuild instructions per call.
//
// T8: submitting no longer talks to the assistant session directly — it goes
// through `AskAndSaveServicing`, which streams the answer *and* saves it to the
// journal (T6) automatically once the stream completes successfully. This view
// model doesn't know or care about the save step beyond that seam.
//
// Does NOT wire a real Spotlight/widget deep link (T13/T17's job) —
// `prefilledQuery`/`prefill(with:)` are the seam those tasks hand a query in
// through.
//
// See tasks/task-graph.md T7, T8 and planning/engineering-plan.md item #7 (Req 1, 2).

import ApinCore
import Observation

/// Distinct states a single ask-flow can be in, so the view can render loading,
/// streaming, success, and error visibly differently (per T7's acceptance
/// criteria). Equatable so tests can assert on it directly.
enum AskPhase: Equatable {
    /// No request in flight, no result to show yet.
    case idle
    /// Request submitted, no partial text received yet.
    case loading
    /// Partial cumulative text received from the streaming response so far.
    case streaming(String)
    /// The full response completed successfully.
    case answered(String)
    /// The request failed; carries T4's typed error for the view to map to copy.
    case failed(AssistantResponseError)
}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@MainActor
@Observable
final class AskViewModel {
    private(set) var query: String
    private(set) var phase: AskPhase = .idle
    private(set) var capability: CapabilityGateResult

    private let capabilityGate: CapabilityGating
    private let askAndSaveService: AskAndSaveServicing

    /// - Parameters:
    ///   - capabilityGate: T2's gate (fake in tests, `CapabilityGate.live()` in
    ///     production via `AskViewModel.live`).
    ///   - askAndSaveService: T8's "stream an answer, save it to the journal on
    ///     success" seam (fake in tests, `AskAndSaveService` in production via
    ///     `AskViewModel.live`).
    ///   - prefilledQuery: The seam T13 (Spotlight deep link) and T17 (widget
    ///     quick-ask) will hand a typed query in through later.
    init(
        capabilityGate: CapabilityGating,
        askAndSaveService: AskAndSaveServicing,
        prefilledQuery: String = ""
    ) {
        self.capabilityGate = capabilityGate
        self.askAndSaveService = askAndSaveService
        self.query = prefilledQuery
        self.capability = capabilityGate.checkCapability()
    }

    /// Re-checks capability, e.g. after the user returns from Settings having
    /// turned Apple Intelligence on. Cheap and synchronous — safe to call from
    /// `.onAppear`/`.task`.
    func refreshCapability() {
        capability = capabilityGate.checkCapability()
    }

    /// Updates the query text without submitting.
    func updateQuery(_ text: String) {
        query = text
    }

    /// Replaces the query text, e.g. from a prefilled Spotlight/widget deep link
    /// handed in after this view model already exists. Distinct name from
    /// `updateQuery` to make call sites read intentionally at the T13/T17 call
    /// sites that will use it.
    func prefill(with text: String) {
        query = text
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isBusy: Bool {
        switch phase {
        case .loading, .streaming:
            return true
        case .idle, .answered, .failed:
            return false
        }
    }

    /// Whether `submit()` would actually do anything right now — drives the
    /// submit button's enabled state.
    var canSubmit: Bool {
        !trimmedQuery.isEmpty && !isBusy
    }

    /// Submits the current query, streaming partial responses into `.streaming`
    /// and settling on `.answered` or `.failed`. No-ops if the query is blank or a
    /// request is already in flight (see `canSubmit`).
    ///
    /// On success, `askAndSaveService` has already saved the Q&A pair to the
    /// journal (T8/T6) by the time this method returns — no separate save step is
    /// needed here.
    func submit() async {
        guard canSubmit else { return }
        let prompt = trimmedQuery
        phase = .loading

        do {
            var latest = ""
            for try await partial in askAndSaveService.streamAndSave(prompt: prompt) {
                latest = partial
                phase = .streaming(partial)
            }
            phase = .answered(latest)
        } catch let error as AssistantResponseError {
            phase = .failed(error)
        } catch {
            phase = .failed(AssistantResponseError(kind: .other, debugDescription: String(describing: error)))
        }
    }
}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
extension AskViewModel {
    #if canImport(FoundationModels)
    /// Production factory: T2's real capability gate (or T3's debug override, in
    /// Debug builds only — see `resolvedCapabilityGate()`) plus a real
    /// `AskAndSaveService` wrapping a session pre-loaded with T5's personality
    /// instructions and T6's `journalRepository` (typically constructed from the
    /// same `ModelContainer` the app's `.modelContainer(...)` scene modifier
    /// uses — see `ApinApp`/`ContentView`).
    static func live(prefilledQuery: String = "", journalRepository: JournalRepository) -> AskViewModel {
        AskViewModel(
            capabilityGate: resolvedCapabilityGate(),
            askAndSaveService: AskAndSaveService(
                assistantSession: AssistantSessionService(instructions: PersonalitySystemInstructionBuilder.build()),
                journalRepository: journalRepository
            ),
            prefilledQuery: prefilledQuery
        )
    }

    /// T3 — resolves which `CapabilityGating` conformance `.live` should use.
    ///
    /// In Debug builds, checks `CapabilityGateDebugOverride` first, so `/qa` and
    /// manual testers can force any of the 5 `CapabilityGateResult` cases via the
    /// `APIN_DEBUG_CAPABILITY_OVERRIDE` launch environment variable, and falls
    /// back to the real `CapabilityGate.live()` when that variable is unset.
    ///
    /// `CapabilityGateDebugOverride` itself only exists inside `#if DEBUG` (see
    /// that file's header for why), so in a Release build this `#if DEBUG` block
    /// is elided entirely at compile time — there is no override symbol left to
    /// reference — and this function unconditionally returns
    /// `CapabilityGate.live()`, exactly as it did before T3. This is what makes
    /// the override "verifiably absent/inert in Release", not merely unused:
    /// building with `-configuration Release` compiles fine with the debug type
    /// gone, so there is no way for a Release build's capability check to be
    /// influenced by this environment variable.
    private static func resolvedCapabilityGate() -> CapabilityGating {
        #if DEBUG
        if let override = CapabilityGateDebugOverride.gate() {
            return override
        }
        #endif
        return CapabilityGate.live()
    }
    #endif
}
