// AssistantResponseError.swift
// ApinCore
//
// App-level typed error surface for `AssistantSessionService` (T4). Callers (T7's
// Ask screen, T13's App Intent, a future widget entry point, etc.) branch on
// `Kind` instead of matching FoundationModels' own error types directly, so this
// module stays the single place that understands the framework's error shape.
//
// See tasks/task-graph.md T4.

import Foundation

/// A typed error produced by `AssistantSessionService` after mapping a
/// FoundationModels (or internal) failure into an app-level shape.
public struct AssistantResponseError: Error, Equatable, Sendable {
    /// Coarse-grained category a caller can branch UI/retry behavior on.
    public enum Kind: Sendable, Equatable {
        /// The request did not complete within the configured timeout.
        /// FoundationModels has no native timeout error, so this service enforces
        /// one itself (see `withTimeout` in `AsyncTimeout.swift`).
        case timeout

        /// The request (or its enclosing `Task`) was cancelled.
        case cancelled

        /// The on-device model/assets weren't available to service this request
        /// (`GenerationError.assetsUnavailable`). Distinct from T2's capability
        /// gate, which covers device/OS/Apple-Intelligence-toggle eligibility
        /// *before* a session is even created.
        case modelUnavailable

        /// The model declined to answer — a guardrail violation or an explicit
        /// refusal (`GenerationError.guardrailViolation` / `.refusal`).
        case refusal

        /// The prompt plus transcript exceeded the model's context window.
        case contextWindowExceeded

        /// The requested language/locale isn't supported by the model.
        case unsupportedLanguage

        /// The model's raw output couldn't be decoded into the expected shape.
        case decodingFailure

        /// Too many concurrent requests were made against the same session.
        case concurrentRequests

        /// The request was rate-limited.
        case rateLimited

        /// Any other framework/session error not covered above.
        case other
    }

    public let kind: Kind

    /// Debug detail for logging, deliberately not guaranteed to be
    /// user-presentable copy — UI layers (T7) should map `kind` to their own copy
    /// rather than surface this string directly.
    public let debugDescription: String

    public init(kind: Kind, debugDescription: String) {
        self.kind = kind
        self.debugDescription = debugDescription
    }
}

extension AssistantResponseError: LocalizedError {
    public var errorDescription: String? { debugDescription }
}
