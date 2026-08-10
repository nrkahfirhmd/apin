// OSVersionProviding.swift
// ApinCore
//
// See tasks/task-graph.md T2.

/// Something that reports whether the current OS meets Apin's minimum supported
/// version. Abstracted so ``CapabilityGate`` can be unit-tested for the
/// `unsupportedOS` branch without depending on the OS actually running an
/// unsupported version.
public protocol OSVersionProviding: Sendable {
    /// `true` if the current OS version meets Apin's minimum supported version.
    var isRunningSupportedOSVersion: Bool { get }
}

/// The production ``OSVersionProviding`` implementation.
///
/// Apin's minimum supported OS is iOS 26 (the release that introduced the
/// `FoundationModels` framework's on-device model access) — this is the only place
/// that version number appears; every other capability check is delegated to
/// `SystemLanguageModel.availability` via ``ModelHardwareAvailabilityProviding``,
/// which is Apple's own runtime source of truth for hardware/toggle eligibility.
public struct DefaultOSVersionProvider: OSVersionProviding {
    public init() {}

    public var isRunningSupportedOSVersion: Bool {
        if #available(iOS 26.0, macOS 26.0, *) {
            return true
        } else {
            return false
        }
    }
}
