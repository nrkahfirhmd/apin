// AskViewModelTests.swift
// ApinTests
//
// Unit tests for T7's `AskViewModel`. Exercises state transitions (idle -> loading
// -> streaming -> answered/failed) and capability-gate branching against
// `FakeCapabilityGate` / `FakeAssistantSession`, so this is testable without a live
// device or on-device model. AI response *content* is deliberately not tested here
// (non-deterministic) — only fixed strings and constructed errors, matching
// ApinCoreTests' `AssistantSessionServiceTests` testing strategy.
//
// This is the first test target for the `Apin` app target (previously only
// `ApinCoreTests` existed, per T3's flagged debt) — added as part of T7 per the
// task's own acceptance criteria, since app-level view model testing recurs in T8,
// T9's search, etc. and someone had to add it first. See tasks/task-graph.md T7.

import ApinCore
import XCTest
@testable import Apin

private struct SomeOtherError: Error {}

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@MainActor
final class AskViewModelTests: XCTestCase {
    // MARK: - Capability gating

    func testCapabilityReflectsGateResultAtInit() {
        let viewModel = AskViewModel(
            capabilityGate: FakeCapabilityGate(result: .appleIntelligenceDisabled),
            askAndSaveService: FakeAssistantSession()
        )

        XCTAssertEqual(viewModel.capability, .appleIntelligenceDisabled)
    }

    func testRefreshCapabilityPicksUpLatestGateResult() {
        let fake = FakeCapabilityGate(result: .modelNotReady)
        let viewModel = AskViewModel(capabilityGate: fake, askAndSaveService: FakeAssistantSession())
        XCTAssertEqual(viewModel.capability, .modelNotReady)

        fake.result = .available
        viewModel.refreshCapability()

        XCTAssertEqual(viewModel.capability, .available)
    }

    // MARK: - Prefilled query

    func testPrefilledQuerySeedsInitialQuery() {
        let viewModel = AskViewModel(
            capabilityGate: FakeCapabilityGate(result: .available),
            askAndSaveService: FakeAssistantSession(),
            prefilledQuery: "What is photosynthesis?"
        )

        XCTAssertEqual(viewModel.query, "What is photosynthesis?")
    }

    func testPrefillWithUpdatesQueryAfterConstruction() {
        let viewModel = makeViewModel()

        viewModel.prefill(with: "How do plants make food?")

        XCTAssertEqual(viewModel.query, "How do plants make food?")
    }

    // MARK: - canSubmit

    func testCanSubmitIsFalseForBlankQuery() {
        let viewModel = makeViewModel(query: "   ")
        XCTAssertFalse(viewModel.canSubmit)
    }

    func testCanSubmitIsTrueForNonBlankQueryWhenIdle() {
        let viewModel = makeViewModel(query: "hello")
        XCTAssertTrue(viewModel.canSubmit)
    }

    // MARK: - Success path

    func testSubmitTransitionsThroughLoadingStreamingToAnswered() async {
        let fake = FakeAssistantSession()
        fake.streamValues = ["Hel", "Hello", "Hello there"]
        let viewModel = makeViewModel(query: "hi", session: fake)

        XCTAssertEqual(viewModel.phase, .idle)

        await viewModel.submit()

        XCTAssertEqual(viewModel.phase, .answered("Hello there"))
        XCTAssertEqual(fake.receivedPrompts, ["hi"])
    }

    func testSubmitTrimsQueryBeforeSending() async {
        let fake = FakeAssistantSession()
        fake.streamValues = ["ok"]
        let viewModel = makeViewModel(query: "  hi  ", session: fake)

        await viewModel.submit()

        XCTAssertEqual(fake.receivedPrompts, ["hi"])
    }

    // MARK: - No-ops

    func testSubmitNoOpsForBlankQuery() async {
        let fake = FakeAssistantSession()
        let viewModel = makeViewModel(query: "   ", session: fake)

        await viewModel.submit()

        XCTAssertEqual(viewModel.phase, .idle)
        XCTAssertTrue(fake.receivedPrompts.isEmpty)
    }

    // MARK: - Error path

    func testSubmitMapsStreamFailureToFailedPhase() async {
        let fake = FakeAssistantSession()
        fake.streamValues = ["partial"]
        fake.streamFailure = AssistantResponseError(kind: .refusal, debugDescription: "declined")
        let viewModel = makeViewModel(query: "hi", session: fake)

        await viewModel.submit()

        guard case .failed(let error) = viewModel.phase else {
            return XCTFail("Expected .failed, got \(viewModel.phase)")
        }
        XCTAssertEqual(error.kind, .refusal)
    }

    // MARK: - Helpers

    private func makeViewModel(
        query: String = "",
        capability: CapabilityGateResult = .available,
        session: FakeAssistantSession = FakeAssistantSession()
    ) -> AskViewModel {
        AskViewModel(
            capabilityGate: FakeCapabilityGate(result: capability),
            askAndSaveService: session,
            prefilledQuery: query
        )
    }
}
