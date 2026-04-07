import XCTest
@testable import TDDGuardSwift

final class XCTestParserTests: XCTestCase {
    func testPassingTest() {
        let parser = XCTestParser()
        feedLines(parser, xcTestOutput(state: "passed"))

        XCTAssertEqual(parser.results.count, 1)
        let result = parser.results[0]
        XCTAssertEqual(result.moduleId, "CalculatorTests")
        XCTAssertEqual(result.name, "testShouldAddNumbersCorrectly")
        XCTAssertEqual(result.state, "passed")
        XCTAssertTrue(result.errors.isEmpty)
    }

    func testFailingTestWithAssertError() {
        let parser = XCTestParser()
        feedLines(parser, xcTestOutput(state: "failed", includeError: true))

        XCTAssertEqual(parser.results.count, 1)
        let result = parser.results[0]
        XCTAssertEqual(result.state, "failed")
        XCTAssertEqual(result.errors.count, 1)
        XCTAssertTrue(result.errors[0].message.contains("XCTAssertEqual failed"))
    }

    func testExtractsExpectedAndActualFromAssertEqual() {
        let parser = XCTestParser()
        feedLines(parser, xcTestOutput(state: "failed", includeError: true))

        let error = parser.results[0].errors[0]
        XCTAssertEqual(error.actual, "5")
        XCTAssertEqual(error.expected, "6")
    }

    func testModuleQualifiedClassName() {
        let parser = XCTestParser()
        // SPM produces ModuleName.ClassName format
        parser.process(line: "Test Case '-[CalculatorTests.CalculatorTests testShouldAddNumbersCorrectly]' started.")
        parser.process(line: "Test Case '-[CalculatorTests.CalculatorTests testShouldAddNumbersCorrectly]' passed (0.001 seconds).")

        XCTAssertEqual(parser.results.count, 1)
        XCTAssertEqual(parser.results[0].moduleId, "CalculatorTests")
    }

    func testIgnoresUnrelatedLines() {
        let parser = XCTestParser()
        parser.process(line: "Test Suite 'All tests' started at 2026-04-05 10:00:00.000")
        parser.process(line: "Test Suite 'CalculatorTests' passed at 2026-04-05 10:00:00.002.")
        parser.process(line: "Executed 1 test, with 0 failures (0 unexpected) in 0.001 (0.002) seconds")

        XCTAssertTrue(parser.results.isEmpty)
    }
}

// MARK: - Helpers

private func feedLines(_ parser: XCTestParser, _ lines: [String]) {
    lines.forEach { parser.process(line: $0) }
}

private func xcTestOutput(state: String, includeError: Bool = false) -> [String] {
    var lines = [
        "Test Case '-[CalculatorTests testShouldAddNumbersCorrectly]' started.",
    ]
    if includeError {
        lines.append("/path/Tests/CalculatorTests.swift:12: error: -[CalculatorTests testShouldAddNumbersCorrectly] : XCTAssertEqual failed: (\"5\") is not equal to (\"6\")")
    }
    lines.append("Test Case '-[CalculatorTests testShouldAddNumbersCorrectly]' \(state) (0.001 seconds).")
    return lines
}
