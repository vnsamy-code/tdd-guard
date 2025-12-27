import XCTest
import Foundation

// MARK: - TDD Guard Observer

/// XCTest observer that captures test results and saves them for TDD Guard validation
public class TDDGuardObserver: NSObject, XCTestObservation {
    private let storage: Storage
    private var modules: [String: TestModuleBuilder] = [:]
    private var unhandledErrors: [UnhandledError] = []

    /// Initialize observer with optional project root and storage
    /// - Parameters:
    ///   - projectRoot: Absolute path to project root (defaults to current directory)
    ///   - storage: Custom storage implementation (defaults to FileStorage)
    public init(projectRoot: String? = nil, storage: Storage? = nil) {
        self.storage = storage ?? FileStorage(projectRoot: projectRoot)
        super.init()
    }

    // MARK: - XCTestObservation Protocol

    public func testBundleWillStart(_ testBundle: Bundle) {
        // Clear state at start of test run
        modules.removeAll()
        unhandledErrors.removeAll()
    }

    public func testCaseWillStart(_ testCase: XCTestCase) {
        // Extract module ID from test class name
        let moduleId = String(describing: type(of: testCase))

        // Create module builder if it doesn't exist
        if modules[moduleId] == nil {
            modules[moduleId] = TestModuleBuilder(moduleId: moduleId)
        }
    }

    public func testCase(
        _ testCase: XCTestCase,
        didFailWithDescription description: String,
        inFile filePath: String?,
        atLine lineNumber: Int
    ) {
        let moduleId = String(describing: type(of: testCase))

        // Format stack trace
        let stack = filePath.map { "\($0):\(lineNumber)" }

        // Create error
        let error = TestError(message: description, stack: stack)

        // Add error to test
        modules[moduleId]?.addError(for: testCase.name, error: error)
    }

    public func testCaseDidFinish(_ testCase: XCTestCase) {
        let moduleId = String(describing: type(of: testCase))

        // Determine test state from test run
        let state: Test.TestState
        if let testRun = testCase.testRun {
            if testRun.hasSucceeded {
                state = .passed
            } else if testRun.skipCount > 0 {
                state = .skipped
            } else {
                state = .failed
            }
        } else {
            state = .failed
        }

        // Extract test name (remove leading "-[ClassName " and trailing "]")
        let testName = cleanTestName(testCase.name)

        // Build full name
        let fullName = "\(moduleId).\(testName)"

        // Add test to module
        modules[moduleId]?.addTest(
            name: testName,
            fullName: fullName,
            state: state
        )
    }

    public func testBundleDidFinish(_ testBundle: Bundle) {
        // Save results synchronously to ensure completion before process exits
        let semaphore = DispatchSemaphore(value: 0)
        Task {
            await saveResults()
            semaphore.signal()
        }
        semaphore.wait()
    }

    // MARK: - Private Helpers

    private func cleanTestName(_ name: String) -> String {
        // XCTest names come as "-[ClassName testMethodName]"
        // Extract just "testMethodName"
        let pattern = #"-\[.+ (.+)\]"#
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: name, range: NSRange(name.startIndex..., in: name)),
           let range = Range(match.range(at: 1), in: name) {
            return String(name[range])
        }
        return name
    }

    private func saveResults() async {
        // Build test modules
        let testModules = modules.values.map { $0.build() }

        // Determine overall reason
        let reason: TestResult.TestRunReason
        let hasFailures = testModules.contains { module in
            module.tests.contains { $0.state == .failed }
        }
        reason = hasFailures ? .failed : .passed

        // Build final result
        let result = TestResult(
            testModules: testModules,
            unhandledErrors: unhandledErrors.isEmpty ? nil : unhandledErrors,
            reason: reason
        )

        // Encode to JSON with pretty printing
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let jsonData = try encoder.encode(result)

            if let jsonString = String(data: jsonData, encoding: .utf8) {
                try await storage.saveTest(jsonString)
            }
        } catch {
            // Silently fail - tests should not be interrupted by reporter errors
        }
    }
}

// MARK: - Test Module Builder

/// Accumulates tests for a single module
private class TestModuleBuilder {
    let moduleId: String
    private var tests: [String: TestBuilder] = [:]

    init(moduleId: String) {
        self.moduleId = moduleId
    }

    func addTest(name: String, fullName: String, state: Test.TestState) {
        if tests[name] == nil {
            tests[name] = TestBuilder(name: name, fullName: fullName)
        }
        tests[name]?.state = state
    }

    func addError(for testName: String, error: TestError) {
        if tests[testName] == nil {
            tests[testName] = TestBuilder(
                name: testName,
                fullName: "\(moduleId).\(testName)"
            )
        }
        tests[testName]?.addError(error)
    }

    func build() -> TestModule {
        TestModule(
            moduleId: moduleId,
            tests: tests.values.map { $0.build() }
        )
    }
}

// MARK: - Test Builder

/// Builds individual test with errors
private class TestBuilder {
    let name: String
    let fullName: String
    var state: Test.TestState = .passed
    var errors: [TestError] = []

    init(name: String, fullName: String) {
        self.name = name
        self.fullName = fullName
    }

    func addError(_ error: TestError) {
        errors.append(error)
        state = .failed
    }

    func build() -> Test {
        Test(
            name: name,
            fullName: fullName,
            state: state,
            errors: errors.isEmpty ? nil : errors
        )
    }
}
