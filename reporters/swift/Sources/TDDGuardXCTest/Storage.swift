import Foundation

// MARK: - Storage Protocol

/// Storage abstraction for saving test results
public protocol Storage {
    func saveTest(_ content: String) async throws
}

// MARK: - File Storage Implementation

/// File-based storage that writes to .claude/tdd-guard/data/test.json
public class FileStorage: Storage {
    private let testPath: URL

    /// Initialize file storage with optional project root
    /// - Parameter projectRoot: Absolute path to project root. If nil, uses CLAUDE_PROJECT_DIR env var or current directory
    public init(projectRoot: String? = nil) {
        // Determine project root (parameter > env var > current directory)
        let root = projectRoot
            ?? ProcessInfo.processInfo.environment["CLAUDE_PROJECT_DIR"]
            ?? FileManager.default.currentDirectoryPath

        // Create .claude/tdd-guard/data/ directory
        let dataDir = URL(fileURLWithPath: root)
            .appendingPathComponent(".claude")
            .appendingPathComponent("tdd-guard")
            .appendingPathComponent("data")

        // Ensure directory exists
        try? FileManager.default.createDirectory(
            at: dataDir,
            withIntermediateDirectories: true,
            attributes: nil
        )

        self.testPath = dataDir.appendingPathComponent("test.json")
    }

    /// Save test results to test.json file
    /// - Parameter content: JSON string containing test results
    public func saveTest(_ content: String) async throws {
        try content.write(to: testPath, atomically: true, encoding: .utf8)
    }
}

// MARK: - Memory Storage (for testing)

/// In-memory storage for unit testing
public class MemoryStorage: Storage {
    private var testData: String?

    public init() {}

    public func saveTest(_ content: String) async throws {
        self.testData = content
    }

    /// Retrieve saved test data (for testing)
    public func getTest() -> String? {
        return testData
    }

    /// Clear saved data (for testing)
    public func clear() {
        testData = nil
    }
}
