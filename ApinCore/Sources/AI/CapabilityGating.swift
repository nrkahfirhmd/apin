// CapabilityGating.swift
// ApinCore
//
// See tasks/task-graph.md T2.

/// Something that can determine whether Apin's on-device Foundation Models
/// capability is available right now.
///
/// This is the seam every entry point (Ask screen, widget, App Intent) should
/// depend on instead of a concrete type, so T3/T7 and friends can inject a fake in
/// their own tests. ``CapabilityGate`` is the production implementation.
public protocol CapabilityGating: Sendable {
    /// Checks OS version, hardware/Apple Intelligence eligibility, and model
    /// readiness and returns one typed result describing the current state.
    func checkCapability() -> CapabilityGateResult
}
