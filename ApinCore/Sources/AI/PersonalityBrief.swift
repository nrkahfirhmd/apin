// PersonalityBrief.swift
// ApinCore
//
// Swappable data describing Apin's voice, tone, style, and guardrails. Kept as plain
// data (not string literals baked into a builder function) so revising the brief later
// is a content change, not a code change. See tasks/task-graph.md T5.
//
// `PersonalityBrief.placeholder` below carries forward the placeholder brief verbatim
// from the engineering plan's open question #2 (personality brief pending Kv's real
// version) and open question #5 (mirror-question-language assumption, English/Indonesian,
// pending runtime verification of on-device Indonesian support). Neither open question is
// resolved by this task — only wired in as swappable content.

/// Isolated, swappable description of Apin's personality, tone, style, guardrails, and
/// language-handling policy. Construct a new value (or replace `.placeholder`) to change
/// the assistant's voice without touching `PersonalitySystemInstructionBuilder`.
public struct PersonalityBrief: Sendable, Equatable {
    /// The assistant's name, as it should appear in the system instructions.
    public var name: String

    /// Short phrases describing the overall tone/voice (e.g. "warm", "curious").
    public var toneDescriptors: [String]

    /// Concrete style guidance (conciseness, plain language, enthusiasm level, etc.).
    public var styleGuidelines: [String]

    /// Behavioral guardrails the assistant must follow (e.g. admitting uncertainty).
    public var guardrails: [String]

    /// Instruction describing how the assistant should choose its response language.
    public var languagePolicy: String

    public init(
        name: String,
        toneDescriptors: [String],
        styleGuidelines: [String],
        guardrails: [String],
        languagePolicy: String
    ) {
        self.name = name
        self.toneDescriptors = toneDescriptors
        self.styleGuidelines = styleGuidelines
        self.guardrails = guardrails
        self.languagePolicy = languagePolicy
    }
}

extension PersonalityBrief {
    /// Placeholder brief carried forward verbatim per task-graph.md T5's notes, pending
    /// Kv's confirmed personality brief. Treat this as content to be swapped out later,
    /// not as a spec to be hardened in code.
    public static let placeholder = PersonalityBrief(
        name: "Apin",
        toneDescriptors: [
            "warm",
            "curious",
            "encouraging study-buddy voice"
        ],
        styleGuidelines: [
            "Give concise, plain-language explanations.",
            "Show occasional light enthusiasm.",
            "Never sound condescending."
        ],
        guardrails: [
            "Admit uncertainty rather than fabricating an answer."
        ],
        languagePolicy: "Mirror the language of the question (English or Indonesian); "
            + "default to English when the question's language is ambiguous."
    )
}
