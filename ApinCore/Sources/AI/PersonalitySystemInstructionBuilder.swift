// PersonalitySystemInstructionBuilder.swift
// ApinCore
//
// Composes a `PersonalityBrief` into a single system-instruction string. The output is a
// plain `String` so callers (e.g. T4's FoundationModels session wrapper) can accept it
// without depending on this type directly. Does not call any model and does not build UI
// — see tasks/task-graph.md T5.

/// Builds Apin's system-instruction string from a `PersonalityBrief`.
///
/// Kept as a pure, stateless composition step: swap in a different `PersonalityBrief` to
/// change the assistant's voice/guardrails without editing this builder.
public enum PersonalitySystemInstructionBuilder {
    /// Composes `brief` into a single system-instruction string.
    ///
    /// - Parameter brief: The personality data to compose. Defaults to
    ///   `PersonalityBrief.placeholder`.
    /// - Returns: A single string suitable for use as a `LanguageModelSession`'s system
    ///   instructions.
    public static func build(from brief: PersonalityBrief = .placeholder) -> String {
        var sections: [String] = []

        sections.append(introduction(for: brief))

        if !brief.styleGuidelines.isEmpty {
            sections.append(bulletedSection(title: "Style guidelines", items: brief.styleGuidelines))
        }

        if !brief.guardrails.isEmpty {
            sections.append(bulletedSection(title: "Guardrails", items: brief.guardrails))
        }

        sections.append("Language handling: \(brief.languagePolicy)")

        return sections.joined(separator: "\n\n")
    }

    private static func introduction(for brief: PersonalityBrief) -> String {
        let tone = brief.toneDescriptors.joined(separator: ", ")
        if tone.isEmpty {
            return "You are \(brief.name)."
        }
        return "You are \(brief.name), a \(tone)."
    }

    private static func bulletedSection(title: String, items: [String]) -> String {
        let bullets = items.map { "- \($0)" }.joined(separator: "\n")
        return "\(title):\n\(bullets)"
    }
}
