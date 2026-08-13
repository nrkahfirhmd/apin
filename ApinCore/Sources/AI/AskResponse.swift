// AskResponse.swift
// ApinCore
//
// `@Generable` shape produced by `AssistantSessionService.sendStructured(prompt:)`
// (Cycle 5's T2): a structured counterpart to the existing plain-`String`
// `send(prompt:)`/`streamResponse(prompt:)`. Carries a direct answer plus
// lightweight metadata (a natural follow-up question, suggested reply chips,
// freeform topic tags) for a future UI (follow-up chips, message history —
// deferred to a later cycle, see tasks/task-graph.md T2/T4) to consume.
//
// `@Generable`/`@Guide` macro syntax verified against this machine's real,
// installed Xcode 26.6 `FoundationModels.framework` (not guessed): confirmed by
// (1) Apple's bundled "Using Apple's On-Device LLM in Your Apps" doc at
// `Xcode.app/Contents/PlugIns/IDEIntelligenceChat.framework/.../
// FoundationModels-Using-on-device-LLM-in-your-app.md`, and (2) a scratch SPM
// package compiled directly against `FoundationModels.swiftinterface`
// (`.../MacOSX.sdk/.../FoundationModels.framework/.../arm64e-apple-macos.swiftinterface`),
// which also confirms `@Generable`'s macro expansion does not synthesize a public
// memberwise initializer for a `public` type — hence the explicit `public init`
// below.
//
// See tasks/task-graph.md T2 (Cycle 5).

import Foundation

#if canImport(FoundationModels)
import FoundationModels

/// A structured assistant response: a direct answer plus a natural follow-up
/// question and lightweight metadata for a future UI to consume.
///
/// Per-field `@Guide` descriptions are written to read naturally alongside
/// `PersonalitySystemInstructionBuilder`'s system instructions (Apin's tone,
/// style, guardrails) as additional guidance for *this* structured call, not a
/// replacement for them.
@available(iOS 26.0, macOS 26.0, visionOS 26.0, *)
@Generable(description: "Apin's structured response to a user's question, in Apin's own playful, witty voice.")
public struct AskResponse: Sendable, Equatable {
    /// A direct, complete answer to the user's question, in Apin's voice.
    @Guide(description: "A direct, complete answer to the user's question, written in Apin's own voice.")
    public var answer: String

    /// A short, natural follow-up question to keep the conversation going.
    @Guide(description: "A short, natural follow-up question inviting the user to continue the conversation.")
    public var followUpQuestion: String

    /// Suggested short reply chips the user could tap next.
    @Guide(
        description: "2 to 4 short suggested reply chips (a few words each) the user could tap next.",
        .count(2...4)
    )
    public var chips: [String]

    /// Short freeform topic tags describing this exchange.
    @Guide(
        description: "1 to 5 short, lowercase, freeform topic tags describing this exchange.",
        .count(1...5)
    )
    public var tags: [String]

    public init(answer: String, followUpQuestion: String, chips: [String], tags: [String]) {
        self.answer = answer
        self.followUpQuestion = followUpQuestion
        self.chips = chips
        self.tags = tags
    }
}
#endif
