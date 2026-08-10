// CapabilityGateResult.swift
// ApinCore
//
// Typed result for Apin's capability gate (T2) — the single source of truth every
// entry point (Ask screen, widget, App Intent) branches on to decide whether
// on-device Foundation Models inference can run right now. See tasks/task-graph.md
// T2 and planning/engineering-plan.md item #2 (Req 7).

/// The outcome of checking whether Apin can use on-device Foundation Models
/// inference on the current device, right now.
///
/// Callers should treat this as the *only* place capability is derived — do not
/// re-derive availability with ad hoc `if #available` or hardware checks at call
/// sites. The Ask screen, widget, and App Intent entry points all branch on this
/// one type via ``CapabilityGating``.
public enum CapabilityGateResult: Equatable, Sendable {
    /// On-device inference is ready to use right now.
    case available

    /// The current OS version does not meet Apin's minimum supported version.
    case unsupportedOS

    /// The current device's hardware is not eligible for Apple Intelligence /
    /// Foundation Models, independent of OS version or the Apple Intelligence
    /// toggle. Not user-fixable (no settings change resolves this).
    case unsupportedDevice

    /// The device and OS are eligible, but the user has not turned on Apple
    /// Intelligence in Settings. Unlike the other non-`available` cases, this one
    /// is user-fixable without a new device or OS update.
    case appleIntelligenceDisabled

    /// The device and OS are eligible and Apple Intelligence is on, but the model
    /// assets are not finished downloading/preparing yet. Distinct from the other
    /// unavailable cases because it is expected to resolve on its own without user
    /// action, typically by retrying later.
    case modelNotReady
}
