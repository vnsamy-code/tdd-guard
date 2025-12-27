import Foundation

// MARK: - Test Result Models

/// Complete test run output matching TDD Guard's JSON schema
public struct TestResult: Codable {
    public let testModules: [TestModule]
    public let unhandledErrors: [UnhandledError]?
    public let reason: TestRunReason?

    public init(
        testModules: [TestModule],
        unhandledErrors: [UnhandledError]? = nil,
        reason: TestRunReason? = nil
    ) {
        self.testModules = testModules
        self.unhandledErrors = unhandledErrors
        self.reason = reason
    }

    public enum TestRunReason: String, Codable {
        case passed
        case failed
        case interrupted
    }
}

/// Test module (test file/class grouping)
public struct TestModule: Codable {
    public let moduleId: String
    public let tests: [Test]

    public init(moduleId: String, tests: [Test]) {
        self.moduleId = moduleId
        self.tests = tests
    }
}

/// Individual test case
public struct Test: Codable {
    public let name: String
    public let fullName: String
    public let state: TestState
    public let errors: [TestError]?

    public init(
        name: String,
        fullName: String,
        state: TestState,
        errors: [TestError]? = nil
    ) {
        self.name = name
        self.fullName = fullName
        self.state = state
        self.errors = errors
    }

    public enum TestState: String, Codable {
        case passed
        case failed
        case skipped
    }
}

/// Error details for failed tests
public struct TestError: Codable {
    public let message: String
    public let stack: String?

    public init(message: String, stack: String? = nil) {
        self.message = message
        self.stack = stack
    }
}

/// Unhandled errors at test run level (import failures, etc.)
public struct UnhandledError: Codable {
    public let name: String
    public let message: String
    public let stack: String?

    public init(name: String, message: String, stack: String? = nil) {
        self.name = name
        self.message = message
        self.stack = stack
    }
}
