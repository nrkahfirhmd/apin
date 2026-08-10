// AssistantSessionService.swift
// ApinCore
//
// FoundationModels session wrapper (T4): creates/holds a `LanguageModelSession`
// (via `FoundationModelsSessionAdapter`), accepts a plain system-instructions
// `String` (deliberately not T5's concrete builder type, so this task doesn't
// block on T5's exact shape — any caller that can produce a `String` works),
// sends a prompt, awaits or streams the response, and maps FoundationModels
// errors (timeout, unavailable, refusal, etc.) to `AssistantResponseError`.
//
// Does NOT build the personality content itself (T5) and does NOT build any UI
// (T7) — this is purely the "talk to the model" seam. See tasks/task-graph.md T4.

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

/// Talks to a FoundationModels session (or a fake, in tests) behind a small,
/// injectable surface. Exposes both an awaited full-response path and a
/// streaming path so a future loading/streaming UI (T7) has something to
/// consume either way.
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
public final class AssistantSessionService: Sendable {
    /// Default request timeout. FoundationModels has no native timeout error, so
    /// this service enforces its own (see `AsyncTimeout.swift`) and maps a
    /// timed-out request to `AssistantResponseError.Kind.timeout`.
    public static let defaultTimeout: TimeInterval = 30

    private let session: LanguageModelSessionProviding
    private let timeout: TimeInterval

    /// Primary initializer, written entirely against the `LanguageModelSessionProviding`
    /// seam. Inject a fake here in tests; production callers typically use the
    /// `instructions:` convenience initializer below instead.
    public init(
        session: LanguageModelSessionProviding,
        timeout: TimeInterval = AssistantSessionService.defaultTimeout
    ) {
        self.session = session
        self.timeout = timeout
    }

    #if canImport(FoundationModels)
    /// Convenience initializer that creates a real, on-device
    /// `LanguageModelSession` primed with `instructions`.
    /// - Parameter instructions: A system-instruction string, e.g. the output of
    ///   T5's personality builder. This type only needs a `String`.
    public convenience init(instructions: String, timeout: TimeInterval = AssistantSessionService.defaultTimeout) {
        self.init(session: FoundationModelsSessionAdapter(instructions: instructions), timeout: timeout)
    }
    #endif

    /// Sends `prompt` and awaits the full response, bounded by `timeout`.
    /// Suitable for a simple "loading -> answer" UI.
    public func send(prompt: String) async -> Result<String, AssistantResponseError> {
        do {
            let text = try await withTimeout(seconds: timeout) { [session] in
                try await session.respond(to: prompt)
            }
            return .success(text)
        } catch {
            return .failure(Self.mapError(error))
        }
    }

    /// Sends `prompt` and returns a stream of cumulative partial responses (each
    /// element is the full text generated so far, per FoundationModels' snapshot
    /// semantics), for a future streaming UI (T7) to consume. Errors surfaced
    /// through the stream are already mapped to `AssistantResponseError`.
    ///
    /// Note: unlike `send(prompt:)`, this path is not currently timeout-bounded
    /// by this service — a streaming UI is expected to show incremental
    /// progress, so a hang is visible to the caller rather than silent. Revisit
    /// if T7 needs a stall timeout too.
    public func streamResponse(prompt: String) -> AsyncThrowingStream<String, Error> {
        let upstream = session.streamResponse(to: prompt)
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await partial in upstream {
                        continuation.yield(partial)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: Self.mapError(error))
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    // MARK: - Error mapping

    static func mapError(_ error: Error) -> AssistantResponseError {
        if let alreadyMapped = error as? AssistantResponseError {
            return alreadyMapped
        }
        if error is AsyncOperationTimedOutError {
            return AssistantResponseError(kind: .timeout, debugDescription: "Request timed out after \(Self.self).")
        }
        if error is CancellationError {
            return AssistantResponseError(kind: .cancelled, debugDescription: "Request was cancelled.")
        }
        #if canImport(FoundationModels)
        if let generationError = error as? LanguageModelSession.GenerationError {
            return mapGenerationError(generationError)
        }
        #endif
        return AssistantResponseError(kind: .other, debugDescription: String(describing: error))
    }

    #if canImport(FoundationModels)
    static func mapGenerationError(_ error: LanguageModelSession.GenerationError) -> AssistantResponseError {
        switch error {
        case .exceededContextWindowSize(let context):
            return AssistantResponseError(kind: .contextWindowExceeded, debugDescription: context.debugDescription)
        case .assetsUnavailable(let context):
            return AssistantResponseError(kind: .modelUnavailable, debugDescription: context.debugDescription)
        case .guardrailViolation(let context):
            return AssistantResponseError(kind: .refusal, debugDescription: context.debugDescription)
        case .unsupportedGuide(let context):
            return AssistantResponseError(kind: .other, debugDescription: context.debugDescription)
        case .unsupportedLanguageOrLocale(let context):
            return AssistantResponseError(kind: .unsupportedLanguage, debugDescription: context.debugDescription)
        case .decodingFailure(let context):
            return AssistantResponseError(kind: .decodingFailure, debugDescription: context.debugDescription)
        case .rateLimited(let context):
            return AssistantResponseError(kind: .rateLimited, debugDescription: context.debugDescription)
        case .concurrentRequests(let context):
            return AssistantResponseError(kind: .concurrentRequests, debugDescription: context.debugDescription)
        case .refusal(_, let context):
            return AssistantResponseError(kind: .refusal, debugDescription: context.debugDescription)
        @unknown default:
            return AssistantResponseError(kind: .other, debugDescription: "Unknown FoundationModels generation error.")
        }
    }
    #endif
}
