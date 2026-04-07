import XCTest
@testable import TDDGuardSwift

final class SwiftTestingParserTests: XCTestCase {
    func testPassingTest() {
        let parser = SwiftTestingParser()
        feedLines(parser, swiftTestingOutput(result: "passed"))

        XCTAssertEqual(parser.results.count, 1)
        let result = parser.results[0]
        XCTAssertEqual(result.moduleId, "CalculatorTests")
        XCTAssertEqual(result.name, "testShouldAddNumbersCorrectly")
        XCTAssertEqual(result.state, "passed")
        XCTAssertTrue(result.errors.isEmpty)
    }

    func testFailingTestWithIssue() {
        let parser = SwiftTestingParser()
        feedLines(parser, swiftTestingOutput(result: "failed", includeIssue: true))

        XCTAssertEqual(parser.results.count, 1)
        let result = parser.results[0]
        XCTAssertEqual(result.state, "failed")
        XCTAssertEqual(result.errors.count, 1)
        XCTAssertTrue(result.errors[0].message.contains("#expect"))
    }

    func testIssueStackContainsFileAndLine() {
        let parser = SwiftTestingParser()
        feedLines(parser, swiftTestingOutput(result: "failed", includeIssue: true))

        let stack = parser.results[0].errors[0].stack
        XCTAssertNotNil(stack)
        XCTAssertTrue(stack!.contains(":"))
    }

    func testStripsParenthesesFromMethodName() {
        let parser = SwiftTestingParser()
        parser.process(line: makeEvent("testCaseStarted", id: "CalculatorTests.CalculatorTests/testShouldAddNumbersCorrectly()"))
        parser.process(line: makeEvent("testCaseEnded", id: "CalculatorTests.CalculatorTests/testShouldAddNumbersCorrectly()", result: "passed"))

        XCTAssertEqual(parser.results[0].name, "testShouldAddNumbersCorrectly")
    }

    func testIgnoresNonJSONLines() {
        let parser = SwiftTestingParser()
        parser.process(line: "Test Suite 'All tests' started at 2026-04-05")
        parser.process(line: "not json at all")

        XCTAssertTrue(parser.results.isEmpty)
    }
}

// MARK: - Helpers

private func feedLines(_ parser: SwiftTestingParser, _ lines: [String]) {
    lines.forEach { parser.process(line: $0) }
}

private func swiftTestingOutput(result: String, includeIssue: Bool = false) -> [String] {
    let id = "CalculatorTests.CalculatorTests/testShouldAddNumbersCorrectly()"
    var lines = [makeEvent("testCaseStarted", id: id)]
    if includeIssue {
        lines.append(makeIssueEvent(testCaseID: id))
    }
    lines.append(makeEvent("testCaseEnded", id: id, result: result))
    return lines
}

private func makeEvent(_ kind: String, id: String, result: String? = nil) -> String {
    var payload = #"{"id":"\#(id)""#
    if let result = result { payload += #","result":"\#(result)""# }
    payload += "}"
    return #"{"kind":"\#(kind)","payload":\#(payload)}"#
}

private func makeIssueEvent(testCaseID: String) -> String {
    // Use ##"..."## delimiter so the "#expect" content doesn't close the raw string
    ##"{"kind":"issueRecorded","payload":{"testCaseID":"\##(testCaseID)","issue":{"description":"#expect(calc.add(2,3) == 6) failed","sourceLocation":{"fileID":"CalculatorTests/CalculatorTests.swift","line":12}}}}"##
}
