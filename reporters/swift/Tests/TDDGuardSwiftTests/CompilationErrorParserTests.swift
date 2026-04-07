import XCTest
@testable import TDDGuardSwift

final class CompilationErrorParserTests: XCTestCase {
    func testSwiftCompilerErrorWithLocation() {
        let parser = CompilationErrorParser()
        parser.process(line: "/path/Sources/Calculator.swift:3:8: error: no such module 'NonExistentModule'")

        XCTAssertEqual(parser.errors.count, 1)
        XCTAssertEqual(parser.errors[0].message, "no such module 'NonExistentModule'")
        XCTAssertEqual(parser.errors[0].stack, "/path/Sources/Calculator.swift:3:8")
    }

    func testGeneralBuildError() {
        let parser = CompilationErrorParser()
        parser.process(line: "error: fatalError")

        XCTAssertEqual(parser.errors.count, 1)
        XCTAssertEqual(parser.errors[0].message, "fatalError")
        XCTAssertNil(parser.errors[0].stack)
    }

    func testProducesSyntheticCompilationModule() {
        let parser = CompilationErrorParser()
        parser.process(line: "/path/file.swift:1:1: error: something went wrong")

        let results = parser.results
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results[0].moduleId, "compilation")
        XCTAssertEqual(results[0].name, "build")
        XCTAssertEqual(results[0].state, "failed")
    }

    func testEmptyResultsWhenNoErrors() {
        let parser = CompilationErrorParser()
        parser.process(line: "Test Suite 'All tests' started")

        XCTAssertTrue(parser.results.isEmpty)
    }

    func testSkipsBuildFailedMarker() {
        let parser = CompilationErrorParser()
        parser.process(line: "** BUILD FAILED **")

        XCTAssertTrue(parser.errors.isEmpty)
    }

    func testStripsANSICodesBeforeParsing() {
        let parser = CompilationErrorParser()
        parser.process(line: "\u{1B}[1m/path/file.swift:1:1:\u{1B}[0m error: bad code")

        XCTAssertEqual(parser.errors.count, 1)
        XCTAssertTrue(parser.errors[0].message.contains("bad code"))
    }
}
