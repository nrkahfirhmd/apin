// AskDeepLinkCoordinatorTests.swift
// ApinCoreTests
//
// Unit tests for T13's `AskDeepLinkCoordinator` — the mailbox `AskApinIntent`
// hands a deep-linked query to, and `AskView` consumes from. Each test constructs
// its own instance (`AskDeepLinkCoordinator()`, not `.shared`) so tests stay
// isolated from one another rather than sharing process-wide singleton state. See
// tasks/task-graph.md T13.

import XCTest
@testable import ApinCore

@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@MainActor
final class AskDeepLinkCoordinatorTests: XCTestCase {
    func testPendingQueryStartsNil() {
        let coordinator = AskDeepLinkCoordinator()
        XCTAssertNil(coordinator.pendingQuery)
    }

    func testRequestAskSetsPendingQuery() {
        let coordinator = AskDeepLinkCoordinator()

        coordinator.requestAsk(query: "What is photosynthesis?")

        XCTAssertEqual(coordinator.pendingQuery, "What is photosynthesis?")
    }

    func testConsumePendingQueryReturnsAndClearsTheValue() {
        let coordinator = AskDeepLinkCoordinator()
        coordinator.requestAsk(query: "How do plants make food?")

        let consumed = coordinator.consumePendingQuery()

        XCTAssertEqual(consumed, "How do plants make food?")
        XCTAssertNil(coordinator.pendingQuery)
    }

    func testConsumePendingQueryReturnsNilWhenNothingIsPending() {
        let coordinator = AskDeepLinkCoordinator()
        XCTAssertNil(coordinator.consumePendingQuery())
    }

    func testConsumingTwiceInARowOnlyReturnsTheValueOnce() {
        let coordinator = AskDeepLinkCoordinator()
        coordinator.requestAsk(query: "Why is the sky blue?")

        XCTAssertEqual(coordinator.consumePendingQuery(), "Why is the sky blue?")
        XCTAssertNil(coordinator.consumePendingQuery())
    }

    func testRequestAskOverwritesAPreviousUnconsumedQuery() {
        let coordinator = AskDeepLinkCoordinator()
        coordinator.requestAsk(query: "First question")

        coordinator.requestAsk(query: "Second question")

        XCTAssertEqual(coordinator.consumePendingQuery(), "Second question")
    }
}
