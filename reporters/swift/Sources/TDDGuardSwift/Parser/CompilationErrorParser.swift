import Foundation

class CompilationErrorParser {
    private(set) var errors: [ParsedError] = []

    private let swiftErrorPattern = try! NSRegularExpression(
        pattern: #"^(.+\.swift:\d+:\d+): error: (.+)$"#
    )
    private let generalErrorPattern = try! NSRegularExpression(
        pattern: #"^error: (.+)$"#
    )
    private let ansiPattern = try! NSRegularExpression(
        pattern: "\u{1B}\\[[0-9;]*m"
    )

    private let skipPrefixes = ["CompileSwift", "=== BUILD", "** BUILD FAILED **"]

    func process(line: String) {
        let clean = stripANSI(line)
        let trimmed = clean.trimmingCharacters(in: .whitespaces)

        guard !trimmed.isEmpty else { return }
        guard !skipPrefixes.contains(where: { trimmed.hasPrefix($0) }) else { return }
        guard !trimmed.hasPrefix("note:") else { return }

        let range = NSRange(clean.startIndex..., in: clean)

        if let match = swiftErrorPattern.firstMatch(in: clean, range: range) {
            let stack = group(match, at: 1, in: clean)
            let message = group(match, at: 2, in: clean)
            errors.append(ParsedError(message: message, stack: stack, expected: nil, actual: nil))
            return
        }

        if let match = generalErrorPattern.firstMatch(in: clean, range: range) {
            let message = group(match, at: 1, in: clean)
            errors.append(ParsedError(message: message, stack: nil, expected: nil, actual: nil))
        }
    }

    var results: [ParsedTest] {
        guard !errors.isEmpty else { return [] }
        return [ParsedTest(moduleId: "compilation", name: "build", state: "failed", errors: errors)]
    }

    private func stripANSI(_ string: String) -> String {
        let range = NSRange(string.startIndex..., in: string)
        return ansiPattern.stringByReplacingMatches(in: string, range: range, withTemplate: "")
    }

    private func group(_ match: NSTextCheckingResult, at index: Int, in string: String) -> String {
        guard let range = Range(match.range(at: index), in: string) else { return "" }
        return String(string[range])
    }
}
