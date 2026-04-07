import Foundation

class SwiftTestingParser {
    private struct PendingTest {
        let moduleId: String
        let name: String
        var errors: [ParsedError] = []
    }

    private var pending: [String: PendingTest] = [:]
    private(set) var results: [ParsedTest] = []

    // MARK: - Decodable event shapes

    private struct Event: Decodable {
        let kind: String
        let payload: Payload
    }

    private struct Payload: Decodable {
        let id: String?
        let testCaseID: String?
        let result: String?
        let issue: Issue?
    }

    private struct Issue: Decodable {
        let description: String
        let sourceLocation: SourceLocation?
    }

    private struct SourceLocation: Decodable {
        let fileID: String
        let line: Int
    }

    private let decoder = JSONDecoder()

    func process(line: String) {
        guard let data = line.data(using: .utf8),
              let event = try? decoder.decode(Event.self, from: data)
        else { return }

        switch event.kind {
        case "testCaseStarted":
            guard let id = event.payload.id,
                  let (moduleId, name) = parseID(id)
            else { return }
            pending[id] = PendingTest(moduleId: moduleId, name: name)

        case "issueRecorded":
            guard let testCaseID = event.payload.testCaseID,
                  let issue = event.payload.issue
            else { return }
            let stack: String? = issue.sourceLocation.map { "\($0.fileID):\($0.line)" }
            let error = ParsedError(
                message: issue.description,
                stack: stack,
                expected: nil,
                actual: nil
            )
            pending[testCaseID]?.errors.append(error)

        case "testCaseEnded":
            guard let id = event.payload.id,
                  let result = event.payload.result,
                  let test = pending.removeValue(forKey: id)
            else { return }
            let state = result == "passed" ? "passed" : "failed"
            results.append(ParsedTest(
                moduleId: test.moduleId,
                name: test.name,
                state: state,
                errors: test.errors
            ))

        default:
            break
        }
    }

    // Parses "Module.ClassName/testMethod()" → ("ClassName", "testMethod")
    private func parseID(_ id: String) -> (moduleId: String, name: String)? {
        guard let slashIndex = id.firstIndex(of: "/") else { return nil }
        let typePart = String(id[id.startIndex..<slashIndex])
        let methodPart = String(id[id.index(after: slashIndex)...])

        let className = typePart.split(separator: ".").last.map(String.init) ?? typePart
        let methodName: String
        if let parenIndex = methodPart.firstIndex(of: "(") {
            methodName = String(methodPart[methodPart.startIndex..<parenIndex])
        } else {
            methodName = methodPart
        }

        return (moduleId: className, name: methodName)
    }
}
