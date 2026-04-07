import Foundation

class XCTestParser {
    private struct PendingTest {
        let moduleId: String
        let name: String
        var errors: [ParsedError] = []
    }

    private var pending: [String: PendingTest] = [:]
    private(set) var results: [ParsedTest] = []

    // Legacy format (Xcode ≤15, swift test):
    // Test Case '-[CalculatorTests.CalculatorTests testMethod]' started.
    private let startedPattern = try! NSRegularExpression(
        pattern: #"Test Case '-\[(?:\w+\.)?(\w+) (\w+)\]' started\."#
    )
    // Test Case '-[CalculatorTests.CalculatorTests testMethod]' passed/failed (0.001 seconds).
    private let endedPattern = try! NSRegularExpression(
        pattern: #"Test Case '-\[(?:\w+\.)?(\w+) (\w+)\]' (passed|failed) \([\d.]+ seconds\)\."#
    )
    // /path/file.swift:12: error: -[Class method] : message
    private let errorLinePattern = try! NSRegularExpression(
        pattern: #"^(?:error: )?(.+\.swift:\d+): error: -\[(?:\w+\.)?(\w+) (\w+)\] : (.+)$"#
    )
    // XCTAssertEqual failed: ("actual") is not equal to ("expected")
    private let assertEqualPattern = try! NSRegularExpression(
        pattern: #"XCTAssertEqual failed: \("(.+?)"\) is not equal to \("(.+?)"\)"#
    )

    // Xcode 16+ format (dot-notation, lowercase 'case'):
    // Test case 'ToDoAppTests.testMethod()' passed on 'Device' (0.001 seconds)
    // Test case 'ToDoAppTests.testMethod()' failed on 'Device' (0.001 seconds)
    private let modernCompletionPattern = try! NSRegularExpression(
        pattern: #"Test case '(?:\w+\.)?(\w+)\.(\w+)\(\)' (passed|failed) on '.+?' \([\d.]+ seconds\)"#
    )
    // /path/file.swift:14: error: testMethod(): XCTAssertEqual failed …
    private let modernErrorPattern = try! NSRegularExpression(
        pattern: #"^(?:error: )?(.+\.swift:\d+): error: (\w+)\(\): (.+)$"#
    )

    func process(line: String) {
        let range = NSRange(line.startIndex..., in: line)

        // --- Legacy format ---
        if let match = startedPattern.firstMatch(in: line, range: range) {
            let className = group(match, at: 1, in: line)
            let methodName = group(match, at: 2, in: line)
            pending[key(className, methodName)] = PendingTest(moduleId: className, name: methodName)
            return
        }

        if let match = endedPattern.firstMatch(in: line, range: range) {
            let className = group(match, at: 1, in: line)
            let methodName = group(match, at: 2, in: line)
            let state = group(match, at: 3, in: line)
            if let test = pending.removeValue(forKey: key(className, methodName)) {
                results.append(ParsedTest(
                    moduleId: test.moduleId,
                    name: test.name,
                    state: state,
                    errors: test.errors
                ))
            }
            return
        }

        if let match = errorLinePattern.firstMatch(in: line, range: range) {
            let stack = group(match, at: 1, in: line)
            let className = group(match, at: 2, in: line)
            let methodName = group(match, at: 3, in: line)
            let message = group(match, at: 4, in: line)
            let (expected, actual) = extractAssertEqual(from: message)
            let error = ParsedError(message: message, stack: stack, expected: expected, actual: actual)
            pending[key(className, methodName)]?.errors.append(error)
            return
        }

        // --- Xcode 16+ format ---
        if let match = modernCompletionPattern.firstMatch(in: line, range: range) {
            let className = group(match, at: 1, in: line)
            let methodName = group(match, at: 2, in: line)
            let state = group(match, at: 3, in: line)
            let k = key(className, methodName)
            let errors = pending.removeValue(forKey: k)?.errors ?? []
            results.append(ParsedTest(
                moduleId: className,
                name: methodName,
                state: state,
                errors: errors
            ))
            return
        }

        if let match = modernErrorPattern.firstMatch(in: line, range: range) {
            let stack = group(match, at: 1, in: line)
            let methodName = group(match, at: 2, in: line)
            let message = group(match, at: 3, in: line)
            let (expected, actual) = extractAssertEqual(from: message)
            let error = ParsedError(message: message, stack: stack, expected: expected, actual: actual)
            // Buffer against the method name; we don't know the class yet
            for k in pending.keys where k.hasSuffix("/\(methodName)") {
                pending[k]?.errors.append(error)
                return
            }
            // If no pending entry exists yet, create a placeholder
            pending["unknown/\(methodName)"] = PendingTest(moduleId: "unknown", name: methodName)
            pending["unknown/\(methodName)"]?.errors.append(error)
        }
    }

    private func extractAssertEqual(from message: String) -> (expected: String?, actual: String?) {
        let range = NSRange(message.startIndex..., in: message)
        guard let m = assertEqualPattern.firstMatch(in: message, range: range) else {
            return (nil, nil)
        }
        return (group(m, at: 2, in: message), group(m, at: 1, in: message))
    }

    private func key(_ className: String, _ methodName: String) -> String {
        "\(className)/\(methodName)"
    }

    private func group(_ match: NSTextCheckingResult, at index: Int, in string: String) -> String {
        guard let range = Range(match.range(at: index), in: string) else { return "" }
        return String(string[range])
    }
}
