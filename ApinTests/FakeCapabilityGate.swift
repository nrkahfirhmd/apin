// FakeCapabilityGate.swift
// ApinTests
//
// Fake `CapabilityGating` conformance (T2's protocol) used by `AskViewModelTests`
// (T7) so capability-gate branching can be unit-tested without a live device.
//
// See tasks/task-graph.md T7.

import ApinCore

final class FakeCapabilityGate: CapabilityGating, @unchecked Sendable {
    var result: CapabilityGateResult

    init(result: CapabilityGateResult) {
        self.result = result
    }

    func checkCapability() -> CapabilityGateResult {
        result
    }
}
