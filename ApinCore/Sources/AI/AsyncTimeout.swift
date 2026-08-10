// AsyncTimeout.swift
// ApinCore
//
// Small async-timeout utility used by `AssistantSessionService` (T4) because
// FoundationModels doesn't expose a native timeout error — a hung/slow session
// call would otherwise wait indefinitely.
//
// See tasks/task-graph.md T4.

import Foundation

/// Thrown internally when `withTimeout`'s timer wins the race against the
/// operation. Callers of `AssistantSessionService` should not need to match on
/// this directly — it's mapped into `AssistantResponseError.Kind.timeout` before
/// it reaches them.
struct AsyncOperationTimedOutError: Error {}

/// Races `operation` against a `seconds`-long timer, throwing
/// `AsyncOperationTimedOutError` if the timer wins first. Cancels whichever task
/// loses the race.
///
/// Gated at iOS/macOS 26 to match its only caller, `AssistantSessionService`
/// (see the note on `LanguageModelSessionProviding` for why the whole module
/// shares one availability floor rather than mixing 10.15/13.0 and 26.0).
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
func withTimeout<T: Sendable>(
    seconds: TimeInterval,
    operation: @escaping @Sendable () async throws -> T
) async throws -> T {
    try await withThrowingTaskGroup(of: T.self) { group in
        defer { group.cancelAll() }

        group.addTask {
            try await operation()
        }
        group.addTask {
            let nanoseconds = UInt64(max(seconds, 0) * 1_000_000_000)
            try await Task.sleep(nanoseconds: nanoseconds)
            throw AsyncOperationTimedOutError()
        }

        guard let result = try await group.next() else {
            throw AsyncOperationTimedOutError()
        }
        return result
    }
}
