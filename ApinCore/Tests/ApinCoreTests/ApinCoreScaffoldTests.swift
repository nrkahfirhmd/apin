// ApinCoreScaffoldTests.swift
// ApinCoreTests
//
// Placeholder test target scaffold so `ApinCoreTests` exists and builds before T2/
// T4/T5/T6 add real unit tests alongside their logic. Replace/extend per task, do
// not accumulate unrelated tests here.

import XCTest
@testable import ApinCore

final class ApinCoreScaffoldTests: XCTestCase {
    func testPackageResolves() throws {
        // Confirms the ApinCoreTests target links against ApinCore. Real coverage
        // arrives with T2 (capability gate), T4 (session wrapper), T5 (personality
        // builder), and T6 (journal repository).
        XCTAssertTrue(true)
    }
}
