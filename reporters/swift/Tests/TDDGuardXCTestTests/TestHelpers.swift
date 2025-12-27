import XCTest
@testable import TDDGuardXCTest

// MARK: - Test Data Factories

enum TestDataFactory {
    /// Create a sample test result
    static func createTestResult(
        moduleId: String = "SampleTests",
        testName: String = "testExample",
        state: Test.TestState = .passed,
        errors: [TestError]? = nil
    ) -> TestResult {
        let test = Test(
            name: testName,
            fullName: "\(moduleId).\(testName)",
            state: state,
            errors: errors
        )
        let module = TestModule(moduleId: moduleId, tests: [test])
        return TestResult(
            testModules: [module],
            unhandledErrors: nil,
            reason: state == .failed ? .failed : .passed
        )
    }

    /// Create a test error
    static func createTestError(
        message: String = "Test failed",
        stack: String? = "/path/to/test.swift:42"
    ) -> TestError {
        return TestError(message: message, stack: stack)
    }
}

// MARK: - Assertion Helpers

extension XCTestCase {
    /// Parse saved test data from storage and verify structure
    func parseAndVerifyTestResult(_ json: String) throws -> TestResult {
        let decoder = JSONDecoder()
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try decoder.decode(TestResult.self, from: data)
    }
}
