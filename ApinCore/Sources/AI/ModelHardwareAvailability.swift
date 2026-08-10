// ModelHardwareAvailability.swift
// ApinCore
//
// See tasks/task-graph.md T2.

/// A minimal, `FoundationModels`-independent mirror of
/// `FoundationModels.SystemLanguageModel.Availability` (and its
/// `UnavailableReason`), so ``CapabilityGate`` and its tests don't need to import
/// `FoundationModels` or run on Apple Intelligence–eligible hardware to exercise
/// gate logic.
///
/// ``DefaultModelHardwareAvailabilityProvider`` is the only place that translates
/// the real framework type into this one.
public enum ModelHardwareAvailability: Equatable, Sendable {
    /// `SystemLanguageModel.Availability.available`.
    case available

    /// `SystemLanguageModel.Availability.unavailable(.deviceNotEligible)`.
    case deviceNotEligible

    /// `SystemLanguageModel.Availability.unavailable(.appleIntelligenceNotEnabled)`.
    case appleIntelligenceNotEnabled

    /// `SystemLanguageModel.Availability.unavailable(.modelNotReady)`.
    case modelNotReady
}
