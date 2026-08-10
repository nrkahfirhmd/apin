// PersonalitySystemInstructionBuilderTests.swift
// ApinCoreTests
//
// Structural tests for T5 (personality system-instruction builder): verifies the name
// and guardrail content are present in the composed output, and that the brief is
// data-driven/swappable (a different `PersonalityBrief` produces different output).
// Deliberately does not assert on exact prose/wording, per the task's acceptance
// criteria.

import XCTest
@testable import ApinCore

final class PersonalitySystemInstructionBuilderTests: XCTestCase {
    func testDefaultOutputIncludesTheNameApin() {
        let instructions = PersonalitySystemInstructionBuilder.build()

        XCTAssertTrue(
            instructions.contains("Apin"),
            "System instructions should mention the assistant's name."
        )
    }

    func testDefaultOutputIncludesEachGuardrail() {
        let instructions = PersonalitySystemInstructionBuilder.build()

        for guardrail in PersonalityBrief.placeholder.guardrails {
            XCTAssertTrue(
                instructions.contains(guardrail),
                "System instructions should include guardrail: \(guardrail)"
            )
        }
    }

    func testDefaultOutputIncludesEachStyleGuideline() {
        let instructions = PersonalitySystemInstructionBuilder.build()

        for guideline in PersonalityBrief.placeholder.styleGuidelines {
            XCTAssertTrue(
                instructions.contains(guideline),
                "System instructions should include style guideline: \(guideline)"
            )
        }
    }

    func testDefaultOutputIncludesLanguageHandlingInstruction() {
        let instructions = PersonalitySystemInstructionBuilder.build()

        XCTAssertTrue(
            instructions.contains(PersonalityBrief.placeholder.languagePolicy),
            "System instructions should wire in the mirror-question-language policy."
        )
    }

    func testBriefIsDataDrivenAndSwappable() {
        let customBrief = PersonalityBrief(
            name: "TestBot",
            toneDescriptors: ["stern", "formal"],
            styleGuidelines: ["Use precise technical vocabulary."],
            guardrails: ["Refuse to speculate about unverifiable facts."],
            languagePolicy: "Always respond in English only."
        )

        let instructions = PersonalitySystemInstructionBuilder.build(from: customBrief)

        XCTAssertTrue(instructions.contains("TestBot"))
        XCTAssertTrue(instructions.contains("Refuse to speculate about unverifiable facts."))
        XCTAssertTrue(instructions.contains("Always respond in English only."))
        XCTAssertFalse(
            instructions.contains("Apin"),
            "Swapping the brief should not leave the previous brief's content behind."
        )
    }

    func testEmptyGuardrailsProduceNoGuardrailsSection() {
        let briefWithoutGuardrails = PersonalityBrief(
            name: "Apin",
            toneDescriptors: ["friendly"],
            styleGuidelines: ["Be brief."],
            guardrails: [],
            languagePolicy: "Respond in English."
        )

        let instructions = PersonalitySystemInstructionBuilder.build(from: briefWithoutGuardrails)

        XCTAssertFalse(instructions.contains("Guardrails:"))
    }

    func testOutputIsNonEmptyAndSinglePlainString() {
        let instructions = PersonalitySystemInstructionBuilder.build()

        XCTAssertFalse(instructions.isEmpty)
    }
}
