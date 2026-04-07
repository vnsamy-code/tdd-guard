// MARK: - Intermediate types produced by parsers

struct ParsedError {
    let message: String
    let stack: String?
    let expected: String?
    let actual: String?
}

struct ParsedTest {
    let moduleId: String
    let name: String
    let state: String
    let errors: [ParsedError]
}

// MARK: - Output types written to test.json

struct TDDGuardOutput: Encodable {
    let testModules: [TestModule]
    let reason: String
}

struct TestModule: Encodable {
    let moduleId: String
    let tests: [TestResult]
}

struct TestResult: Encodable {
    let name: String
    let fullName: String
    let state: String
    let errors: [TestError]
}

struct TestError: Encodable {
    let message: String
    let stack: String?
    let expected: String?
    let actual: String?

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(stack, forKey: .stack)
        try container.encodeIfPresent(expected, forKey: .expected)
        try container.encodeIfPresent(actual, forKey: .actual)
    }

    private enum CodingKeys: String, CodingKey {
        case message, stack, expected, actual
    }
}

// MARK: - Transformer

enum Transformer {
    static func transform(_ tests: [ParsedTest]) -> TDDGuardOutput {
        var moduleMap: [String: [ParsedTest]] = [:]
        for test in tests {
            moduleMap[test.moduleId, default: []].append(test)
        }

        let reason = tests.contains { $0.state == "failed" } ? "failed" : "passed"

        let modules = moduleMap.map { moduleId, parsedTests in
            TestModule(
                moduleId: moduleId,
                tests: parsedTests.map { t in
                    TestResult(
                        name: t.name,
                        fullName: "\(t.moduleId)/\(t.name)",
                        state: t.state,
                        errors: t.errors.map { e in
                            TestError(
                                message: e.message,
                                stack: e.stack,
                                expected: e.expected,
                                actual: e.actual
                            )
                        }
                    )
                }
            )
        }

        return TDDGuardOutput(testModules: modules, reason: reason)
    }
}
